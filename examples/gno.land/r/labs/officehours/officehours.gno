package officehours

import (
	"chain"
	"chain/runtime"
	"net/url"
	"strconv"
	"strings"
	"time"

	"gno.land/p/eve/event"
	eve "gno.land/p/eve/component"
	"gno.land/p/moul/txlink"
)

// ---------- Logograph / Projectable / Editable surface ----------

var (
	_           eve.LogoGraph    = OfficeHoursObj
	_           eve.Editable     = OfficeHoursObj
	_           eve.PageTemplate = OfficeHoursObj
	packagePath                  = runtime.CurrentRealm().PkgPath()
)

func init() {
	eve.AssertProjectionRoundTrip(OfficeHoursObj, OfficeHoursObj)
}

// Cid is derived from the stable JSON-LD composed below.
func (o OfficeHours) Cid() string {
	return o.JsonLD().Cid()
}

// RenderForm (HTML) → form to propose a new session.
func (OfficeHours) RenderForm(path string) string {
	evt := eventFromPath(path)
	cid := evt.Cid()
	return proposalForm(cid, event.ScheduleFromEvent(evt, cid))
}

// Image (markdown) → embeds the full SVG via data URL.
func (o OfficeHours) Image() string {
	return "![OfficeHours](" + o.DataUrl() + ")"
}

func (o OfficeHours) DataUrl() string {
	return "data:image/svg+xml;charset=utf-8," + url.PathEscape(o.SVG())
}

func (OfficeHours) Thumbnail() string {
	return "![OfficeHours](" + OfficeHours{}.ThumbnailDataUrl() + ")"
}

func (OfficeHours) ThumbnailDataUrl() string {
	return "data:image/svg+xml;utf8," + url.PathEscape(OfficeHours{}.ThumbnailSvg("75", "94"))
}

func (OfficeHours) ThumbnailSvg(w, h string) string {
	return `<svg width="` + w + `" height="` + h + `" viewBox="0 0 80 54" xmlns="http://www.w3.org/2000/svg">
  <g transform="translate(11,2) scale(0.7)">
    ` + aibLogoPath + `
  </g>
  <text x="40" y="70" text-anchor="middle" font-size="12" font-weight="bolder" font-family="sans-serif" fill="#222">Office Hours</text>
</svg>`
}

// SVG returns the full SVG representation of the flyer.
func (o OfficeHours) SVG() string {
	var y = 28
	body := o.Flyer().ToSVGFragment(&y)
	body += `<g transform="translate(410, 52) scale(1.8)"> ` + aibLogoPath + `</g>`
	return eve.SvgHeading("600", "200") + body + "</svg>"
}

// Compose builds the stable JSON-LD (and is what we CID over).
func (o OfficeHours) JsonLD() eve.JsonLDMap {

	// build the concrete event for the current (or requested) session.
	// we intentionally don’t read path here to keep the ld stable; path-specific
	// choices (like ?date=) are “views.” if you want date-pinning in the cid,
	// pass an override object that sets it in your own workflow.
	status := "EventScheduled"
	if isCancelled(publishedAt) { // cancelling this date marks the whole series as cancelled
		status = "EventCancelled"
	}

	admin := o.admin
	if admin == "" {
		admin = runtime.CurrentRealm().Address().String()
	}

	selectedDate := o.selectedDate
	if selectedDate == "" {
		selectedDate = OfficeHoursObj.selectedDate
	}

	if len(selectedDate) == 10 {
		selectedDate = selectedDate + "T" + strconv.Itoa(OfficeHoursObj.eventStartHour) + ":00:00"
	}

	return eve.JsonLDMap{
		"@context":    "https://schema.org",
		"@type":       "WebPage",
		"name":        "OfficeHours",
		"description": "Recurring Weekly Event with AllInBits Labs.",
		"@graph": []interface{}{
			map[string]interface{}{
				"@type":     "Event",
				"@id":       "{{CID}}",
				"startDate": selectedDate,
				"status":    status,
			},
		},
		"about": map[string]interface{}{
			"url":       packagePath[8:],
			"banner":    packagePath[8:] + "?embed=banner",
			"thumbnail": packagePath[8:] + "?embed=thumbnail",
			"admin":     admin,
		},
		// REVIEW: any page with a @graph should not use representativeOfPage
		//"representativeOfPage": true,
	}
}

