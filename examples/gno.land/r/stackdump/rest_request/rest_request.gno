// Package rfe - Request For Event Sample Memo Format - first draft see /r/stackdump/rfe for latest
package rest_request

import (
	"gno.land/p/demo/ufmt"
	"strings"
)

func Sprint(v interface{}) string {
	return ufmt.Sprintf("%v", v)
}

var cities = []string{
	"Any City",
	"New York", "Los Angeles", "Chicago", "Houston", "Phoenix",
	"Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose", "Austin", "Virtual",
}

var organizers = []string{
	"Any Organizer",
	"Build The Future", "Foo", "Bar", "Tech Innovators", "Event Masters",
}

var exampleUrls = []string{
	"?city=New+York&city=Los+Angeles&date=2022-01-01&date=2022-01-02&organizer=Build+The+Future",
	"?city=New+York&city=Los+Angeles&date=2022-01-01..2022-01-02&organizer=Foo",
	"?city=New+York&city=Los+Angeles&date=2022-01-01..2022-01-02&date=2022-01-03..2022-01-04&organizer=Tech+Innovators",
	"?city=Chicago&date=2022-02-01&organizer=Event+Masters",
	"?city=Houston&date=2022-03-01&organizer=Bar",
	"?city=Phoenix&date=2022-04-01&organizer=Build+The+Future",
}

func validDate(date string) bool {
	dateLen := len(date)
	if dateLen == 10 {
		return true
	}
	if dateLen == 22 { // support range
		return true
	}
	return false
}

type EventRequest struct {
	Cities     []string
	Organizers []string
	Dates      []string // TODO: support date range and also use a proper data type
	Bid        string   //uint64 // REVIEW: resize to match data type of Photon token
}

func NewEventRequest(url string) *EventRequest {
	er := &EventRequest{}
	er.Cities = []string{}
	er.Organizers = []string{}
	er.Dates = []string{}
	er.Bid = "0"
	er.FromPath(url)
	return er
}

// FromPath parse the query string and populate the EventRequest
func (er *EventRequest) FromPath(path string) {
	// remove leading from path
	if strings.HasPrefix(path, "?") {
		path = path[1:]
	}
	params := strings.Split(path, "&")
	for _, param := range params {
		kv := strings.Split(param, "=")
		if len(kv) != 2 {
			continue
		}
		key, value := kv[0], kv[1]
		switch key {
		case "city":
			er.Cities = append(er.Cities, value)
		case "organizer":
			er.Organizers = append(er.Organizers, value)
		case "date":
			er.Dates = append(er.Dates, value)
		case "bid":
			er.Bid = Sprint(value)
		}
	}
}

func (er *EventRequest) Validate() {
	// make sure the cities are valid
	for _, city := range er.Cities {
		valid := false
		for _, validCity := range cities {
			if city == validCity {
				valid = true
				break
			}
		}
		if !valid {
			panic("invalid city: " + city)
		}
	}

	// make sure the organizers are valid
	for _, organizer := range er.Organizers {
		valid := false
		for _, validOrganizer := range organizers {
			if organizer == validOrganizer {
				valid = true
				break
			}
		}
		if !valid {
			panic("invalid organizer: " + organizer)
		}
	}

	// make sure the dates are valid
	for _, date := range er.Dates {
		if !validDate(date) {
			panic("invalid date: " + date)
		}
	}

}

// use string concat to produce a json payload
func (er *EventRequest) ToJson() (string, error) {
	jsonStr := "{\n"
	jsonStr += "\"Cities\":[\n"
	for i, city := range er.Cities {
		if i > 0 {
			jsonStr += ",\n"
		}
		jsonStr += "\"" + city + "\""
	}
	jsonStr += "\n],\n"
	jsonStr += "\"Organizers\":[\n"
	for i, organizer := range er.Organizers {
		if i > 0 {
			jsonStr += ",\n"
		}
		jsonStr += "\"" + organizer + "\""
	}
	jsonStr += "\n],\n"
	jsonStr += "\"Dates\":[\n"
	for i, date := range er.Dates {
		if i > 0 {
			jsonStr += ",\n"
		}
		jsonStr += "\"" + date + "\""
	}
	jsonStr += "\n],\n"
	jsonStr += "\"Bid\":" + Sprint(er.Bid) + "\n"
	jsonStr += "}"

	return jsonStr, nil
}

const intro = `Request For Event Sample Memo Format

Try the following example URLs:
`

// mdLink returns a markdown link
func mdLink(text, url string) string {
	text = strings.ReplaceAll(text, "+", " ")
	url = strings.ReplaceAll(url, " ", "+")
	if strings.HasPrefix(url, "&") {
		url = "?" + url[1:]
	}
	return "[" + text + "](" + url + ")"
}

func showEvent(er *EventRequest) string {
	out, _ := er.ToJson()
	return "```json\n" + out + "\n```"
}

func Render(path string) string {
	out := mdLink("Restart", "?") + "\n\n"
	// make links for each city
	for _, city := range cities {
		out += " - " + mdLink(city, path+"&city="+city)
	}
	out += "\n"
	// make links for each organizer
	for _, organizer := range organizers {
		out += " - " + mdLink(organizer, path+"&organizer="+organizer)
	}

	out += "\n"
	// make links to compose data select year, month day
	out += " - " + mdLink("Range", path+"&date=2025-00-00..2025-00-00") + "\n"
	out += " - " + mdLink("2025", path+"&date=2025-00-00") + "\n"
	// TODO: detect empty date and compose links for each day of the month

	out += " ### Event Request\n"

	er := NewEventRequest(path)
	er.Validate()
	out += showEvent(er) + "\n"

	return out
}
