// PKGPATH: gno.land/r/demo/boards_test
package boards_test

// SEND: 200000000ugnot

import (
	"std"

	"gno.land/p/demo/testutils"
	"gno.land/r/demo/boards"
	"gno.land/r/demo/users"
)

var bid boards.BoardID

func init() {
	caller := testutils.TestAddress("caller")
	std.TestSetRealm(std.NewUserRealm(caller))
	users.Register("", "gnouser", "my profile")
	boards.CreateThread(1, "First Post (title)", "Body of the first post. (body)")
}

func main() {
	println(boards.Render("test_board"))
}

// Error:
// board not exist
