package grc20

import (
	"strings"

	mm "gno.land/p/labs/metamodel"
)

// REVIEW: conversion to julia w/ Algebraic Petri Nets
// https://gist.github.com/stackdump/33dcd8e6f071d391c998008dfeac6ed9

var pflowLink = `
[![pflow](https://pflow.dev/img/zb2rhdVMFVdcBLYqpMJh8Vk4awKUf5GeWsuURmeTxRghdAmQx.svg)](https://pflow.dev/p/zb2rhdVMFVdcBLYqpMJh8Vk4awKUf5GeWsuURmeTxRghdAmQx/)
`


func init() {
    defaultCid := GRC20(modelOpts).Cid()
    if defaultCid != "bafkreihv25z3g7w54mw55vxyeurjao76nlqhowrrmiibym575uatuayxl4" {
		panic("model version mismatch: " + defaultCid)
	}
	forgetObjectsCid := GRC20(modelOpts).ForgetObjects().Cid()
	if forgetObjectsCid != "bafkreidcy54crfmtx4odm2i6doj4dhuevt3leg525yilkfco4gldaamfly" {
	    panic("forget objects mismatch: " + forgetObjectsCid)
    }
}

var monotoneNote = `
> A **monotone** net is one where tokens have **no named color**,
> but still participate in transitions according to the net's structure.

`

func Render(path string) string {
	opts := map[string]any{}
	for k, v := range modelOpts {
		opts[k] = v
	}
	switch path {
	case "token":
		opts["objects"] = []string{Token, Allow} // "Token" oriented view
	case "allow":
		opts["objects"] = []string{Allow, Token} // "Allow" oriented view
	case "monotone":
		return RenderModel(GRC20(opts).ForgetObjects(), path)
	case "pflow":
		return RenderModel(nil, path)
	default:
	}
	return RenderModel(GRC20(opts), path)
}

func navMenu(path string) string {
	base := modelOpts["BasePath"].(string)

	var navigation = map[string]string{
		"monotone": "[Monotone](" + base + ":monotone)",
		"token":    "[Token](" + base + ":token)",
		"allow":    "[Allow](" + base + ":allow)",
		"pflow":    "[PFlow](" + base + ":pflow)",
	}

	p := "monotone"
	if len(path) > 0 {
		p = path
	}

	var sb strings.Builder
	sb.WriteString("- **Switch View** | ")
	first := true
	for key, item := range navigation {
		if !first {
			sb.WriteString(" | ")
		}
		if key == p {
			// Show as plain text, not a link
			sb.WriteString("**" + strings.Title(key) + "**")
		} else {
			sb.WriteString(item)
		}
		first = false
	}
	sb.WriteString("\n\n### Diagram\n")

	return sb.String()
}

func RenderModel(m *mm.Model, path string) string {
	var sb strings.Builder
	sb.WriteString(navMenu(path))
	if path == "pflow" {
		sb.WriteString("Link to External - monotone with simulation \n\n")
		sb.WriteString(pflowLink)
		sb.WriteString("\n\n")
	} else {
	    if path == "monotone" {
            sb.WriteString(monotoneNote)
            sb.WriteString("\n\n")
        }
		sb.WriteString("\n\n Model ID: " + m.Cid() + "\n\n")
		sb.WriteString(m.Markdown())
	}
	return sb.String()
}