// Flyer builds the eve.Flyer projection (used by SVG/Image).
func (OfficeHours) Flyer(obj ...interface{}) *eve.Flyer {
	// Build from the same concrete event we render elsewhere
	evt := eventFromPath("")
	f := &eve.Flyer{
		Name:        "Office Hours",
		Location:    &eve.Location{Name: "Online"},
		StartDate:   evt.StartDate,
		EndDate:     evt.EndDate,
		Description: "Recurring Weekly Event with AllInBits Labs.",
		Status:      eve.EventStatus(evt.Status),
		Sessions: []*eve.Session{
			{
				Title:       OfficeHoursObj.eventTitle,
				Description: OfficeHoursObj.eventDescription,
				StartTime:   evt.StartDate,
				EndTime:     evt.EndDate,
				Sequence:    OfficeHoursObj.sequence,
			},
		},
		Images: []string{},
	}
	f.SetRenderOpts(OfficeHoursObj.renderOpts)
	return f
}

var aibLogoPath = `<path fill-rule="evenodd" clip-rule="evenodd" d="M24.9998 19.9998 30 30H0L5.00021 19.9998H24.9998zM15 0l4.9998 9.99979H10.0002L15 0zM41.6667.0c2.7614.0 5 2.23858 5 5s-2.2386 5-5 5c-2.7615.0-5-2.23858-5-5s2.2385-5 5-5zm-5 30V20h10V30h-10zM75 20H56.6667V30H75C77.7614 30 80 27.7614 80 25S77.7614 20 75 20zM56.6667.0H68.3333c2.76150000000001.0 5 2.23858 5 5S71.0948 10 68.3333 10H56.6667V0zM77.5939 43.8512C77.9255 44.0839 78.1137 44.4092 78.1583 44.827H79.866C79.8564 44.2753 79.7018 43.7874 79.402 43.3633 79.1022 42.9359 78.6893 42.6027 78.1631 42.3635 77.6401 42.1212 77.0311 42 76.3359 42 75.6503 42 75.0364 42.1212 74.4943 42.3635 73.9522 42.6027 73.5233 42.9391 73.2076 43.3728 72.895 43.8065 72.7388 44.312 72.7388 44.8891 72.7388 45.5907 72.9716 46.1535 73.4372 46.5777 73.9059 46.9986 74.5437 47.3127 75.3505 47.52L76.465 47.807C76.8158 47.8963 77.1219 47.9983 77.3834 48.1131 77.6481 48.2247 77.8538 48.3651 78.0005 48.5341 78.1472 48.6999 78.2221 48.9104 78.2253 49.1655 78.2221 49.4461 78.1376 49.6916 77.9718 49.9021 77.806 50.1094 77.5764 50.272 77.283 50.39 76.9928 50.5048 76.6548 50.5622 76.2689 50.5622 75.899 50.5622 75.5642 50.5064 75.2644 50.3948 74.9678 50.2832 74.7271 50.1142 74.5421 49.8878 74.3572 49.6613 74.2519 49.3775 74.2264 49.0363H72.4805C72.506 49.6869 72.675 50.2385 72.9875 50.6914 73.3032 51.1442 73.7401 51.4886 74.2982 51.7246 74.8594 51.9605 75.5211 52.0785 76.2832 52.0785 77.0677 52.0785 77.7358 51.9573 78.2875 51.715 78.8423 51.4694 79.2665 51.1298 79.5599 50.6961 79.8532 50.2593 79.9999 49.7538 79.9999 49.1798 79.9999 48.7557 79.9202 48.3858 79.7607 48.0701 79.6013 47.7544 79.3845 47.4849 79.1102 47.2617 78.8392 47.0385 78.5314 46.8535 78.187 46.7068 77.8458 46.5601 77.4903 46.4437 77.1203 46.3576L76.2019 46.128C76.001 46.0802 75.8017 46.0212 75.604 45.951 75.4063 45.8809 75.2261 45.7948 75.0635 45.6927 74.9009 45.5875 74.7717 45.46 74.676 45.3101 74.5836 45.1602 74.5373 44.9832 74.5373 44.7791 74.5405 44.5336 74.6123 44.3151 74.7526 44.1238 74.8929 43.9325 75.0954 43.781 75.3601 43.6694 75.6247 43.5578 75.942 43.502 76.312 43.502 76.8381 43.502 77.2654 43.6184 77.5939 43.8512zM62.973 42.1339v1.4877h3.0279v8.3087h1.7603V43.6216H70.789V42.1339H62.973zm-2.03.0V51.9303H59.1684V42.1339H60.943zm-11.1662.0V51.9303h3.9654C54.4916 51.9303 55.1134 51.8139 55.6077 51.5811 56.102 51.3483 56.4719 51.031 56.7174 50.6292 56.963 50.2242 57.0857 49.7682 57.0857 49.2611 57.0857 48.7637 56.9837 48.3396 56.7796 47.9888 56.5755 47.638 56.3124 47.3669 55.9903 47.1756 55.6714 46.9811 55.3382 46.8743 54.9906 46.8551V46.7595C55.3095 46.6829 55.5981 46.557 55.8564 46.3816 56.1147 46.2062 56.3204 45.9782 56.4735 45.6975 56.6265 45.4137 56.7031 45.0725 56.7031 44.6739 56.7031 44.1892 56.5851 43.7555 56.3491 43.3728 56.1163 42.9902 55.7639 42.6888 55.292 42.4688 54.8232 42.2456 54.2348 42.1339 53.5269 42.1339H49.7768zM53.4599 50.4474H51.5514v-2.87h1.9564C53.8745 47.5774 54.1902 47.646 54.4549 47.7831 54.7196 47.917 54.9236 48.102 55.0672 48.338 55.2107 48.5708 55.2824 48.8322 55.2824 49.1224 55.2824 49.5115 55.1389 49.8304 54.8519 50.0791 54.5681 50.3246 54.1041 50.4474 53.4599 50.4474zM53.3069 46.3003H51.5514V43.5977h1.7937C53.8681 43.5977 54.262 43.7204 54.5266 43.966 54.7945 44.2115 54.9284 44.524 54.9284 44.9035 54.9284 45.1905 54.8567 45.4392 54.7132 45.6497 54.5729 45.857 54.3799 46.018 54.1344 46.1328 53.8889 46.2444 53.613 46.3003 53.3069 46.3003zm-9.8827-4.1664V51.9303H41.8457l-4.6159-6.6728H37.1484v6.6728H35.3738V42.1339h1.5881L41.5731 48.8115H41.6592V42.1339h1.765zM32.9133 51.9303V42.1339H31.1386V51.9303h1.7747zm-13.8228.0V42.1339h1.7747v8.3087h4.3145v1.4877H19.0905zM10.9222 42.1339V51.9303h6.0892V50.4426H12.6969V42.1339H10.9222zM1.89421 51.9303H0L3.4488 42.1339H5.63958L9.09316 51.9303H7.19895L6.38732 49.5147H2.70435L1.89421 51.9303zM4.58245 44.143l1.32593 3.9462H3.18242l1.3235-3.9462h.07653z" fill="black" />`

