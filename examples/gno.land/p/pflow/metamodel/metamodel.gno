package metamodel

import (
	"encoding/base64"
	"gno.land/p/demo/ufmt"
	"net/url"
	"strings"
)

// TokenType represents multiple token types as a slice of integers.
type TokenType []int64

// T creates a TokenType from a list of integers or strings.
func T(t ...interface{}) TokenType {
	ts := make(TokenType, len(t))
	for i, v := range t {
		switch v := v.(type) {
		case int:
			ts[i] = int64(v)
		case int64:
			ts[i] = v
		case string:
			ts[i] = 1
		default:
			ts[i] = -1
		}
	}

	return ts
}

// S creates a TokenType state vector from a list of TokenType.
func S(ts ...interface{}) []TokenType {
	state := make([]TokenType, len(ts))
	for i, v := range ts {
		state[i] = T(v)
	}
	return state
}

// Place represents a place in the Petri net.
type Place struct {
	Label    string    // Label of the place.
	Offset   int       // Offset of the place in the Petri net.
	Tokens   TokenType // Current number of tokens for each type.
	Initial  TokenType // Initial number of tokens for each type.
	Capacity TokenType // Maximum capacity for each token type (0 = unlimited).
	X        int       // X coordinate of the place.
	Y        int       // Y coordinate of the place.
}

// Arrow represents an arc in the Petri net.
type Arrow struct {
	Source  string    // Source place or transition.
	Target  string    // Target place or transition.
	Weight  TokenType // Weight for each token type.
	Inhibit bool      // Indicates if the arc inhibits the transition.
}

// Transition represents a transition in the Petri net.
type Transition struct {
	Label  string // Label of the transition.
	Offset int    // Offset of the transition in the Petri net.
	X      int    // X coordinate of the transition.
	Y      int    // Y coordinate of the transition.
}

// Pflow represents a Petri net model.
type Pflow struct {
	Places      map[string]Place      // Map of places.
	Transitions map[string]Transition // Map of transitions.
	Arrows      []Arrow               // List of arcs.
}

func (model *Pflow) State() []TokenType {
	state := make([]TokenType, len(model.Places))
	for _, place := range model.Places {
		state[place.Offset] = place.Tokens
	}
	return state
}

func Execute(state []TokenType, model *Pflow, action string) ([]TokenType, bool) {
	newState := make([]TokenType, len(state))
	copy(newState, state)

	for _, arc := range model.Arrows {
		if arc.Target == action {
			sourceTokens := model.Places[arc.Source].Tokens
			for i, weight := range arc.Weight {
				if sourceTokens[i] < weight {
					return state, false // Not enough tokens.
				}
				sourceTokens[i] -= weight
			}
		} else if arc.Source == action {
			targetTokens := model.Places[arc.Target].Tokens
			for i, weight := range arc.Weight {
				targetTokens[i] += weight
				if model.Places[arc.Target].Capacity[i] > 0 && targetTokens[i] > model.Places[arc.Target].Capacity[i] {
					return state, false // Exceeds capacity.
				}
			}
		}
	}

	return newState, true
}

// ToSvg renders the Petri net as an SVG.
func (model *Pflow) ToSvg(state []TokenType) string {
	svg := "<svg xmlns=\"http://www.w3.org/2000/svg\">"

	// Render places.
	for _, place := range model.Places {
		svg += ufmt.Sprintf("<circle cx=\"%d\" cy=\"%d\" r=\"16\" stroke=\"black\" fill=\"white\" />", place.X, place.Y)
		svg += ufmt.Sprintf("<text x=\"%d\" y=\"%d\" font-size=\"10\">%s</text>", place.X-20, place.Y-20, place.Label)

		// Render tokens.
		tokens := place.Tokens // FIXME
		for i, token := range tokens {
			if token > 0 {
				svg += ufmt.Sprintf("<text x=\"%d\" y=\"%d\" font-size=\"10\" fill=\"black\">%d</text>", place.X+10*i, place.Y+10, token)
			}
		}
	}

	// Render transitions.
	for _, transition := range model.Transitions {
		svg += ufmt.Sprintf("<rect x=\"%d\" y=\"%d\" width=\"30\" height=\"30\" fill=\"white\" stroke=\"black\" />", transition.X-15, transition.Y-15)
		svg += ufmt.Sprintf("<text x=\"%d\" y=\"%d\" font-size=\"10\">%s</text>", transition.X-20, transition.Y-20, transition.Label)
	}

	// Render arcs.
	for _, arc := range model.Arrows {
		source := model.Places[arc.Source]
		target := model.Transitions[arc.Target]
		svg += ufmt.Sprintf("<line x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\" stroke=\"black\" marker-end=\"url(#arrow)\" />", source.X, source.Y, target.X, target.Y)
	}

	svg += "</svg>"
	return svg
}

// ToBase64 encodes the SVG as a base64 string.
func (model *Pflow) ToBase64(state []TokenType) string {
	return base64.StdEncoding.EncodeToString([]byte(model.ToSvg(state)))
}

func (model *Pflow) ToDataUrl(state []TokenType) string {
	return "data:image/svg+xml;utf8," + url.PathEscape(model.ToSvg(state))
}

// ToLinkMarkdown generates a markdown link to the SVG image.
func (model *Pflow) ToLinkMarkdown(state []TokenType) string {
	return ufmt.Sprintf("![Petri-net](https://pflow.dev/img/b=%s)", model.ToBase64(state))
}

// ToImageMarkdown generates a markdown image link to the SVG image.
func (model *Pflow) ToImageMarkdown(state []TokenType) string {
	return ufmt.Sprintf("![Petri-net](https://pflow.dev/img/b=%s)", model.ToBase64(state))
}

func (model *Pflow) ToJson(state []TokenType) string {
	return "{}"
}

type WebHost struct {
	Base string
	Tag  string
	Path string
}

func (h *WebHost) Cdn() string {
	return h.Base + h.Tag + h.Path
}

func templateHtml(key, value string, s SourceProvider, path string) (out string) {
	out = strings.ReplaceAll(htmlContent, key, value)
	return strings.ReplaceAll(out, "{SOURCE}", s(path))
}

func Html(w *WebHost, s SourceProvider, path string) string {
	return templateHtml("{CDN}", w.Cdn(), s , path)
}

type SourceProvider = func(path string) string

func DataUrl(w *WebHost, s SourceProvider, path string) string {
	return "data:text/html;utf8," + url.PathEscape(Html(w, s, path))
}

var htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>pflow | model.svg</title>
    <style type="text/css">
        @import url("{CDN}pflow.css");
    </style>
</head>
<body>
    <a href="https://pflow.xyz" >
        <img src="{CDN}title.svg" alt="pflow logo" id="title" />
    </a>
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
</body>
</html>
`
