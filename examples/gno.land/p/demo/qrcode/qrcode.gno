package qrcode

import (
	"encoding/base64"
)

//  qrcode package was ported from another project:
//
//  https://github.com/kazuhikoarase/qrcode-generator/blob/master/LICENSE
//  Copyright (c) 2012 Kazuhiko Arase
//
//  URL: http://www.d-project.com/
//
//  Licensed under the MIT license:
//     http://www.opensource.org/licenses/mit-license.php
//
//  The word 'QR Code' is registered trademark of
//  DENSO WAVE INCORPORATED
//     http://www.denso-wave.com/qrcode/faqpatent-e.html
//

type ErrorCorrectLevel struct{}

const (
	ErrorCorrectLevelL = 1 // 7%
	ErrorCorrectLevelM = 0 // 15%
	ErrorCorrectLevelQ = 3 // 25%
	ErrorCorrectLevelH = 2 // 30%
)

type QRCode struct {
	typeNumber        int
	errorCorrectLevel int
	qrDataList        []QR8BitByte
	modules           [][]bool
	moduleCount       int
}

const (
	PAD0 = 0xEC
	PAD1 = 0x11
)

func NewQRCode() *QRCode {
	return &QRCode{
		typeNumber:        1,
		errorCorrectLevel: ErrorCorrectLevelH,
		qrDataList:        []QR8BitByte{},
		modules:           [][]bool{},
		moduleCount:       0,
	}
}

func (qr *QRCode) SetTypeNumber(typeNumber int) {
	qr.typeNumber = typeNumber
}

func (qr *QRCode) SetErrorCorrectLevel(errorCorrectLevel int) {
	qr.errorCorrectLevel = errorCorrectLevel
}

func (qr *QRCode) AddData(data string) {
	qr.qrDataList = append(qr.qrDataList, QR8BitByte{data})
}

func (qr *QRCode) Make() {
	qr.moduleCount = qr.typeNumber*4 + 17
	qr.modules = make([][]bool, qr.moduleCount)
	for i := range qr.modules {
		qr.modules[i] = make([]bool, qr.moduleCount)
	}

	qr.setupPositionProbePattern(0, 0)
	qr.setupPositionProbePattern(qr.moduleCount-7, 0)
	qr.setupPositionProbePattern(0, qr.moduleCount-7)
}

func (qr *QRCode) setupPositionProbePattern(row, col int) {
	for r := -1; r <= 7; r++ {
		for c := -1; c <= 7; c++ {
			if row+r < 0 || qr.moduleCount <= row+r || col+c < 0 || qr.moduleCount <= col+c {
				continue
			}
			qr.modules[row+r][col+c] = (r >= 0 && r <= 6 && (c == 0 || c == 6)) ||
				(c >= 0 && c <= 6 && (r == 0 || r == 6)) ||
				(r >= 2 && r <= 4 && c >= 2 && c <= 4)
		}
	}
}

func (qr *QRCode) IsDark(row, col int) bool {
	return qr.modules[row][col]
}

func (qr *QRCode) GetModuleCount() int {
	return qr.moduleCount
}

type QR8BitByte struct {
	data string
}

func (qr *QRCode) ToImageDataURI() string {
	base64Svg := "data:image/svg+xml;base64," + base64.StdEncoding.EncodeToString([]byte(qr.ToSvg()))
	return base64Svg
}

func (qr *QRCode) ToImageMarkdown() string {
	return "![" + qr.qrDataList[0].data + "](" + qr.ToImageDataURI() + ")"
}

func (qr *QRCode) ToSvg() string {
	svg := "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" width=\"200\" height=\"200\">"
	for row := 0; row < qr.moduleCount; row++ {
		for col := 0; col < qr.moduleCount; col++ {
			if qr.IsDark(row, col) {
				svg += "<rect x=\"" + string(row*10) + "\" y=\"" + string(col*10) + "\" width=\"10\" height=\"10\" fill=\"black\" />"
			}
		}
	}
	svg += "</svg>"
	return svg
}
