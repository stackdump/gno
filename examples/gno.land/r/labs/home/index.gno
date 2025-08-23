package home

var index = `

## Labs Index
- [grc000](/r/labs/grc000) - base grammar for fungible tokens (GRC-000)
- [bsip072](/r/labs/bsip072) - grammar for BSIP-072 tank & tap
`

func Render(_ string) string {
	return index
}
