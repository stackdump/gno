package blog

import (
	"strings"
	"time"
)

func breadcrumb(parts []string) string {
	return "# " + strings.Join(parts, " / ") + "\n\n"
}

func getTitleKey(title string) string {
	return strings.ReplaceAll(title, " ", "")
}

func getPublishedKey(t time.Time) string {
	return t.Format(time.RFC3339)
}

// escapeXML escapes special XML characters in a string
var xmlReplacer = strings.NewReplacer(
	"&", "&amp;",
	"<", "&lt;",
	">", "&gt;",
	"\"", "&quot;",
	"'", "&apos;",
)

func escapeXML(s string) string {
	return xmlReplacer.Replace(s)
}
