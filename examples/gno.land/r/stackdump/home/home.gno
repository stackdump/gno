package home

import (
	mm "gno.land/p/pflow/metamodel"
)

const back = `
[Back](./home)
`

const modelPreview = `
[![pflow](https://pflow.dev/img/zb2rhbzaEAGY4L6SpmAByfdYr6jt945NmNY6zVZ1mWHK8Jjcb.svg)](https://pflow.dev/p/zb2rhbzaEAGY4L6SpmAByfdYr6jt945NmNY6zVZ1mWHK8Jjcb/)
`

const indexHeader = `
# Stackdump

Hi, I’m Matt York—engineer, blockchain researcher, and creator of pflow.xyz, a Petri-net SDK for modeling complex systems.

Check out my latest thoughts on software design, blockchain, and Petri nets at [blog.stackdump.com](https://blog.stackdump.com).

Or, see what I'm working on lately at [github.com/stackdump](https://github.com/stackdump).

## Libraries

### Pflow Metamodel - [gno.land/p/pflow/metamodel](/p/pflow/metamodel)
`

const index = indexHeader + modelPreview +
	"```\n" + exampleSource + "\n```\n" +
	menu

const menu = `
* [pflow.xyz](?pflow) - Build State Machines Visually
* [svg](?svg) - Export your state machine to SVG
* [html](?html) - Export your state machine to HTML
* [json](?json) - Export your state machine as Json (compatible with  [pflow.xyz/editor](https://pflow.xyz/editor))
`

const pflow = `
### Pflow.xyz

Build State Machines Visually -- and convert to source code. (gnolang templating coming soon).

[![pflow](https://pflow.dev/img/zb2rhbzaEAGY4L6SpmAByfdYr6jt945NmNY6zVZ1mWHK8Jjcb.svg)](https://pflow.dev/p/zb2rhbzaEAGY4L6SpmAByfdYr6jt945NmNY6zVZ1mWHK8Jjcb/)

Click on the above diagram to open in the pflow editor.

or read the [docs](https://pflow.dev/docs).
` + back

const svgHeader = `
### SVG
Export your state machine to SVG.
`

const htmlHeader = `
### HTML
Export your state machine to HTML.
`

const jsonHeader = `
### JSON
[![pflow](https://pflow.dev/img/zb2rhbzaEAGY4L6SpmAByfdYr6jt945NmNY6zVZ1mWHK8Jjcb.svg)](https://pflow.dev/p/zb2rhbzaEAGY4L6SpmAByfdYr6jt945NmNY6zVZ1mWHK8Jjcb/)
Copy the json below and paste it into the editor at [pflow.xyz/editor](https://pflow.xyz/editor) to interact with the state machine.
`

const exampleSource = `
import (
	mm "gno.land/p/pflow/metamodel"
)

...

// define petri net model using metamodel package
func exampleModel() *mm.Pflow {
	return &mm.Pflow{
		Places: map[string]mm.Place{
			"place0": {Offset: 0, Initial: 1, Capacity: 3, X: 130, Y: 207},
		},
		Transitions: map[string]mm.Transition{
			"txn0": {X: 46, Y: 116},
			"txn1": {X: 227, Y: 112},
			"txn2": {X: 43, Y: 307},
			"txn3": {X: 235, Y: 306},
		},
		Arcs: []mm.Arrow{
			{Source: "txn0", Target: "place0"},
			{Source: "place0", Target: "txn1", Weight: 3},
			{Source: "txn2", Target: "place0", Weight: 3, Inhibit: true},
			{Source: "place0", Target: "txn3", Inhibit: true},
		},
	}
}
`

// exampleModel returns a simple Petri net model.
func exampleModel() *mm.Pflow {
	return &mm.Pflow{
		Places: map[string]mm.Place{
			"place0": {Offset: 0, Initial: 1, Capacity: 3, X: 130, Y: 207},
		},
		Transitions: map[string]mm.Transition{
			"txn0": {X: 46, Y: 116},
			"txn1": {X: 227, Y: 112},
			"txn2": {X: 43, Y: 307},
			"txn3": {X: 235, Y: 306},
		},
		Arcs: []mm.Arrow{
			{Source: "txn0", Target: "place0"},
			{Source: "place0", Target: "txn1", Weight: 3},
			{Source: "txn2", Target: "place0", Weight: 3, Inhibit: true},
			{Source: "place0", Target: "txn3", Inhibit: true},
		},
	}
}

var m = exampleModel()

func Render(path string) string {
	switch path {
	case "?json":
		json, _ := m.ToJson()
		return jsonHeader + "```\n" + json + "\n```"
	case "?svg":
		return svgHeader + "```\n" + m.ToSVG() + "\n```"
	case "?html":
		return htmlHeader + "```\n" + m.ToHTML() + "\n```"
	case "?pflow":
		return pflow
	default:
		return index
	}
}
