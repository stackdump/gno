// PKGPATH: gno.land/r/crossrealm_test
package crossrealm_test

import (
	"std"

	crossrealm "gno.land/r/demo/tests/crossrealm"
)

type fooer struct {
	s string
}

func (f *fooer) Foo() {
	f.s = "B"
	println("hello " + f.s + " " + std.CurrentRealm().PkgPath())
}

var f *fooer

func init() {
	f = &fooer{s: "A"}
	crossrealm.SetFooer(f)
	crossrealm.CallFooerFoo()
}

func main() {
	print(".")
}

// Error:
// new escaped mark has no object ID
