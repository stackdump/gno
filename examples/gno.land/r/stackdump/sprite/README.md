# 🧱 sprite – Pixelized Image Registration for Gno.land

This project enables **pixel-perfect visual rendering on Gno.land** through a dual-mode approach:

1. **Gno Module (`sprite`)**: Register named pixel-art sprites using callback functions that describe each pixel.
2. **JavaScript Widget**: Generate Gno-compatible sprite code from any uploaded image via a browser-based pixelizer tool.

---

## 🌈 What is a Sprite?

A **sprite** is a tiny pixel-art image defined in code. Each sprite:

- Implements `Bounds()` to define its width and height.
- Implements `Pixels(p PixelSetter)` to declare each colored pixel.

These sprite modules can be registered by name and used in visual Gno applications.

Example sprite registration in Gno:
```go
package gnome

import "gno.land/r/stackdump/sprite"

type Gnome struct{}

func init() {
  sprite.Register("gnome", Gnome{})
}

func (Gnome) Bounds() sprite.Bounds {
  return sprite.Bounds{X1: 0, Y1: 0, X2: 50, Y2: 50}
}

func (Gnome) Pixels(p sprite.PixelSetter) {
  p(9, 22, 254, 254, 254)
  p(9, 23, 250, 251, 251)
  // ...
}
