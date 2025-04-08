package metamodel

import (
	"encoding/base64"
	"gno.land/p/demo/ufmt"
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
func (net *Pflow) ToSvg(state []TokenType) string {
	svg := "<svg xmlns=\"http://www.w3.org/2000/svg\">"

	// Render places.
	for _, place := range net.Places {
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
	for _, transition := range net.Transitions {
		svg += ufmt.Sprintf("<rect x=\"%d\" y=\"%d\" width=\"30\" height=\"30\" fill=\"white\" stroke=\"black\" />", transition.X-15, transition.Y-15)
		svg += ufmt.Sprintf("<text x=\"%d\" y=\"%d\" font-size=\"10\">%s</text>", transition.X-20, transition.Y-20, transition.Label)
	}

	// Render arcs.
	for _, arc := range net.Arrows {
		source := net.Places[arc.Source]
		target := net.Transitions[arc.Target]
		svg += ufmt.Sprintf("<line x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\" stroke=\"black\" marker-end=\"url(#arrow)\" />", source.X, source.Y, target.X, target.Y)
	}

	svg += "</svg>"
	return svg
}

// ToBase64 encodes the SVG as a base64 string.
func (net *Pflow) ToBase64(state []TokenType) string {
	return base64.StdEncoding.EncodeToString([]byte(net.ToSvg(state)))
}

// ToLinkMarkdown generates a markdown link to the SVG image.
func (net *Pflow) ToLinkMarkdown(state []TokenType) string {
    return ufmt.Sprintf("![Petri-net](https://pflow.dev/img/b=%s)", net.ToBase64(state))
}

// ToImageMarkdown generates a markdown image link to the SVG image.
func (net *Pflow) ToImageMarkdown(state []TokenType) string {
    return ufmt.Sprintf("![Petri-net](https://pflow.dev/img/b=%s)", net.ToBase64(state))
}

func (net *Pflow) ToJson(state[]TokenType) string {
    return "{}"
}