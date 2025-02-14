package metamodel

import (
	"gno.land/p/demo/ufmt"
)

const VERSION = "v0"
const PETRI_NET = "petriNet"

func Sprint(v interface{}) string {
	return ufmt.Sprintf("%v", v)
}

type Place struct {
	Label    string
	Offset   int
	Initial  *int
	Capacity *int
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
	Weight  *int
	Consume *bool
	Produce *bool
	Inhibit *bool
	Read    *bool
}

type Pflow struct {
	ModelType   string
	Version     string
	Places      map[string]Place
	Transitions map[string]Transition
	Arcs        []Arrow
}

type StateMachine struct {
	Model Pflow
	State map[string]int
	Rates map[string]int // rates of firing transitions - only useful for simulation
}

func NewStateMachine(m Pflow) StateMachine {
	return StateMachine{Model: m, State: setState(m), Rates: setRates(m)}
}

func setRates(m Pflow) map[string]int {
	rates := make(map[string]int)
	for label := range m.Transitions {
		rates[label] = 1 // default rate every transition is 1 == 100% rate of firing
	}
	return rates
}

func setState(m Pflow) map[string]int {
	state := make(map[string]int)
	for label, place := range m.Places {
		if place.Initial == nil {
			state[label] = 0
		} else {
			state[label] = *place.Initial
		}
	}
	return state
}

func (sm *StateMachine) SetRates(rates map[string]int) {
	for label, rate := range rates {
		if _, ok := sm.Model.Transitions[label]; ok {
			sm.Rates[label] = rate
		} else {
			panic("Transition %s not found in the model\n" + label)
		}
	}
}

func (sm *StateMachine) SetState(state map[string]int) {
	for label := range sm.Model.Places {
		if _, ok := state[label]; !ok {
			panic("Place" + label + "not found in the state\n")
		}
	}
	sm.State = state
}

func (sm *StateMachine) Transform(action string, multiple int) bool {
	newState := make(map[string]int)
	for k, v := range sm.State {
		newState[k] = v
	}

	for _, arc := range sm.Model.Arcs {
		if arc.Target == action {
			newState[arc.Source] -= *arc.Weight * multiple
			if newState[arc.Source] < 0 {
				return false
			}
		} else if arc.Source == action {
			newState[arc.Target] += *arc.Weight * multiple
		}
	}
	sm.State = newState
	return true
}

func NewPflow() Pflow {
	return Pflow{ModelType: PETRI_NET, Version: VERSION, Places: make(map[string]Place), Transitions: make(map[string]Transition), Arcs: []Arrow{}}
}

func (net *Pflow) AddPlace(label string, offset, initial, capacity, x, y *int) {
	if offset == nil {
		offset = new(int)
		*offset = len(net.Transitions)
	}
	net.Places[label] = Place{Label: label, Offset: *offset, Initial: initial, Capacity: capacity, X: *x, Y: *y}
}

func (net *Pflow) AddTransition(label string, offset *int, role string, x, y int) {
	if offset == nil {
		offset = new(int)
		*offset = len(net.Transitions)
	}
	net.Transitions[label] = Transition{Label: label, Offset: *offset, Role: role, X: x, Y: y}
}

func (net *Pflow) AddArc(source, target string, weight *int) {
	_, sourceExists := net.Places[source]
	_, targetExists := net.Places[target]

	consume := sourceExists && targetExists
	produce := targetExists && sourceExists

	net.Arcs = append(net.Arcs, Arrow{Source: source, Target: target, Weight: weight, Consume: &consume, Produce: &produce, Inhibit: new(bool), Read: new(bool)})
}

func (net *Pflow) AddGuard(source, target string, weight *int) {
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
	inhibit := true
	read := sourceIsTransition && targetIsPlace
	net.Arcs = append(net.Arcs, Arrow{Source: source, Target: target, Weight: weight, Consume: &consume, Produce: &produce, Inhibit: &inhibit, Read: &read})
}

type Display struct {
	Buffer string
	Model  Pflow
}

func NewDisplay(model Pflow) Display {
	return Display{Model: model}
}

func (d *Display) NewSVGImage(width, height *int) {
	w := 400
	h := 400
	if width != nil {
		w = *width
	}
	if height != nil {
		h = *height
	}
	d.Buffer += "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100%\" height=\"100%\" viewBox=\"0 0 " + Sprint(w) + " " + Sprint(h) + "\">"
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
	tokens := 0
	if place.Initial != nil {
		tokens = *place.Initial
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
	if *arc.Inhibit {
		marker = "url(#markerInhibit1)"
	}
	extra := "stroke=\"#000000\" fill=\"#000000\" marker-end=\"" + marker + "\""

	var p Place
	var t Transition
	if *arc.Inhibit {
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
		weight := 1
		if arc.Weight != nil {
			weight = *arc.Weight
		}
		d.Text(midX-4, midY+4, Sprint(weight), "font-size=\"small\"")
	} else {
		p = d.Model.Places[arc.Target]
		t = d.Model.Transitions[arc.Source]
		d.Line(t.X, t.Y, p.X, p.Y, extra)
		midX := (t.X + p.X) / 2
		midY := (t.Y+p.Y)/2 - 8
		weight := 1
		if arc.Weight != nil {
			weight = *arc.Weight
		}
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

func (net Pflow) ToHTML() string {
	d := NewDisplay(net)
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
	maxX += 100
	maxY += 100
	d.NewSVGImage(&maxX, &maxY)
	d.Render()
	return d.ToHTML()
}

func (net Pflow) ToSVG() string {
	d := NewDisplay(net)
	d.NewSVGImage(nil, nil)
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
