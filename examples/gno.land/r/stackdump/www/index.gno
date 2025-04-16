package www

import (
    "net/url"
    "strings"
)

var (
    webHost = &WebHost{
        Base: "https://cdn.jsdelivr.net/gh/pflow-xyz/pflow-app@",
        Tag:  "0.2.1",
        Path: "/static/",
    }
)

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

var newSource = `
{
  "modelType": "PetriNet",
  "version": "v1",
  "tokens": ["black"],
  "places": {
    "place0": { "offset": 0, "initial": [1], "capacity": [3], "x": 130, "y": 207 }
  },
  "transitions": {
    "txn0": { "x": 46, "y": 116 },
    "txn1": { "x": 227, "y": 112 },
    "txn2": { "x": 43, "y": 307 },
    "txn3": { "x": 235, "y": 306 }
  },
  "arcs": [
    { "source": "txn0", "target": "place0", "weight": [1] },
    { "source": "place0", "target": "txn1", "weight": [3] },
    { "source": "txn2", "target": "place0", "weight": [3], "inhibit": true },
    { "source": "place0", "target": "txn3", "weight": [1], "inhibit": true }
  ]
}`

func Render(path string) string {
    return templateHtml("{CDN}", webHost.Cdn(), func(path string) string {
        return newSource
    }, path)
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