// ---------- Constants & Types ----------

var publishedAt = time.Date(2025, 9, 1, 0, 0, 0, 0, time.UTC)

type OfficeHours struct {
	eventTitle       string
	eventDescription string
	eventDayOfWeek   time.Weekday
	eventStartHour   int
	eventDuration    time.Duration
	cancelledDates   map[string]bool
	renderOpts       map[string]interface{}
	sequence         int
	admin            string
	selectedDate     string
}

// ---------- State ----------

var OfficeHoursObj = &OfficeHours{
	eventTitle:       "",
	eventDescription: "",
	eventDayOfWeek:   time.Sunday,
	eventStartHour:   1,
	eventDuration:    time.Hour,
	cancelledDates:   map[string]bool{},
	renderOpts: map[string]any{
		"dev": map[string]any{
			"CalendarFile":  "http://127.0.0.1:8080",
			"SessionsTitle": "Weekly Session",
		},
		"labsnet1": map[string]any{
			"CalendarFile":  "https://gnocal.aiblabs.net",
			"SessionsTitle": "Weekly Session",
		},
	},
	sequence:     -1,
	admin:        runtime.PreviousRealm().Address().String(),
	selectedDate: "2025-09-01",
}

// ---------- Access Control ----------

func assertAccess() {
	if OfficeHoursObj.admin != runtime.PreviousRealm().Address().String() {
		panic("access denied: only admin can update office hours")
	}
}

// ---------- OfficeHours Methods ----------

