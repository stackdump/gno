package rfe

import (
	"gno.land/p/demo/ufmt"
	"strings"
)

func sprint(v interface{}) string {
	return ufmt.Sprintf("%v", v)
}

func mdLink(text, url string) string {
	if !strings.HasPrefix(url, "?") {
		url = "?" + url
	}
	return "[" + text + "](" + url + ")"
}

func addQueryVar(path, key, value string) string {
	if strings.HasPrefix(path, "?") {
		return path + "&" + key + "=" + value
	} else {
		return path + "?" + key + "=" + value
	}
}

// replaceQueryVar replaces the value of a query variable at a specific index.
func replaceQueryVar(path, old, new string) string {
	return strings.Replace(path, old, new, 1)
}

// map of name -> number
var months = map[int]string{
	1:  "January",
	2:  "February",
	3:  "March",
	4:  "April",
	5:  "May",
	6:  "June",
	7:  "July",
	8:  "August",
	9:  "September",
	10: "October",
	11: "November",
	12: "December",
}

func lpad(i, length int) string {
	s := sprint(i)
	for len(s) < length {
		s = "0" + s
	}
	return s
}
func removeTrailing(s, tail string) string {
	if strings.HasSuffix(s, tail) {
		return s[:len(s)-len(tail)]
	}
	return s
}

// REVIEW: select modest year range
const startDate = 2025
const endDate = 2028

func NewDateField(path, value string) string {
	date := strings.Split(value, "=")[1]
	out := ""
	// REVIEW: no format check
	y, m, d := date[:4], date[5:7], date[8:]
	out += "|" + y + "-" + m + "-" + d + "|\n\n"
	flag := false
	if y == "0000" {
		flag = true
		yearStr := ""
		for i := startDate; i <= endDate; i++ {
			uri := replaceQueryVar(path, value, "date="+sprint(i)+"-"+m+"-"+d)
			yearStr += mdLink(sprint(i), uri) + "-"
		}
		//removeTrailing(out, "-")
		out += removeTrailing(yearStr, "-") + "\n\n"
	}
	if m == "00" {
		flag = true
		monthStr := ""
		for i := 1; i <= 12; i++ {
			uri := replaceQueryVar(path, value, "date="+y+"-"+lpad(i, 2)+"-"+d)
			monthStr += mdLink(months[i], uri) + "-"
		}
		out += removeTrailing(monthStr, "-") + "\n\n"
		//removeTrailing(out, "-")
	}
	if d == "00" {
		flag = true
		dayStr := ""
		for i := 1; i <= 31; i++ {
			uri := replaceQueryVar(path, value, "date="+y+"-"+m+"-"+sprint(i))
			dayStr += mdLink(sprint(i), uri) + "-"
		}
		out += removeTrailing(dayStr, "-") + "\n\n"
	}
	if flag {
		return out + ","
	}

	// date is selected
	return date + ","
}

func DatePicker(path string) string {
	// build array of date= values from path, exclude other query vars
	var dates []string
	if strings.HasPrefix(path, "?") {
		dates = strings.Split(path[1:], "&")
	}
	out := "[Add Date:](" + addQueryVar(path, "date", "0000-00-00") + ")\n"
	for _, date := range dates {
		if strings.HasPrefix(date, "date=") {
			out += NewDateField(path, date)
		}
	}
	return removeTrailing(out, ",")
}

func Render(path string) string {
	out := mdLink("Restart", "?") + "\n\n"
	out += "\n"

	// Use DatePicker to handle date selection
	out += DatePicker(path) + "\n"
	return out
}
