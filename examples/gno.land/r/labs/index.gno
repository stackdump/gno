package labs

import (
	"strings"
)

func Render(path string) string {
	var sb strings.Builder
	sb.WriteString("## AIB Labs \n")
	sb.WriteString("Continue to [/r/labs/home](/r/labs/home)->\n")
	return sb.String()
}
