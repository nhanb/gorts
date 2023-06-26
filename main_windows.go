//go:build windows

package main

import (
	"fmt"
	"strconv"

	"github.com/lxn/win"
)

const DefaultTclPath = "./IronTcl/bin/wish86t.exe"

func forceFocus(handle string) error {
	hex := handle[2:] // trim the "0x" prefix
	uintHandle, err := strconv.ParseUint(hex, 16, 64)
	if err != nil {
		return fmt.Errorf("failed to parse handle: %w", err)
	}

	h := win.HWND(uintptr(uintHandle))
	win.SetForegroundWindow(h)
	win.SetFocus(h)
	return nil
}
