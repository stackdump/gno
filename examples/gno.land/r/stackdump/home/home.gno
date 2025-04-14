package home

import (
	mm "gno.land/p/pflow/metamodel"
)

var intro = `
# Stackdump

Hi, I’m Matt York—engineer, blockchain researcher, and creator of pflow.xyz, a Petri-net SDK for modeling complex systems.

![Matt York](https://raw.githubusercontent.com/stackdump/stackdump/main/profile.jpg)

Check out my latest thoughts on software design, blockchain, and Petri nets at [blog.stackdump.com](https://blog.stackdump.com).

Or, see what I'm working on lately at [github.com/stackdump](https://github.com/stackdump).
`

var libraries = `
## Libraries

### [/p/pflow/metamodel](/p/pflow/metamodel)

- [Pflow metamodel](/p/pflow/metamodel) is a Gno library for modeling Petri nets. 
- It provides a simple API for defining places, transitions, and arrows, and can export the model as a markdown image or JSON.
- #### Dapp - JS Petri-net Editor
  - [DAPP](`+ mm.DataUrl(webHost) + `) - "Copy Link Address" then paste in browser to run the JS Widget
  - Pflow.xyz SDK [https://github.com/pflow-xyz/pflow-app/](https://github.com/pflow-xyz/pflow-app/)
`

// exampleModel returns a simple Petri net model.
func exampleModel() *mm.Pflow {
	return &mm.Pflow{
		Places: map[string]mm.Place{
			"place0": {Offset: 0, Initial: mm.T(1), Capacity: mm.T(3), X: 130, Y: 207},
		},
		Transitions: map[string]mm.Transition{
			"txn0": {X: 46, Y: 116},
			"txn1": {X: 227, Y: 112},
			"txn2": {X: 43, Y: 307},
			"txn3": {X: 235, Y: 306},
		},
		Arrows: []mm.Arrow{
			{Source: "txn0", Target: "place0", Weight: mm.T(1)},
			{Source: "place0", Target: "txn1", Weight: mm.T(3)},
			{Source: "txn2", Target: "place0", Weight: mm.T(3), Inhibit: true},
			{Source: "place0", Target: "txn3", Weight: mm.T(1), Inhibit: true},
		},
	}
}