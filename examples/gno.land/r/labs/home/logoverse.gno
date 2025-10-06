package logoverse

import (
	eve "gno.land/p/eve/component"
)

type logoVerse struct{}

var LogoverseContext = eve.JsonLDMap{
	"@version":  1.1,
	"logoverse": "/r/labs/home",

	// Term definitions
	"Glyph": "logoverse:Glyph",
	"parents": map[string]any{
		"@id":        "logoverse:parents",
		"@type":      "@id",
		"@container": "@set",
	},
	"commit": map[string]any{
		"@id":   "logoverse:commit",
		"@type": "@id",
	},
}

var LogoVerse = logoVerse{}
var _ eve.LogoGraph = LogoVerse
var _ eve.PageTemplate = LogoVerse

func (logoVerse) Cid() string {
	return LogoVerse.JsonLD().Cid()
}

func (logoVerse) renderOpts() map[string]any {
	return map[string]any{
		"dev":      map[string]any{},
		"labsnet1": map[string]any{},
	}
}

func (logoVerse) Image() string {
	return AibLabs.Image()
}

func (logoVerse) DataUrl() string {
	return AibLabs.DataUrl()
}

func (logoVerse) Thumbnail() string {
	return AibLabs.Thumbnail()
}

func (logoVerse) SVG() string {
	return AibLabs.SVG()
}

var termset []map[string]any

func init() {
    LogoVerse.snapshot() // initialize first snapshot
}

// snapshot creates a snapshot of the current rows and returns its CID.
func (logoVerse) snapshot() string {
	for _, cid := range rows {
		if v, ok := registry.Get(cid); ok {
			r := v.(Record)
			termset = append(termset, map[string]any{
                "@type":       "DefinedTerm",
				"name":        r.Name,
				"description": r.Description,
			})
		} else {
            panic("unregistered cid: " + cid)
        }
	}

    cid := rows[0]
    obj, ok  := registry.Get(cid)
    if !ok {
        panic("unregistered cid: " + cid)
    }
    rec := obj.(Record)
    rows[0] = Register(rec.Object) // register snapshot
    return rows[0]
}

func (logoVerse) JsonLD() eve.JsonLDMap {
	return eve.JsonLDMap{
		"@context":    []any{"https://schema.org", LogoverseContext},
		"@type":       "CreativeWork",
		"@id":         "{{CID}}",
		"name":        "Logoverse",
		"description": LogoVerse.Description(),
		"url":         "?glyph=Logoverse&embed=page",
		"image":      "?glyph=Logoverse&embed=img",
		"thumbnailUrl":   "?glyph=Logoverse&embed=thumbnail",
		"author": map[string]any{
			"@type": "Organization",
			"name":  "AllInBits",
			"url":   "https://allinbits.com",
		},
		"license": "https://github.com/gnolang/gno/blob/master/LICENSE.md",
		"hasPart": map[string]any{
			"@type": "WebPage",
			"name":  "Glyph",
			"url":   "?glyph=Glyph",
			"about": "Glyph is the fundamental building block of the Logoverse.",
		},
		"hasDefinedTerm": map[string]any{
            "@type":   "DefinedTermSet",
            "name":    "Logoverse Termset",
            "hasDefinedTerm": termset,
        },
	}
}

func (logoVerse) ThumbnailSvg(width, height string) string {
	return AibLabs.ThumbnailSvg(width, height)
}

func (logoVerse) Description() string {
	return `Software as a Universe.`
}

func (logoVerse) Introduction() string {
	return `## What is the Logoverse?
The [**Logoverse**](?glyph=Logoverse&embed=page) is like a digital universe made up of tiny building blocks called **objects**.
Each object has a permanent identity (a **CID**) and can be combined with others to form bigger ideas.

- **Immutable:** once created, objects never change.
- **Composable:** you can link and combine objects to make new ones.
- **Transparent:** every object carries its own history by default.

Think of it as a library where every page is alive: when you follow a link, it doesn’t just show you something—it *creates* a new object.

This is **Software as a Universe**.
Stop writing services. **Start minting universes.**`
}

func (logoVerse) Render(path string) string {
	return LogoVerse.Introduction()
}
