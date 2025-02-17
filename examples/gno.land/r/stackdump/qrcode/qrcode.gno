// Package rfe - Request For Event Sample Memo Format
package rfe

import (
	"gno.land/p/demo/qrcode"
)

var qr = NewCode()

func NewCode() *qrcode.QRCode {
	qr := qrcode.NewQRCode()
	qr.SetTypeNumber(4)
	qr.SetErrorCorrectLevel(qrcode.ErrorCorrectLevelM)
	qr.AddData("Hello Gno!")
	qr.Make()
	return qr
}

func Render(_ string) string {
	return "## hello world \n\n" +
		"```" + qr.ToSvg() + "```\n\n" +
		qr.ToImageMarkdown() + ""
}