func (o *OfficeHours) String() string {
	return `{
    "eventTitle": "` + o.eventTitle + `",
    "eventDescription": "` + o.eventDescription + `",
    "eventDayOfWeek": "` + o.eventDayOfWeek.String() + `",
    "eventStartHour": ` + strconv.Itoa(o.eventStartHour) + `,
    "eventDurationMinutes": ` + strconv.Itoa(int(o.eventDuration.Minutes())) + `,
    "cancelledDates": ` + formatCancelledDates(o.cancelledDates) + `,
    "admin": "` + o.admin + `",
    "sequence": ` + strconv.Itoa(o.sequence) + `
}`
}

func formatCancelledDates(dates map[string]bool) string {
	var list []string
	for d := range dates {
		list = append(list, `"`+d+`"`)
	}
	return "[" + strings.Join(list, ", ") + "]"
}

// ---------- Update Logic ----------

var validKeys = map[string]bool{
	"admin":                true,
	"eventTitle":           true,
	"eventDescription":     true,
	"eventDayOfWeek":       true,
	"eventStartHour":       true,
	"eventDurationMinutes": true,
	"cancelledDate":        true,
}

// Update modifies the office hours configuration.
func Update(cur realm, parts ...string) {
	assertAccess()
	OfficeHoursObj.Update(parts...)
}

func (o *OfficeHours) Update(parts ...string) {
	if len(parts) < 2 || len(parts)%2 != 0 {
		panic("Update requires key-value pairs (even number of arguments)")
	}
	o.sequence++
	for i := 0; i < len(parts); i += 2 {
		key := strings.TrimSpace(parts[i])
		value := strings.TrimSpace(parts[i+1])
		if !validKeys[key] {
			panic("Invalid key: " + key + ". Valid keys: " + validKeyList())
		}
		o.applyUpdate(key, value)
	}
}

func validKeyList() string {
	keys := make([]string, 0, len(validKeys))
	for k := range validKeys {
		keys = append(keys, k)
	}
	return strings.Join(keys, ", ")
}

func (o *OfficeHours) applyUpdate(key, value string) {
	switch key {
	case "admin":
		o.admin = value
	case "eventTitle":
		o.eventTitle = value
	case "eventDescription":
		o.eventDescription = value
	case "eventDayOfWeek":
		o.eventDayOfWeek = parseWeekday(value)
	case "eventStartHour":
		o.eventStartHour = parseHour(value)
	case "eventDurationMinutes":
		o.eventDuration = parseDurationMinutes(value)
	case "cancelledDate":
		o.cancelledDates[parseCancelledDate(value)] = true
	}
}
func parseWeekday(value string) time.Weekday {
	switch strings.ToLower(value) {
	case "sunday":
		return time.Sunday
	case "monday":
		return time.Monday
	case "tuesday":
		return time.Tuesday
	case "wednesday":
		return time.Wednesday
	case "thursday":
		return time.Thursday
	case "friday":
		return time.Friday
	case "saturday":
		return time.Saturday
	default:
		panic("Invalid day of week: " + value)
	}
}

func parseHour(value string) int {
	h, err := strconv.Atoi(value)
	if err != nil || h < 0 || h > 23 {
		panic("Invalid start hour: " + value)
	}
	return h
}

func parseDurationMinutes(value string) time.Duration {
	m, err := strconv.Atoi(value)
	if err != nil || m <= 0 {
		panic("Invalid duration minutes: " + value)
	}
	return time.Duration(m) * time.Minute
}

func parseCancelledDate(value string) string {
	if _, err := time.Parse("2006-01-02", value); err != nil {
		panic("Invalid date format for cancelledDate. Use YYYY-MM-DD.")
	}
	return value
}

// ---------- Time Helpers ----------

func nextEventDay() time.Time {
	now := time.Now().UTC()
	daysUntil := (int(OfficeHoursObj.eventDayOfWeek) - int(now.Weekday()) + 7) % 7
	if daysUntil == 0 {
		daysUntil = 7
	}
	next := now.AddDate(0, 0, daysUntil)
	return time.Date(next.Year(), next.Month(), next.Day(), OfficeHoursObj.eventStartHour, 0, 0, 0, time.UTC)
}

func isCancelled(date time.Time) bool {
	return OfficeHoursObj.cancelledDates[date.Format("2006-01-02")]
}

// ---------- UI Helpers ----------

