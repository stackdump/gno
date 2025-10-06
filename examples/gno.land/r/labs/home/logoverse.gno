package logoverse

import (
	eve "gno.land/p/eve/component"
)

type logoVerse struct {
	parents []string
    termset []map[string]any
    rows    []string // CIDs of rows (snapshots)
}

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

var LogoVerse = logoVerse{
    parents: []string{},
    termset: []map[string]any{},
    rows:  []string{},
}
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


func init() {
	LogoVerse.snapshot() // initialize first snapshot
}

func (lv logoVerse) Compose(o interface{}) eve.LogoGraph {
    switch val := o.(type) {
    case map[string]any:
        if parents, ok := val["parents"].([]string); ok {
            lv.parents = parents
        }
        if termset, ok := val["termset"].([]map[string]any); ok {
            lv.termset = termset
        }
        if cid, ok := val["commit"].(string); ok {
            lv.rows = append(lv.rows, cid)
        }
    default:
        panic("invalid type for Compose")
    }
    return lv
}

// TODO: consider refactoring to use a Compose(interface{}) method
// snapshot creates a snapshot of the current rows and returns its CID.
func (lv logoVerse) snapshot() string {
    return ""
}

func (logoVerse) FromPath(path string) eve.LogoGraph {
    return LogoVerse
}

func (logoVerse) ToPath() string {
    return "?"
}

func (lv logoVerse) JsonLD() eve.JsonLDMap {
	return eve.JsonLDMap{
		"@context":     []any{"https://schema.org", LogoverseContext},
		"@type":        "CreativeWork",
		"name":         "Logoverse",
		"description":  LogoVerse.Description(),
		"url":          "?glyph=Logoverse&embed=page",
		"image":        "?glyph=Logoverse&embed=img",
		"thumbnailUrl": "?glyph=Logoverse&embed=thumbnail",
		"@graph": map[string]any{
			"@id":     "{{CID}}",
			"@type":   "Glyph",
			"parents": lv.parents,
			"url":     "?glyph=Logoverse&embed=page",
		},
		"hasDefinedTerm": map[string]any{
			"@type":          "DefinedTermSet",
			"name":           "Logoverse Termset",
			"hasDefinedTerm": lv.termset,
		},
		"author": map[string]any{
			"@type": "Organization",
			"name":  "AllInBits",
			"url":   "https://allinbits.com",
		},
		"license": "https://github.com/gnolang/gno/blob/master/LICENSE.md",
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
