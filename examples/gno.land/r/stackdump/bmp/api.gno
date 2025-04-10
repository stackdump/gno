package bmp

import (
	"gno.land/p/demo/ufmt"
	"net/url"
	"std"
	"strings"
)

var (
	registry         = make(map[string]ImageApi) // TODO: use AVL Tree
	realmAllowPrefix = []string{}
)

func init() {
	allowPatchesFromSubRealms()
}

func allowPatchesFromSubRealms() {
	realmAllowPrefix = append(realmAllowPrefix, std.CurrentRealm().PkgPath()+"/") // must be in realm sub-path
}

func HasAllowedPrefix() bool {
	prevRealm := std.PreviousRealm()
	for _, callerPath := range realmAllowPrefix {
		if strings.HasPrefix(prevRealm.PkgPath(), callerPath) {
			return true
		}
	}
	return false
}

func AssertAccess() {
	if !HasAllowedPrefix() {
		panic("access denied: " + std.PreviousRealm().PkgPath() +
			" realm must match an allowed prefix:[" + strings.Join(realmAllowPrefix, ",") + "]")
	}
}

func AssertValidName(name string) {
	if !strings.HasSuffix(std.PreviousRealm().PkgPath(), name) {
		panic("invalid name: " + name + " must end with " + std.PreviousRealm().PkgPath())
	}
}

type PixelSetter = func(x, y, r, g, b int)

type ImageApi interface {
	Pixels(p PixelSetter)
	Bounds() Bounds
}

func Register(name string, handler ImageApi) {
	AssertAccess()
	AssertValidName(name)
	if _, exists := registry[name]; !exists {
		registry[name] = handler
	}
}

func Render(path string) (out string) {
	defer func() {
		if r := recover(); r != nil {
			out = ufmt.Sprint(r)
		}
	}()
	args := []string{}
	if path == "" {
		path = "profile"
	} else {
		args = strings.Split(path, ":")
		if len(args) > 1 {
			path = args[0]
		}
	}
	handler, ok := registry[path]
	if !ok {
		panic("path not registered: " + path)
	}
	img := NewPixelImage(50, handler.Bounds())
	handler.Pixels(img.SetPixel)
	if len(args) == 2 && args[1] == "source" {
		return "```\n" + img.Source(args[0]) + "```"
	}
	out = img.ToMarkdown()
	out += "[INSECURE: DAPP](data:text/html;utf8," + url.PathEscape(htmlContent) + ")"
	out += "\n\nCopy Link Address (Data Url) and paste in browser to build a new pixelfied image of your own.\n"

	return out
}
