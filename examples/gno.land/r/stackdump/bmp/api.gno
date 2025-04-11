package bmp

import (
	"gno.land/p/demo/ufmt"
	"std"
	"strings"
)

var (
	registry         = make(map[string]ImageApi) // TODO: use AVL Tree
	realmAllowPrefix = []string{}
)

func init() {
	allowPatchesFromSubRealms()
}

func allowPatchesFromSubRealms() {
	realmAllowPrefix = append(realmAllowPrefix, std.CurrentRealm().PkgPath()+"/") // must be in realm sub-path
}

func HasAllowedPrefix() bool {
	prevRealm := std.PreviousRealm()
	for _, callerPath := range realmAllowPrefix {
		if strings.HasPrefix(prevRealm.PkgPath(), callerPath) {
			return true
		}
	}
	return false
}

func AssertAccess() {
	if !HasAllowedPrefix() {
		panic("access denied: " + std.PreviousRealm().PkgPath() +
			" realm must match an allowed prefix:[" + strings.Join(realmAllowPrefix, ",") + "]")
	}
}

func AssertValidName(name string) {
	if !strings.HasSuffix(std.PreviousRealm().PkgPath(), name) {
		panic("invalid name: " + name + " must end with " + std.PreviousRealm().PkgPath())
	}
}

type PixelSetter = func(x, y, r, g, b int)

type ImageApi interface {
	Pixels(p PixelSetter)
	Bounds() Bounds
}

func Register(name string, handler ImageApi) {
	AssertAccess()
	AssertValidName(name)
	if _, exists := registry[name]; !exists {
		registry[name] = handler
	}
}

func RenderList(selected string) string {
    if len(registry) == 0 {
        return "No images registered."
    }

    keys := make([]string, 0, len(registry))
    for key := range registry {
        keys = append(keys, key)
    }

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

    return "[bmp:"+keys[selectedIndex]+"]( ./bmp:" + keys[selectedIndex] + ")\n\n" +
           "[<- prev](./bmp:" + keys[prevIndex] + ")\n" +
           "[next ->]( ./bmp:" + keys[nextIndex] + ")\n"
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
        out += "\n\n"+Dapp()+"\n\n"
        return out
	}
	handler, ok := registry[path]
	if !ok {
		panic("path not registered: " + path)
	}
	img := NewPixelImage(50, handler.Bounds())
	handler.Pixels(img.SetPixel)
    out = img.ToMarkdown()
    out += "\n\n"+RenderList(path)+"\n\n"
    out += "\n\n[PIXEFIED DAPP](./bmp:dapp)\n\n"

	if len(args) == 2 {
	    if args[1] == "source" {
            return "```\n" + img.Source(args[0]) + "```"
	    }
	}
    return out
}
