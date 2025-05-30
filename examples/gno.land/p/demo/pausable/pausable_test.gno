package pausable

import (
	"std"
	"testing"

	"gno.land/p/demo/ownable"
	"gno.land/p/demo/uassert"
	"gno.land/p/demo/urequire"
)

var (
	firstCaller = std.Address("g1l9aypkr8xfvs82zeux486ddzec88ty69lue9de")
	o           = ownable.NewWithAddress(firstCaller)
)

func TestNewFromOwnable(t *testing.T) {
	testing.SetOriginCaller(firstCaller)
	result := NewFromOwnable(o)

	urequire.Equal(t, firstCaller.String(), result.Ownable().Owner().String())
}

func TestSetUnpaused(t *testing.T) {
	testing.SetOriginCaller(firstCaller)
	result := NewFromOwnable(o)

	result.Unpause()
	uassert.False(t, result.IsPaused(), "Expected result to be unpaused")
}

func TestSetPaused(t *testing.T) {
	testing.SetOriginCaller(firstCaller)
	result := NewFromOwnable(o)

	result.Pause()
	uassert.True(t, result.IsPaused(), "Expected result to be paused")
}

func TestIsPaused(t *testing.T) {
	result := NewFromOwnable(o)
	urequire.False(t, result.IsPaused(), "Expected result to be unpaused")

	testing.SetOriginCaller(firstCaller)
	result.Pause()
	uassert.True(t, result.IsPaused(), "Expected result to be paused")
}

func TestOwnable(t *testing.T) {
	result := NewFromOwnable(o)

	uassert.Equal(t, result.Ownable().Owner(), o.Owner())
}
