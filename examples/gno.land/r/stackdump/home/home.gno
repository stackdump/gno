package home

import (
	//"github.com/gnolang/gno/examples/gno.land/p/pflow/metamodel"
	"gno.land/p/pflow/metamodel"
)

const back = `
[Back](./home)
`

const index = `
# Stackdump

Hi, I’m Matt York—engineer, blockchain researcher, and creator of pflow.xyz, a Petri-net SDK for modeling complex systems.

Check out my latest thoughts on software design, blockchain, and Petri nets at [blog.stackdump.com](https://blog.stackdump.com).

Or, see what I'm working on lately at [github.com/stackdump](https://github.com/stackdump).

## Pages
* [pflow.xyz](?pflow) - Build State Machines Visually
* [svg](?svg) - Export your state machine to SVG
* [html](?html) - Export your state machine to HTML
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

func Render(path string) string {
	switch path {
	case "?svg":
		m := metamodel.NewPflow()
		return "```\n" + m.ToSVG() + "\n```"
	case "?html":
		m := metamodel.NewPflow()
		return "```\n" + m.ToHTML() + "\n```"
	case "?pflow":
		return pflow
	default:
		return index
	}
}