func proposalForm(topicCID string, s event.Schedule) string {
	if time.Now().After(event.ParseTimeSafe(s.EndDate).Add(48 * time.Hour)) {
		return ""
	}
	var sb strings.Builder
	sb.WriteString(`### Propose Topic
<gno-columns>
<gno-form>
  <gno-textarea name="description" label="Description" rows="3" required placeholder="Describe your topic proposal, or leave a comment..."/>
  <gno-input name="topic" type="radio" value="` + topicCID + `" checked="true" />
  <gno-input name="date" type="radio" value="` + s.StartDate[:10] + `" checked="true" />
</gno-form>
|||
</gno-columns>
`)
	nextDate := event.ParseTimeSafe(s.StartDate).AddDate(0, 0, 7).Format("2006-01-02")
	sb.WriteString("\n[Next date →](" + "?date=" + nextDate + ")\n")
	return sb.String()
}

// ---------- Event Composition ----------

func eventFromPath(path string) *event.Event {
	q := eve.ParseQuery(path)
	var start time.Time

	if dateStr := q.Get("date"); dateStr != "" {
		parsed, err := time.Parse("2006-01-02", dateStr)
		if err == nil {
			start = time.Date(parsed.Year(), parsed.Month(), parsed.Day(), OfficeHoursObj.eventStartHour, 0, 0, 0, time.UTC)
		} else {
			start = nextEventDay()
		}
	} else {
		start = nextEventDay()
	}

	end := start.Add(OfficeHoursObj.eventDuration)
	status := "EventPlanned"
	if isCancelled(start) {
		status = "EventCancelled"
	}

	session := &eve.Session{
		Title:       OfficeHoursObj.eventTitle,
		StartTime:   start,
		EndTime:     end,
		Description: OfficeHoursObj.eventDescription,
		Sequence:    OfficeHoursObj.sequence,
	}

	evt := &event.Event{
		Name:      OfficeHoursObj.eventTitle,
		Status:    eve.Status(status),
		StartDate: start,
		EndDate:   end,
		Location:  &eve.Location{Name: "Online"},
		Sessions:  []*eve.Session{session},
	}
	evt.SetRenderOpts(OfficeHoursObj.renderOpts)
	return evt
}

// ---------- Renderers ----------

func renderFlyer(path string) string {
	q := eve.ParseQuery(path)
	evt := eventFromPath(path)
	var body strings.Builder

	body.WriteString(event.Schedule{Title: evt.Name}.Thumbnail())

	if topicCID := q.Get("cal"); topicCID != "" {
		s := event.ScheduleFromEvent(evt, topicCID)
		body.WriteString(proposalForm(topicCID, s))
	}

	return evt.RenderPage("", eve.Content{
		Published: true,
		Markdown:  body.String(),
	})
}

// RenderCalendar composes an ICS calendar file (recurring) for the event.
// Objects are language, not files -  we keep a tiny semantic core and project canonical views on demand.
func RenderCalendar(path string) string {
	opts := map[string]any{
		"Location": "Online",
		"Freq":     "WEEKLY",
		"ByDay":    strings.ToUpper(OfficeHoursObj.eventDayOfWeek.String()[:2]),
		"Interval": 1,
		"DtStart":  publishedAt.Format("20060102T150405Z"),
		"Until":    "20261231T000000Z", // REVIEW: make configurable?
		"ExDates":  []string{},
	}

	for date, _ := range OfficeHoursObj.cancelledDates {
		if t, err := time.Parse("2006-01-02", date); err == nil {
			exdate := time.Date(t.Year(), t.Month(), t.Day(), OfficeHoursObj.eventStartHour, 0, 0, 0, time.UTC)
			opts["ExDates"] = append(opts["ExDates"].([]string), exdate.Format("20060102T150405Z"))
		}
	}

	return eve.IcsRecurringCalendarFile(path, opts)
}

// Render is the main entry point to render the office hours page.
// | ?embed=banner | to render a markdown banner with a link to the flyer image. (useful from other realms)
// | ?embed=thumbnail | to render a markdown thumbnail with a link to the flyer image. (useful from other realms)
// | ?format=json | to view the current configuration in JSON.
// | ?render=calendar | to view the ICS calendar file.
// | ?topic=CID&date=YYYY-MM-DD&description={str} | to view a topic proposal confirmation.
// otherwise, it renders the flyer with a proposal form.
func Render(path string) string {
	return OfficeHoursObj.RenderPage(path)
}

