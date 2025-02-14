package metamodel

import (
	"gno.land/p/demo/ufmt"
)

func Sprint(v interface{}) string {
	return ufmt.Sprintf("%v", v)
}

// Value is a type alias for int64.
type Value = int64 // REVIEW: could this be a generic type in gnolang?

type Place struct {
	Label    string
	Offset   int
	Initial  Value
	Capacity Value
	X        int
	Y        int
}

type Transition struct {
	Label  string
	Offset int
	Role   string
	X      int
	Y      int
}

type Arrow struct {
	Source  string
	Target  string
	Weight  Value
	Consume bool
	Produce bool
	Inhibit bool
	Read    bool
}

type Pflow struct {
	Places      map[string]Place
	Transitions map[string]Transition
	Arcs        []Arrow
}

type StateMachine struct {
	Model *Pflow
	State map[string]Value
}

func NewStateMachine(m *Pflow) StateMachine {
	return StateMachine{Model: m, State: setState(m)}
}

func setState(m *Pflow) map[string]Value {
	state := make(map[string]Value)
	for label, place := range m.Places {
		state[label] = place.Initial
	}
	return state
}

func (sm *StateMachine) SetState(state map[string]Value) {
	for label := range sm.Model.Places {
		if _, ok := state[label]; !ok {
			panic("Place" + label + "not found in the state\n")
		}
	}
	sm.State = state
}

func (sm *StateMachine) Transform(action string, multiple Value) bool {
	if multiple < 0 {
		return false
	}
	_, ok := sm.Model.Transitions[action]
	if !ok {
		return false
	}
	newState := make(map[string]Value)
	for k, v := range sm.State {
		newState[k] = v
	}

	for _, arc := range sm.Model.Arcs {
		if arc.Target == action {
			newState[arc.Source] -= arc.Weight * multiple
			if newState[arc.Source] < 0 {
				return false
			}
		} else if arc.Source == action {
			newState[arc.Target] += arc.Weight * multiple
		}
	}
	sm.State = newState
	return true
}

func NewPflow() *Pflow {
	return &Pflow{Places: make(map[string]Place), Transitions: make(map[string]Transition), Arcs: []Arrow{}}
}

func (net *Pflow) Place(label string, initial Value, capacity Value, x, y int) {
	net.Places[label] = Place{Label: label, Offset: len(net.Places), Initial: initial, Capacity: capacity, X: x, Y: y}
}

func (net *Pflow) Transition(label string, role string, x, y int) {
	net.Transitions[label] = Transition{Label: label, Offset: len(net.Transitions), Role: role, X: x, Y: y}
}

func (net *Pflow) Arrow(source, target string, weight Value) {
	consume := false
	produce := false

	_, sourceIsPlace := net.Places[source]
	_, targetIsPlace := net.Places[target]
	_, sourceIsTransition := net.Transitions[source]
	_, targetIsTransition := net.Transitions[target]

	if sourceIsPlace && targetIsTransition {
		consume = true
	}
	if sourceIsTransition && targetIsPlace {
		produce = true
	}

	net.Arcs = append(net.Arcs, Arrow{Source: source, Target: target, Weight: weight, Consume: consume, Produce: produce, Inhibit: false, Read: false})
}

func (net *Pflow) Guard(source, target string, weight Value) {
	consume := false
	produce := false
	read := false

	_, sourceIsPlace := net.Places[source]
	_, targetIsPlace := net.Places[target]
	_, sourceIsTransition := net.Transitions[source]
	_, targetIsTransition := net.Transitions[target]

	if sourceIsPlace && targetIsTransition {
		consume = true
	}
	if sourceIsTransition && targetIsPlace {
		produce = true
		read = true
	}
	net.Arcs = append(net.Arcs, Arrow{Source: source, Target: target, Weight: weight, Consume: consume, Produce: produce, Inhibit: true, Read: read})
}

type Display struct {
	Buffer string
	Model  *Pflow
	State  map[string]Value
}

func NewDisplay(model *Pflow, state ...map[string]Value) Display {
	if len(state) == 1 {
		return Display{Model: model, State: state[0]}
	}
	return Display{Model: model, State: make(map[string]Value)}
}

func (d *Display) NewSVGImage(w, h int) {
	d.Buffer += "<svg xmlns=\"http://www.w3.org/2000/svg\" w=\"100%\" h=\"100%\" viewBox=\"0 0 " + Sprint(w) + " " + Sprint(h) + "\">"
	d.Rect(0, 0, w, h, "fill=\"#ffffff\"")
	d.WriteDefs()
}

