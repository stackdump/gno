package markdown

import (
	"bytes"
	"strings"

	"github.com/yuin/goldmark"
	"github.com/yuin/goldmark/ast"
	"github.com/yuin/goldmark/parser"
	"github.com/yuin/goldmark/renderer"
	"github.com/yuin/goldmark/text"
	"github.com/yuin/goldmark/util"
)

var (
	KindPflowBlock = ast.NewNodeKind("PflowBlock")

	webHost = &WebHost{
		Base: "https://cdn.jsdelivr.net/gh/pflow-xyz/pflow-app@",
		Tag:  "0.2.1",
		Path: "/static/",
	}
)

// pflowBlock represents a custom block for pflow.
type pflowBlock struct {
	ast.BaseBlock
	JSONContent string
}

// Kind implements Node.Kind.
func (b *pflowBlock) Kind() ast.NodeKind {
	return KindPflowBlock
}

// Dump is used for debugging.
func (b *pflowBlock) Dump(source []byte, level int) {
	m := map[string]string{
		"JSONContent": b.JSONContent,
	}
	ast.DumpHelper(b, source, level, m, nil)
}

type pflowParser struct{}

func (p *pflowParser) Open(parent ast.Node, reader text.Reader, pc parser.Context) (ast.Node, parser.State) {
	line, _ := reader.PeekLine()
	if !bytes.HasPrefix(line, []byte("```pflow")) {
		return nil, parser.NoChildren
	}
	reader.AdvanceLine()
	return &pflowBlock{}, parser.NoChildren
}

func (p *pflowParser) Continue(node ast.Node, reader text.Reader, pc parser.Context) parser.State {
	line, _ := reader.PeekLine()
	if line == nil || bytes.HasPrefix(line, []byte("```")) {
		return parser.Close
	}
	block := node.(*pflowBlock)
	block.JSONContent += string(line)
	return parser.Continue
}

func (p *pflowParser) Close(node ast.Node, reader text.Reader, pc parser.Context) {
	for {
		line, segment := reader.PeekLine()
		_ = segment
		if line == nil || bytes.HasPrefix(line, []byte("```")) {
			reader.AdvanceLine()
			break
		}
		reader.AdvanceLine()
	}
}

func (p *pflowParser) CanInterruptParagraph() bool {
	return true
}

func (p *pflowParser) CanAcceptIndentedLine() bool {
	return false
}

func (p *pflowParser) Trigger() []byte {
	return []byte{'`'}
}

// pflowRenderer renders the pflow block as HTML.
type pflowRenderer struct{}

func (r *pflowRenderer) RegisterFuncs(reg renderer.NodeRendererFuncRegisterer) {
	reg.Register(KindPflowBlock, r.renderPflowBlock)
}

func (r *pflowRenderer) renderPflowBlock(w util.BufWriter, source []byte, node ast.Node, entering bool) (ast.WalkStatus, error) {
	if !entering {
		return ast.WalkContinue, nil
	}

	b, ok := node.(*pflowBlock)
	if !ok {
		return ast.WalkContinue, nil
	}
	b.JSONContent = strings.TrimSuffix(b.JSONContent, "```")

	// REVIEW: somehow we do not replace the existing behavior with ``` source blocks
	// FIXME get rid of extra gray div
	w.WriteString(Render(b.JSONContent))

	return ast.WalkContinue, nil
}

// pflowExtension is the Goldmark extension for pflow.
type pflowExtension struct{}

func (e *pflowExtension) Extend(m goldmark.Markdown) {
	m.Parser().AddOptions(parser.WithBlockParsers(
		util.Prioritized(&pflowParser{}, 500),
	))
	m.Renderer().AddOptions(renderer.WithNodeRenderers(
		util.Prioritized(&pflowRenderer{}, 500),
	))
}

type WebHost struct {
	Base string
	Tag  string
	Path string
}

func (h *WebHost) Cdn() string {
	return h.Base + h.Tag + h.Path
}

func templateHtml(key, value string, s string) (out string) {
	out = strings.ReplaceAll(htmlContent, key, value)
	return strings.ReplaceAll(out, "{SOURCE}", s)
}

func Render(source string) string {
	return templateHtml("{CDN}", webHost.Cdn(), source)
}

var htmlContent = `
    <style type="text/css">
        @import url("{CDN}pflow.css");
    </style>
    <svg id="svgCanvas" width="100%" height="100%"  xmlns="http://www.w3.org/2000/svg">
        <foreignObject height="100%" width="100%" x="0" y="0">
            <object id="svgObject" type="image/svg+xml" data="{CDN}model.svg"></object>
        </foreignObject>
        <g id="toolbar">
            <g id="status" transform="translate(5, 607)" >
                <rect x="0" y="0" width="140" height="20" fill="#fff" rx="5" ry="5"/>
                <text x="10" y="15">Status: Ready</text>
            </g>
            <g id="playBtn" transform="translate(148, 604)" >
                <circle cx="12" cy="11" r="20" fill="transparent" stroke="transparent" stroke-width="2" />
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2m0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8m-2.5-3.5 7-4.5-7-4.5z"></path>
            </g>
        </g>
        <g id="history" transform="translate(5, 605)" ></g>
        <foreignObject height="50%" width="98%" x="0" y="635">
            <textarea id="source">{SOURCE}</textarea>
        </foreignObject>
    </svg>
    <script src="{CDN}pflow.js"></script>
`
