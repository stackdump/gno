package gnopages

import (
	"strings"
	"testing"
)

func TestHome(t *testing.T) {
	printedOnce := false
	got := Render("")
	expectedSubtrings := []string{
		"/r/gnoland/pages:p/tokenomics",
		"/r/gnoland/pages:p/start",
		"/r/gnoland/pages:p/contribute",
		"/r/gnoland/pages:p/about",
		"/r/gnoland/pages:p/gnolang",
	}
	for _, substring := range expectedSubtrings {
		if !strings.Contains(got, substring) {
			if !printedOnce {
				println(got)
				printedOnce = true
			}
			t.Errorf("expected %q, but not found.", substring)
		}
	}
}

func TestAbout(t *testing.T) {
	printedOnce := false
	got := Render("p/about")
	expectedSubtrings := []string{
		"gno.land Is A Platform To Write Smart Contracts In Gno",
		"gno.land is a next-generation smart contract platform using Gno, an interpreted version of the general-purpose Go\nprogramming language.",
	}
	for _, substring := range expectedSubtrings {
		if !strings.Contains(got, substring) {
			if !printedOnce {
				println(got)
				printedOnce = true
			}
			t.Errorf("expected %q, but not found.", substring)
		}
	}
}