func (d *Display) WriteDefs() {
	d.Buffer += "<defs>" +
		"<marker id=\"markerArrow1\" markerWidth=\"23\" markerHeight=\"13\" refX=\"31\" refY=\"6\" orient=\"auto\">" +
		"<rect width=\"28\" height=\"3\" fill=\"white\" stroke=\"white\" x=\"3\" y=\"5\"/>" +
		"<path d=\"M2,2 L2,11 L10,6 L2,2\"/>" +
		"</marker>" +
		"<marker id=\"markerInhibit1\" markerWidth=\"23\" markerHeight=\"13\" refX=\"31\" refY=\"6\" orient=\"auto\">" +
		"<rect width=\"28\" height=\"3\" fill=\"white\" stroke=\"white\" x=\"3\" y=\"5\"/>" +
		"<circle cx=\"5\" cy=\"6.5\" r=\"4\"/>" +
		"</marker>" +
		"</defs>"
}

func (d *Display) Gend() {
	d.WriteElement("</g>")
}

func (d *Display) WriteElement(element string) {
	d.Buffer += element
}

func (d *Display) Render() {
	for _, arc := range d.Model.Arcs {
		d.ArcElement(arc)
	}
	for label, place := range d.Model.Places {
		d.PlaceElement(label, place)
	}
	for label, transition := range d.Model.Transitions {
		d.TransitionElement(label, transition)
	}
	d.EndSVG()
}

func (d *Display) PlaceElement(label string, place Place) {
	d.Group()
	d.Circle(place.X, place.Y, 16, "stroke-width=\"1.5\" fill=\"#ffffff\" stroke=\"#000000\"")
	d.Text(place.X-18, place.Y-20, label, "font-size=\"small\"")
	x := place.X
	y := place.Y
	tokens := place.Initial
	if state, ok := d.State[label]; ok {
		tokens = state
	}
	if tokens > 0 {
		if tokens == 1 {
			d.Circle(x, y, 2, "fill=\"#000000\" stroke=\"#000000\"")
		} else if tokens < 10 {
			d.Text(x-4, y+5, Sprint(tokens), "font-size=\"large\"")
		} else {
			d.Text(x-7, y+5, Sprint(tokens), "font-size=\"small\"")
		}
	}
	d.Gend()
}

func (d *Display) ArcElement(arc Arrow) {
	d.Group()
	marker := "url(#markerArrow1)"
	if arc.Inhibit {
		marker = "url(#markerInhibit1)"
	}
	extra := "stroke=\"#000000\" fill=\"#000000\" marker-end=\"" + marker + "\""

	var p Place
	var t Transition
	if arc.Inhibit {
		if place, ok := d.Model.Places[arc.Source]; ok {
			p = place
			t = d.Model.Transitions[arc.Target]
		} else {
			p = d.Model.Places[arc.Target]
			t = d.Model.Transitions[arc.Source]
		}
	} else {
		if place, ok := d.Model.Places[arc.Source]; ok {
			p = place
			t = d.Model.Transitions[arc.Target]
		} else {
			p = d.Model.Places[arc.Target]
			t = d.Model.Transitions[arc.Source]
		}
	}

	if place, ok := d.Model.Places[arc.Source]; ok {
		p = place
		t = d.Model.Transitions[arc.Target]
		d.Line(p.X, p.Y, t.X, t.Y, extra)
		midX := (p.X + t.X) / 2
		midY := (p.Y+t.Y)/2 - 8
		weight := arc.Weight
		d.Text(midX-4, midY+4, Sprint(weight), "font-size=\"small\"")
	} else {
		p = d.Model.Places[arc.Target]
		t = d.Model.Transitions[arc.Source]
		d.Line(t.X, t.Y, p.X, p.Y, extra)
		midX := (t.X + p.X) / 2
		midY := (t.Y+p.Y)/2 - 8
		weight := arc.Weight
		d.Text(midX-4, midY+4, Sprint(weight), "font-size=\"small\"")
	}
	d.Gend()
}

func (d *Display) TransitionElement(label string, transition Transition) {
	d.Group()
	x := transition.X - 17
	y := transition.Y - 17
	d.Rect(x, y, 30, 30, "stroke=\"#000000\" fill=\"#ffffff\" rx=\"4\"")
	d.Text(x, y-8, label, "font-size=\"small\"")
	d.Gend()
}

func (d *Display) EndSVG() {
	d.Buffer += "</svg>"
}

