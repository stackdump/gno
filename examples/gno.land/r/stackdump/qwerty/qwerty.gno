package qwerty

import (
	"strings"
)

func mdLink(text, url string) string {
	return "[" + text + "](" + url + ")"
}

func appendToWord(path, fieldName, value string) string {
	if strings.HasSuffix(path, "&"+fieldName) {
		return path + "=" + value
	}

	p := path + value
	if strings.HasPrefix(path, "?") {
		return p
	} else {
		return "?" + fieldName + "=" + p
	}
}

func removeLastChar(path, fieldName string) string {
	if strings.HasSuffix(path, "&"+fieldName) {
		return path[:len(path)-len(fieldName)-1]
	}
	if len(path) > 0 {
		return path[:len(path)-1]
	}
	return path
}

// StringField creates a keyboard for entering text
// path is the current path
// fieldName is the name of the field to use in the query string
func StringField(path, fieldName string) (string, func() string) {
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

	out += keyboardRow(path, fieldName, numbers) + "\n\n"
	for _, row := range upper {
		out += keyboardRow(path, fieldName, row) + "\n\n"
	}
	for _, row := range lower {
		out += keyboardRow(path, fieldName, row) + "\n\n"
	}
	return out, func() string {
		return stringFieldToText(path, fieldName)
	}
}

// keyboardRow creates a row of keys from input string
func keyboardRow(path, fieldName, keys string) string {
	out := ""
	for _, key := range keys {
		keyStr := string(key)
		if key == '🔙' {
			uri := removeLastChar(path, fieldName)
			out += mdLink("back", uri) + " "
		} else if key == ' ' {
			uri := appendToWord(path, fieldName, "&"+fieldName+"=")
			out += mdLink("space", uri) + " "
		} else {
			uri := appendToWord(path, fieldName, keyStr)
			out += mdLink(keyStr, uri) + " "
		}
	}
	return out
}

// stringFieldToText converts a query string to text
func stringFieldToText(path, fieldName string) string {
	if !strings.HasPrefix(path, "?"+fieldName+"=") {
		return "[enter text by clicking on the embedded keyboard]"
	}
	p := strings.Replace(path, "?"+fieldName+"=", "", 1)
	p = strings.Replace(p, "&"+fieldName+"=", " ", -1)
	p = strings.Replace(p, "&"+fieldName, " ", -1)
	return p
}

func Render(path string) string {
	out := "[Restart](./qwerty)\n\n"
	field, getText := StringField(path, "q")
	out += field + "\n\n```" + getText() + "```"
	return out
}
