package bmp

import (
	"encoding/base64"
	"gno.land/p/demo/ufmt"
	"strings"
)

func Render(path string) string {
	data := GenerateSVG()
	// Encode the SVG data to base64
	encoded := base64.StdEncoding.EncodeToString([]byte(data))
	// Create the data URL
	dataURL := ufmt.Sprintf("data:image/svg+xml;base64,%s", encoded)
	// create markdown image link
	return ufmt.Sprintf("![Petri-net](%s)", dataURL)
}

func GenerateSVG() string {
	width := 50
	height := 50

	// use string builder for better performance
	var sb strings.Builder

	sb.WriteString(ufmt.Sprintf(`<svg xmlns="http://www.w3.org/2000/svg" width="%d+5" height="%d+5" viewBox="0 0 %d %d">`, width, height, width, height))
	sb.WriteString(`
  <defs>
    <rect id="p" width="1" height="1"/>
  </defs>
  <style>
    .r { fill:#f00; }
    .g { fill:#0f0; }
    .b { fill:#00f; }
    svg { border: 1px solid black; }
    .r:hover { fill: #f00; }
    .g:hover { fill: #0f0; }
    .b:hover { fill: #00f; }

  </style>`)

	// Add reusable `use` elements for red, green, and blue pixels
	colors := []string{"r", "g", "b"}

	//fill every pixel with a color
	for i := 0; i < 50; i++ {
		for j := 0; j < 50; j++ {
			colorClass := colors[(i+j)%len(colors)]
			sb.WriteString(ufmt.Sprintf(`<use href="#p" x="%d" y="%d" class="%s"/>`, i, j, colorClass))
		}
	}

	// Close SVG
	sb.WriteString(`</svg>`)

	// Return the SVG string
	return sb.String()
}
