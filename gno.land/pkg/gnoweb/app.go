package gnoweb

import (
	"fmt"
	"log/slog"
	"net/http"
	"path"
	"strings"

	"github.com/gnolang/gno/gno.land/pkg/gnoweb/components"
	"github.com/gnolang/gno/tm2/pkg/bft/rpc/client"
	"github.com/yuin/goldmark"
	mdhtml "github.com/yuin/goldmark/renderer/html"
)

// AppConfig contains configuration for the gnoweb.
type AppConfig struct {
	// UnsafeHTML, if enabled, allows to use HTML in the markdown.
	UnsafeHTML bool
	// Analytics enables SimpleAnalytics.
	Analytics bool
	// NodeRemote is the remote address of the gno.land node.
	NodeRemote string
	// RemoteHelp is the remote of the gno.land node, as used in the help page.
	RemoteHelp string
	// ChainID is the chain id, used for constructing the help page.
	ChainID string
	// AssetsPath is the base path to the gnoweb assets.
	AssetsPath string
	// AssetDir, if set, will be used for assets instead of the embedded public directory.
	AssetsDir string
	// FaucetURL, if specified, will be the URL to which `/faucet` redirects.
	FaucetURL string
	// Domain is the domain used by the node.
	Domain string
}

// NewDefaultAppConfig returns a new default [AppConfig]. The default sets
// 127.0.0.1:26657 as the remote node, "dev" as the chain ID and sets up Assets
// to be served on /public/.
func NewDefaultAppConfig() *AppConfig {
	const defaultRemote = "127.0.0.1:26657"
	return &AppConfig{
		NodeRemote: defaultRemote,
		RemoteHelp: defaultRemote,
		ChainID:    "dev",
		AssetsPath: "/public/",
		Domain:     "gno.land",
	}
}

// NewRouter initializes the gnoweb router with the specified logger and configuration.
func NewRouter(logger *slog.Logger, cfg *AppConfig) (http.Handler, error) {
	// Initialize RPC Client
	client, err := client.NewHTTPClient(cfg.NodeRemote)
	if err != nil {
		return nil, fmt.Errorf("unable to create HTTP client: %w", err)
	}

	// Setup web client HTML
	webcfg := NewDefaultHTMLWebClientConfig(client)
	webcfg.Domain = cfg.Domain
	if cfg.UnsafeHTML {
		webcfg.GoldmarkOptions = append(webcfg.GoldmarkOptions, goldmark.WithRendererOptions(
			mdhtml.WithXHTML(), mdhtml.WithUnsafe(),
		))
	}
	webcli := NewHTMLClient(logger, webcfg)

	// Setup StaticMetadata
	chromaStylePath := path.Join(cfg.AssetsPath, "_chroma", "style.css")
	staticMeta := StaticMetadata{
		Domain:     cfg.Domain,
		AssetsPath: cfg.AssetsPath,
		ChromaPath: chromaStylePath,
		RemoteHelp: cfg.RemoteHelp,
		ChainId:    cfg.ChainID,
		Analytics:  cfg.Analytics,
	}

	// Configure WebHandler
	webConfig := WebHandlerConfig{WebClient: webcli, Meta: staticMeta}
	webhandler, err := NewWebHandler(logger, webConfig)
	if err != nil {
		return nil, fmt.Errorf("unable to create web handler: %w", err)
	}

	// Setup HTTP muxer
	mux := http.NewServeMux()

	// Handle web handler with alias middleware
	mux.Handle("/", AliasAndRedirectMiddleware(webhandler, cfg.Analytics))

	// Register faucet URL to `/faucet` if specified
	if cfg.FaucetURL != "" {
		mux.Handle("/faucet", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			http.Redirect(w, r, cfg.FaucetURL, http.StatusFound)
			components.RedirectView(components.RedirectData{
				To:            cfg.FaucetURL,
				WithAnalytics: cfg.Analytics,
			}).Render(w)
		}))
	}

	// Handle Chroma CSS requests
	// XXX: probably move this elsewhere
	mux.Handle(chromaStylePath, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/css")
		if err := webcli.WriteFormatterCSS(w); err != nil {
			logger.Error("unable to write CSS", "err", err)
			http.NotFound(w, r)
		}
	}))

	// Handle assets path
	// XXX: add caching
	assetsBase := "/" + strings.Trim(cfg.AssetsPath, "/") + "/"
	if cfg.AssetsDir != "" {
		logger.Debug("using assets dir instead of embedded assets", "dir", cfg.AssetsDir)
		mux.Handle(assetsBase, DevAssetHandler(assetsBase, cfg.AssetsDir))
	} else {
		mux.Handle(assetsBase, AssetHandler())
	}

	// Handle status page
	mux.Handle("/status.json", handlerStatusJSON(logger, client))

	return mux, nil
}
