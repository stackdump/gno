package bmp

import (
	"gno.land/p/demo/avl"
	"gno.land/p/demo/ufmt"
	"std"
	"strings"
)

var (
	registry         = avl.NewTree()
	realmAllowPrefix = []string{}
)

func init() {
	allowPatchesFromSubRealms()
}

func allowPatchesFromSubRealms() {
	realmAllowPrefix = append(realmAllowPrefix, std.CurrentRealm().PkgPath()+"/") // must be in realm sub-path
}

func hasAllowedPrefix() bool {
	prevRealm := std.PreviousRealm()
	for _, callerPath := range realmAllowPrefix {
		if strings.HasPrefix(prevRealm.PkgPath(), callerPath) {
			return true
		}
	}
	return false
}

func assertAccess() {
	if !hasAllowedPrefix() {
		panic("access denied: " + std.PreviousRealm().PkgPath() +
			" realm must match an allowed prefix:[" + strings.Join(realmAllowPrefix, ",") + "]")
	}
}

// assertValidName controls the name of the image by the caller path
// ex1: /r/stackdump/bmp/v0.0.1_profile is allowed to set "profile" image
// ex2: /r/stackdump/bmp/v0.0.1/subfolder/profile is allowed to set "profile" image
func assertValidName(name string) {
	if !strings.HasSuffix(std.PreviousRealm().PkgPath(), name) {
		panic("invalid name: " + name + " must end with " + std.PreviousRealm().PkgPath())
	}
}

type PixelSetter = func(x, y, r, g, b int)

type ImageApi interface {
	Pixels(p PixelSetter)
	Bounds() Bounds
}

func Register(name string, imgHandler ImageApi) {
	assertAccess()
	assertValidName(name)
	if _, exists := registry.Get(name); !exists {
		std.Emit("image_registered", "name", name)
	} else {
		std.Emit("image_updated", "name", name)
	}
	registry.Set(name, imgHandler)
}

func renderList(selected string) string {
	if registry.Size() == 0 {
		return "No images registered."
	}

	keys := make([]string, 0, registry.Size())
	registry.IterateByOffset(0, registry.Size(), func(key string, value any) bool {
		keys = append(keys, key)
		return false
	})

	// Find the index of the selected image
	selectedIndex := -1
	for i, key := range keys {
		if key == selected {
			selectedIndex = i
			break
		}
	}

	if selectedIndex == -1 {
		return "Selected image not found."
	}

	// Get previous and next images circularly
	prevIndex := (selectedIndex - 1 + len(keys)) % len(keys)
	nextIndex := (selectedIndex + 1) % len(keys)

	return "[bmp]( ./bmp:" + keys[selectedIndex] + ":source):" +
		"[" + keys[selectedIndex] + "]( ./bmp:" + keys[selectedIndex] + ")\n\n" +
		"[<- prev](./bmp:" + keys[prevIndex] + ")\n" +
		"[next ->]( ./bmp:" + keys[nextIndex] + ")\n"
}

func getImageApi(path string) ImageApi {
	imgHandler, ok := registry.Get(path)
	if !ok {
		panic("path not registered: " + path)
	}
	return imgHandler.(ImageApi)
}

func Html() string {
	return Bmp.Html()
}

func Svg(name string) string {
	builder := getImageApi(name)

	img := &PixelImage{
		Pixels: make([]ColorPixel, 50*50),
		Bounds: builder.Bounds(),
	}
	builder.Pixels(img.SetPixel)
	return img.ToSvg()
}

func Render(path string) (out string) {
	defer func() {
		if r := recover(); r != nil {
			out = ufmt.Sprint(r)
		}
	}()
	args := []string{}
	if path == "" {
		path = "profile"
	} else {
		args = strings.Split(path, ":")
		if len(args) > 1 {
			path = args[0]
		}
	}
	if path == "dapp" {
		out += "\n\n" + Bmp.Markdown() + "\n\n"
		return out
	}
	builder := getImageApi(path)
	img := &PixelImage{
		Pixels: make([]ColorPixel, 50*50),
		Bounds: builder.Bounds(),
	}
	builder.Pixels(img.SetPixel)
	out = img.ToMarkdown()
	out += "\n\n" + renderList(path) + "\n\n"
	out += "\n\n[PIXELFIED DAPP](./bmp:dapp)\n\n"

	if len(args) == 2 {
		if args[1] == "source" {
			return "```\n" + img.Source(args[0]) + "```"
		}
	}
	return out
}