func (d *Display) ToHTML() string {
	return "<!DOCTYPE html><html><body>" + d.Buffer + "</body></html>"
}

func (net *Pflow) GetLimits() (int, int) {
	maxX := 0
	maxY := 0
	for _, p := range net.Places {
		if p.X > maxX {
			maxX = p.X
		}
		if p.Y > maxY {
			maxY = p.Y
		}
	}
	for _, t := range net.Transitions {
		if t.X > maxX {
			maxX = t.X
		}
		if t.Y > maxY {
			maxY = t.Y
		}
	}
	return maxX, maxY
}

func (net *Pflow) ToHTML(state ...map[string]Value) string {
	s := make(map[string]Value)
	if len(state) == 1 {
		s = state[0]
	}
	d := NewDisplay(net, s)
	maxX, maxY := net.GetLimits()
	d.NewSVGImage(maxX, maxY)
	d.Render()
	return d.ToHTML()
}

func (net *Pflow) ToSVG(state ...map[string]Value) string {
	s := make(map[string]Value)
	if len(state) == 1 {
		s = state[0]
	}
	d := NewDisplay(net, s)
	maxX, maxY := net.GetLimits()
	d.NewSVGImage(maxX, maxY)
	d.Render()
	return d.Buffer
}

func (d *Display) Rect(x, y, width, height int, extra string) {
	d.WriteElement("<rect x=\"" + Sprint(x) + "\" y=\"" + Sprint(y) + "\" width=\"" + Sprint(width) + "\" height=\"" + Sprint(height) + "\" " + extra + " />")
}

func (d *Display) Circle(x, y, radius int, extra string) {
	d.WriteElement("<circle cx=\"" + Sprint(x) + "\" cy=\"" + Sprint(y) + "\" r=\"" + Sprint(radius) + "\" " + extra + " />")
}

func (d *Display) Text(x, y int, txt, extra string) {
	d.WriteElement("<text x=\"" + Sprint(x) + "\" y=\"" + Sprint(y) + "\" " + extra + ">" + txt + "</text>")
}

func (d *Display) Line(x1, y1, x2, y2 int, extra string) {
	d.WriteElement("<line x1=\"" + Sprint(x1) + "\" y1=\"" + Sprint(y1) + "\" x2=\"" + Sprint(x2) + "\" y2=\"" + Sprint(y2) + "\" " + extra + " />")
}

func (d *Display) Group() {
	d.WriteElement("<g>")
}

// ToJson returns a JSON representation of the Petri net model.
// Open the JSON with https://pflow.xyz/editor to interact with the state machine.
func (net *Pflow) ToJson() (string, error) {
	jsonStr := "{"
	jsonStr += "\"modelType\":\"petriNet\","
	jsonStr += "\"version\":\"v0\","
	jsonStr += "\"places\":{"
	first := true
	for label, place := range net.Places {
		if !first {
			jsonStr += ","
		}
		first = false
		jsonStr += "\"" + label + "\":{"
		jsonStr += "\"offset\":" + Sprint(place.Offset) + ","
		jsonStr += "\"initial\":" + Sprint(place.Initial) + ","
		jsonStr += "\"capacity\":" + Sprint(place.Capacity) + ","
		jsonStr += "\"x\":" + Sprint(place.X) + ","
		jsonStr += "\"y\":" + Sprint(place.Y)
		jsonStr += "}"
	}
	jsonStr += "},"
	jsonStr += "\"transitions\":{"
	first = true
	for label, transition := range net.Transitions {
		if !first {
			jsonStr += ","
		}
		first = false
		jsonStr += "\"" + label + "\":{"
		jsonStr += "\"x\":" + Sprint(transition.X) + ","
		jsonStr += "\"y\":" + Sprint(transition.Y)
		jsonStr += "}"
	}
	jsonStr += "},"
	jsonStr += "\"arcs\":["
	first = true
	for _, arc := range net.Arcs {
		if !first {
			jsonStr += ","
		}
		first = false
		jsonStr += "{"
		jsonStr += "\"source\":\"" + arc.Source + "\","
		jsonStr += "\"target\":\"" + arc.Target + "\""
		if arc.Weight != 0 {
			jsonStr += ",\"weight\":" + Sprint(arc.Weight)
		}
		if arc.Inhibit {
			jsonStr += ",\"inhibit\":true"
		}
		jsonStr += "}"
	}
	jsonStr += "]"
	jsonStr += "}"
	return jsonStr, nil
}