func (OfficeHours) Render(path string) string {
	var sb strings.Builder
	sb.WriteString("Join us every Week for an hour of live Q&A, project updates, and community discussions.\n\n")
	sb.WriteString("Propose a topic from the office hours realm.\n\n")
	sb.WriteString(OfficeHoursObj.RenderPage("?embed=banner"))
	return sb.String()
}

func (OfficeHours) RenderPage(path string) string {
	q := eve.ParseQuery(path)
	var sb strings.Builder
	link := packagePath[9:]

	switch {
	case q.Get("embed") == "thumbnail":
		return "[" + OfficeHoursObj.Thumbnail() + "](/" + link + ")\n\n"
	case q.Get("embed") == "banner":
		return "[![Event Flyer](" + OfficeHoursObj.DataUrl() + ")](/" + link + ")\n\n"
	case q.Get("format") == "json":
		return OfficeHoursObj.JsonLD().StringWithCID()
	case q.Get("render") == "calendar":
		return "```\n" + RenderCalendar(path) + "\n```"
	case q.Get("topic") != "":
		sb.WriteString(renderTopicConfirm(q))
	default:
		evt := eventFromPath(path)
		cid := evt.Cid()
		sb.WriteString(proposalForm(cid, event.ScheduleFromEvent(evt, cid)))
	}
	return renderFlyer(path) + sb.String()
}

func renderTopicConfirm(q eve.Query) string {
	var sb strings.Builder
	sb.WriteString("## Confirm\n")
	sb.WriteString("Submit your topic proposal by posting a transaction with the following parameters:\n\n---\n\n")
	sb.WriteString("Func: PostTopic\n\n")
	sb.WriteString("Topic: " + q.Get("topic") + "\n\n")

	if date := q.Get("date"); date != "" {
		sb.WriteString("Date: " + date + "\n\n")
		if desc := q.Get("description"); desc != "" {
			sb.WriteString("Description: " + desc + "\n\n---\n\n")
			sb.WriteString(showCLI(q.Get("topic"), date, desc))
		} else {
			sb.WriteString("> [!CAUTION]\n> Missing description parameter\n\n")
		}
	} else {
		sb.WriteString("> [!CAUTION]\n> Missing date parameter\n\n")
	}
	return sb.String()
}

// ---------- CLI Helpers ----------

func showCLI(topic, date, description string) string {
	var sb strings.Builder
	link := txlink.NewLink("PostTopic").AddArgs(
		"CID", topic,
		"date", date,
		"description", description,
	).URL()

	sb.WriteString("#### Txlink Button (Adena Wallet) \n\n")
	sb.WriteString("Click the button below to open Adena Wallet and prefill a transaction:\n\n")
	sb.WriteString("EXPERIMENTAL: Adena support is still being tested (looking for feedback here).\n\n")
	sb.WriteString(eve.Button("Post Topic  ", link))
	sb.WriteString("\n\n[" + link + "](" + link + ")\n\n")
	return cliCommand(topic, date, description) + "\n\n" + sb.String()
}

func cliCommand(topic, date, description string) string {
	var sb strings.Builder
	sb.WriteString("#### CLI Command (Gnokey) \n\n")
	sb.WriteString("\n```\n\n")
	sb.WriteString("gnokey maketx call ")
	sb.WriteString(" -pkgpath \"" + runtime.CurrentRealm().PkgPath() + "\"")
	sb.WriteString(" -func \"PostTopic\"")
	sb.WriteString(" -args \"" + topic + "\"")
	sb.WriteString(" -args \"" + date + "\"")
	sb.WriteString(" -args \"" + description + "\"")
	sb.WriteString(" -gas-fee 1000000ugnot ")
	sb.WriteString(" -gas-wanted 5000000 ")
	sb.WriteString(" -send \"\" ")
	sb.WriteString(" -broadcast ")
	sb.WriteString(" -chainid \"" + runtime.ChainID() + "\" ")
	sb.WriteString(" -remote \"tcp://0.0.0.0:26657\" ")
	sb.WriteString(" ADDRESS")
	sb.WriteString("\n```")
	return sb.String()
}

// ---------- Event Posting ----------

// PostTopic is the function to be called in a transaction to propose a topic for the next office hours.
// This function emits an event that is indexed by the realm owner to build a list of proposed topics and review comments.
func PostTopic(cur realm, CID, date, description string) {
	eve.MustCIDv1("topic", CID)
	chain.Emit("officehours-topic",
		"topic", CID,
		"date", date,
		"description", description,
	)
}
