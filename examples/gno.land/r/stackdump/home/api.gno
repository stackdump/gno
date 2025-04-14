package home

import (
	mm "gno.land/p/pflow/metamodel"
)

var webHost = &mm.WebHost{
	Base: "https://cdn.jsdelivr.net/gh/pflow-xyz/pflow-app@",
	Tag:  "0.2.0",
	Path: "/static/",
}

func Update(key, value string) {
	switch key {
	case "Base":
		webHost.Base = value
	case "Tag":
		webHost.Tag = value
	case "Path":
		webHost.Path = value
	case "intro":
        intro = value
    case "libraries":
        libraries = value
	default:
	    panic("Invalid key"+key)
	}
}

func Render(path string) string {
	return intro + libraries
}
