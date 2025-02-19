package qwerty

import (
	"strings"
)

func mdLink(text, url string) string {
	if !strings.HasPrefix(url, "?") {
		url = "?" + url
	}
	return "[" + text + "](" + url + ")"
}

func appendToWord(path, value string) string {
	// if trails with &q= then add the equal sign
	if strings.HasSuffix(path, "&q") {
		return path + "=" + value
	}

	p := path + value
	if strings.HasPrefix(path, "?q=") {
		return p
	} else {
		return "?q=" + p
	}
}

func removeLastChar(path string) string {
	if strings.HasSuffix(path, "&q") {
		return path[:len(path)-2]
	}
	if len(path) > 0 {
		return path[:len(path)-1]
	}
	return path
}

func NewKeyboardField(path string) string {
	out := ""
	numbers := "1234567890"
	upper := []string{
		"ABCDEFGHIJKL",
		"MNOPQRSTUVW",
		"XYZ_ 🔙",
	}
	lower := []string{
		"abcdefghijkl",
		"mnopqrstuvw",
		"xyz_ 🔙",
	}

	out += KeyboardRow(path, numbers) + "\n\n"
	for _, row := range upper {
		out += KeyboardRow(path, row) + "\n\n"
	}
	for _, row := range lower {
		out += KeyboardRow(path, row) + "\n\n"
	}
	return out

}
func KeyboardRow(path, keys string) string {
	out := ""
	for _, key := range keys {
		keyStr := string(key)
		if key == '🔙' {
			uri := removeLastChar(path)
			out += mdLink("back", uri) + " "
		} else if key == ' ' {
			uri := appendToWord(path, "&q=")
			out += mdLink("space", uri) + " "
		} else {
			uri := appendToWord(path, keyStr)
			out += mdLink(keyStr, uri) + " "
		}
	}
	return out
}

func toText(path string) string {
	if !strings.HasPrefix(path, "?q=") {
		return ""
	}
	p := strings.Replace(path, "?q=", "", 1)
	p = strings.Replace(p, "&q=", " ", -1)
	p = strings.Replace(p, "&q", " ", -1)
	return p
}

func Keyboard(path string) string {
	out := "[Restart](./qwerty)\n\n"
	out += NewKeyboardField(path)
	return out
}

func Render(path string) string {
	out := Keyboard(path) + "\n"
	out += "```" + toText(path) + "```"
	return out
}
