# iCalendar Kit

A comprehensive Swift 6 library for parsing and creating iCalendar (RFC 5545) events with full support for structured concurrency, Sendable conformance, and modern Swift features.

```swift
let calendar = ICalendar.calendar {
    CalendarName("My Calendar")
    createEvent(summary: "Meeting", startDate: Date(), endDate: Date().addingTimeInterval(3600))
}
```

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fthoven87%2Ficalendar-kit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/thoven87/icalendar-kit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fthoven87%2Ficalendar-kit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/thoven87/icalendar-kit)
[![CI](https://github.com/thoven87/icalendar-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/thoven87/icalendar-kit/actions/workflows/ci.yml)

## Features

- **RFC Compliant**: Full support for multiple iCalendar specifications (see [RFC Compliance](#rfc-compliance) below)
- **Swift 6 Ready**: Complete Sendable conformance and structured concurrency support
- **Type Safe**: Uses structs instead of classes with comprehensive type operations
- **Comprehensive**: Support for events, todos, journals, alarms, time zones, and recurrence rules
- **Enhanced Properties**: RFC 7986 extensions including COLOR, IMAGE, CONFERENCE, GEO, and ATTACH properties
- **Binary Attachments**: Base64-encoded binary data support for ATTACH and IMAGE properties
- **Timezone Integration**: Foundation TimeZone integration with TZURL generation (RFC 7808)
- **Builder Pattern**: Fluent API for easy calendar and event creation
- **Extensible**: Support for custom properties and X-WR extensions

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 6.0+
- Xcode 16.0+
- Linux

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/thoven87/icalendar-kit.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select the version and target

## Quick Start

### Creating a Simple Event

```swift
import ICalendar

// Create a simple event using EventBuilder
let startTime = Date()
let timeZone = TimeZone.current

let teamMeeting = EventBuilder(summary: "Team Meeting")
    .starts(at: startTime, timeZone: timeZone)
    .duration(3600) // 1 hour in seconds
    .location("Conference Room A")
    .description("Weekly team sync meeting")
    .categories("Work", "Meeting")
    .confirmed()
    .addAlarm(action: .display, minutesBefore: 15, description: "Meeting starts in 15 minutes")
    .buildEvent()

// Create calendar and add the event
var calendar = ICalendar(productId: "-//My App//Team Calendar//EN")
calendar.name = "My Team Calendar"
calendar.calendarDescription = "Team events and meetings"
calendar.addEvent(teamMeeting)

// Serialize to iCalendar format
let icsString = try ICalendarSerializer().serialize(calendar)
print(icsString)
```

### Parsing iCalendar Content

```swift
let icalContent = """
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//My App//EN
BEGIN:VEVENT
UID:event-123
DTSTAMP:20240101T120000Z
DTSTART:20240101T140000Z
DTEND:20240101T150000Z
SUMMARY:Important Meeting
LOCATION:Room 101
END:VEVENT
END:VCALENDAR
"""

// Direct parsing functions (no client needed in v2.0)
let calendar = try ICalendarKit.parseCalendar(from: icalContent)
print("Found \(calendar.events.count) events")
```

### Using EventBuilder for Complex Events

```swift
// Create events using EventBuilder
let startTime = Date()
let timeZone = TimeZone(identifier: "America/New_York")!

// Simple meeting
let meeting = EventBuilder(summary: "Daily Standup")
    .starts(at: startTime, timeZone: timeZone)
    .duration(1800) // 30 minutes in seconds
    .location("Virtual - Zoom")
    .description("Daily team standup meeting")
    .categories("Work", "Meeting")
    .confirmed()
    .addAlarm(action: .display, minutesBefore: 15, description: "Meeting in 15 minutes")
    .buildEvent()

// Project planning session
let projectPlanning = EventBuilder(summary: "Project Planning")
    .starts(at: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, timeZone: timeZone)
    .duration(7200) // 2 hours in seconds
    .location("Conference Room B")
    .description("Weekly project planning session")
    .organizer(email: "manager@company.com", name: "Project Manager")
    .attendee(email: "alice@company.com", name: "Alice", required: true)
    .attendee(email: "bob@company.com", name: "Bob", required: false)
    .highPriority()
    .confirmed()
    .buildEvent()

// Create calendar with the events
var calendar = ICalendar(productId: "-//My Company//Project Calendar//EN")
calendar.name = "Project Calendar"
calendar.addEvent(meeting)
calendar.addEvent(projectPlanning)
```

## Advanced Usage

### Creating Recurring Events

```swift
let startTime = Date()
let timeZone = TimeZone(identifier: "America/New_York")!

// Daily standup for 10 occurrences
let dailyStandup = EventBuilder(summary: "Daily Standup")
    .starts(at: startTime, timeZone: timeZone)
    .duration(1800) // 30 minutes
    .location("Team Room")
    .description("Daily team standup meeting")
    .repeats(every: 1, count: 10) // Daily for 10 days
    .categories("Work", "Standup")
    .confirmed()
    .addAlarm(action: .display, minutesBefore: 5, description: "Standup starting soon")
    .buildEvent()

// Weekly team meeting on weekdays (Monday, Wednesday, Friday)
let weeklyMeeting = EventBuilder(summary: "Team Meeting")
    .starts(at: startTime, timeZone: timeZone)
    .duration(3600) // 1 hour
    .location("Conference Room A")
    .description("Weekly team sync meeting")
    .repeatsWeekly(every: 1, on: [.monday, .wednesday, .friday], count: 8)
    .organizer(email: "lead@company.com", name: "Team Lead")
    .categories("Work", "Team Meeting")
    .confirmed()
    .addAlarm(action: .display, minutesBefore: 15, description: "Team meeting reminder")
    .buildEvent()

// Monthly all-hands meeting
let monthlyAllHands = EventBuilder(summary: "All Hands Meeting")
    .starts(at: startTime, timeZone: timeZone)
    .duration(7200) // 2 hours
    .location("Main Auditorium")
    .description("Monthly company-wide meeting")
    .repeatsMonthly(every: 1, count: 12) // Monthly for 12 months
    .organizer(email: "ceo@company.com", name: "CEO")
    .categories("Company", "All Hands")
    .highPriority()
    .confirmed()
    .addAlarm(action: .display, minutesBefore: 30, description: "All hands meeting starting soon")
    .buildEvent()

// Create calendar and add events
var calendar = ICalendar(productId: "-//My Company//Recurring Events//EN")
calendar.name = "Recurring Events Calendar"
calendar.addEvent(dailyStandup)
calendar.addEvent(weeklyMeeting)
calendar.addEvent(monthlyAllHands)
```

### Adding Attendees and Organizer

```swift
// Create meeting with attendees and organizer
let startTime = Date()
let timeZone = TimeZone(identifier: "America/New_York")!

let projectKickoff = EventBuilder(summary: "Project Kickoff")
    .starts(at: startTime, timeZone: timeZone)
    .duration(7200) // 2 hours
    .location("Conference Room A")
    .description("Project kickoff meeting to discuss goals and timeline")
    .organizer(email: "organizer@company.com", name: "Meeting Organizer")
    .attendee(email: "john@company.com", name: "John Doe", required: true)
    .attendee(email: "jane@company.com", name: "Jane Smith", required: false)
    .attendee(email: "mike@company.com", name: "Mike Johnson", required: true)
    .categories("Project", "Kickoff")
    .highPriority()
    .confirmed()
    .addAlarm(action: .display, minutesBefore: 15, description: "Meeting starts in 15 minutes")
    .addAlarm(action: .display, minutesBefore: 60, description: "Project kickoff in 1 hour")
    .buildEvent()

// Create calendar and add the event
var calendar = ICalendar(productId: "-//My Company//Meeting Planner//EN")
calendar.name = "Team Meetings"
calendar.addEvent(projectKickoff)

// All-day event example
let teamOuting = EventBuilder(summary: "Team Building Outing")
    .allDay(on: Calendar.current.date(byAdding: .day, value: 7, to: Date())!, timeZone: timeZone)
    .location("Adventure Park")
    .description("Annual team building activity")
    .organizer(email: "hr@company.com", name: "HR Department")
    .attendee(email: "team1@company.com", name: "Team Member 1")
    .attendee(email: "team2@company.com", name: "Team Member 2")
    .categories("Team Building", "Fun")
    .confirmed()
    .buildEvent()

calendar.addEvent(teamOuting)
```

### Using the Builder Pattern with Pre-configured Templates

```swift
// Create healthcare calendar with EventBuilder
let startTime = Date()
let timeZone = TimeZone(identifier: "America/New_York")!

// Healthcare event
let consultation = EventBuilder(summary: "Patient Consultation - John Doe")
    .starts(at: startTime, timeZone: timeZone)
    .duration(3600) // 1 hour
    .location("Room 205 - Cardiology")
    .description("Routine cardiology consultation")
    .categories("Healthcare", "Consultation")
    .confirmed()
    .privateEvent() // HIPAA compliant
    .addAlarm(action: .display, minutesBefore: 15, description: "Patient consultation starting")
    .buildEvent()

var healthcareCalendar = ICalendar(productId: "-//City Hospital//Healthcare App//EN")
healthcareCalendar.name = "Cardiology Schedule"
healthcareCalendar.calendarDescription = "City Hospital - Cardiology Department"
healthcareCalendar.addEvent(consultation)

// Corporate team calendar
let sprintPlanning = EventBuilder(summary: "Sprint Planning")
    .starts(at: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, timeZone: timeZone)
    .duration(7200) // 2 hours
    .location("Engineering Conference Room")
    .description("Planning for next development sprint")
    .organizer(email: "scrum-master@acme.com", name: "Scrum Master")
    .attendee(email: "dev1@acme.com", name: "Developer 1", required: true)
    .attendee(email: "dev2@acme.com", name: "Developer 2", required: true)
    .attendee(email: "designer@acme.com", name: "UX Designer", required: false)
    .categories("Engineering", "Planning")
    .highPriority()
    .confirmed()
    .addAlarm(action: .display, minutesBefore: 30, description: "Sprint planning starting soon")
    .buildEvent()

var corporateCalendar = ICalendar(productId: "-//Acme Corp//Corporate//EN")
corporateCalendar.name = "Engineering Team"
corporateCalendar.calendarDescription = "Acme Corp - Engineering Team Events"
corporateCalendar.addEvent(sprintPlanning)
```

### Working with Time Zones

```swift
// Multi-timezone calendar with EventBuilder
let pstTimeZone = TimeZone(identifier: "America/Los_Angeles")!
let estTimeZone = TimeZone(identifier: "America/New_York")!

// West Coast event (9 AM PST)
let westCoastStandup = EventBuilder(summary: "West Coast Team Standup")
    .starts(at: Date(), timeZone: pstTimeZone)
    .duration(3600) // 1 hour
    .location("San Francisco Office")
    .description("Daily standup for west coast team")
    .categories("Work", "Standup")
    .repeats(every: 1, count: 30) // Daily for 30 days
    .confirmed()
    .addAlarm(action: .display, minutesBefore: 5, description: "Standup starting")
    .buildEvent()

// East Coast event (2 PM EST - same time as west coast standup)
let eastCoastCall = EventBuilder(summary: "East Coast Client Call")
    .starts(at: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, timeZone: estTimeZone)
    .duration(3600) // 1 hour
    .location("New York Office")
    .description("Important client call")
    .organizer(email: "sales@company.com", name: "Sales Team")
    .categories("Sales", "Client")
    .highPriority()
    .confirmed()
    .addAlarm(action: .display, minutesBefore: 15, description: "Client call starting")
    .buildEvent()

var multiTimeZoneCalendar = ICalendar(productId: "-//Multi-TZ Company//EN")
multiTimeZoneCalendar.name = "Multi-Timezone Events"
multiTimeZoneCalendar.addEvent(westCoastStandup)
multiTimeZoneCalendar.addEvent(eastCoastCall)
```

### Advanced Recurring Events

```swift
// Daily stand up meetings
let startTime = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 9))!
let timeZone = TimeZone(identifier: "America/New_York")!

// Weekly stand up on weekdays
let weeklyStandUp = EventBuilder(summary: "Team Stand Up")
    .starts(at: startTime, timeZone: timeZone)
    .duration(1800) // 30 minutes
    .location("Conference Room A")
    .description("Daily team stand up meeting")
    .repeatsWeekly(every: 1, on: [.monday, .tuesday, .wednesday, .thursday, .friday])
    .categories("Work", "Stand Up")
    .confirmed()
    .addAlarm(action: .display, minutesBefore: 15, description: "Stand up starting soon")
    .buildEvent()

// Daily recurring pattern
let dailyStandUp = EventBuilder(summary: "Daily Stand Up")
    .starts(at: startTime, timeZone: timeZone)
    .duration(900) // 15 minutes
    .description("Quick daily sync")
    .repeats(every: 1, count: 30) // Daily for 30 days
    .categories("Daily", "Stand Up")
    .confirmed()
    .buildEvent()

// Monthly team sync
let monthlySync = EventBuilder(summary: "Monthly Team Sync")
    .starts(at: startTime, timeZone: timeZone)
    .duration(3600) // 1 hour
    .repeatsMonthly(every: 1, count: 12)
    .organizer(email: "manager@company.com", name: "Team Manager")
    .categories("Team", "Sync")
    .confirmed()
    .addAlarm(action: .display, minutesBefore: 30, description: "Monthly sync starting")
    .buildEvent()

var calendar = ICalendar(productId: "-//My Company//Team Events//EN")
calendar.name = "Team Calendar"
calendar.addEvent(weeklyStandUp)
calendar.addEvent(dailyStandUp)
calendar.addEvent(monthlySync)
```

### Creating To-Do Items

```swift
// Create todo items using the direct function API
let todoCalendar = ICalendar.calendar(productId: "-//Task Manager//EN") {
    CalendarName("Project Tasks")
    CalendarMethod("PUBLISH")

    ICalendarFactory.createTodo(
        summary: "Complete project documentation",
        dueDate: Date().addingTimeInterval(604800), // 1 week
        priority: 1,
        description: "Write comprehensive documentation for the new feature"
    )

    ICalendarFactory.createTodo(
        summary: "Code review for PR #123",
        startDate: Date(),
        dueDate: Date().addingTimeInterval(172800), // 2 days
        priority: 3,
        description: "Review the authentication module changes"
    )
}

### Working with Alarms

```swift
// Create alarms using direct functions in v2.0
let calendarWithAlarms = ICalendar.calendar(productId: "-//Alarm Example//EN") {
    CalendarName("Events with Alarms")

    EventBuilder(summary: "Important Meeting")
        .startDate(Date())
        .endDate(Date().addingTimeInterval(3600))
        .location("Conference Room")
        .addAlarm(ICalendarFactory.createDisplayAlarm(
            description: "Meeting reminder",
            triggerMinutesBefore: 15
        ))
        .addAlarm(ICalendarFactory.createAudioAlarm(
            triggerMinutesBefore: 5,
            audioFile: "reminder.wav"
        ))
        .addAlarm(ICalendarFactory.createEmailAlarm(
            summary: "Meeting Tomorrow",
            description: "Don't forget about the important meeting tomorrow",
            attendees: [ICalendarFactory.createAttendee(email: "organizer@company.com")],
            triggerMinutesBefore: 1440 // 24 hours
        ))
}
```

## Configuration

### Parsing and Serialization Options

Version 2.0 provides direct control over parsing and serialization behavior:

```swift
// Parse with validation (default)
let calendar = try ICalendarKit.parseCalendar(from: icsContent, validateOnParse: true)

// Parse without validation for performance
let fastCalendar = try ICalendarKit.parseCalendar(from: icsContent, validateOnParse: false)

// Serialize with validation (default)
let validatedICS = try ICalendarKit.serializeCalendar(calendar, validateBeforeSerializing: true)

// Serialize without validation for performance
let fastICS = try ICalendarKit.serializeCalendar(calendar, validateBeforeSerializing: false)
```

### Working with Multiple Calendars

```swift
// Parse and work with multiple calendars using v2.0 API
let icsFiles = ["calendar1.ics", "calendar2.ics", "calendar3.ics"]
var allCalendars: [ICalendar] = []

for filename in icsFiles {
    let url = URL(fileURLWithPath: filename)
    let calendar = try ICalendarKit.parseCalendar(from: url, validateOnParse: false) // Skip validation for performance
    allCalendars.append(calendar)
}

// Serialize multiple calendars together
let combinedICS = try ICalendarKit.serializeCalendars(allCalendars, validateBeforeSerializing: true)

// Create a merged calendar from multiple sources
let mergedCalendar = ICalendar.calendar(productId: "-//Merged Calendar//EN") {
    CalendarName("Combined Events")
    CalendarDescription("Events from multiple sources")

    for calendar in allCalendars {
        for event in calendar.events {
            event // Add each event to the new calendar
        }
    }
}
```

## Structured Concurrency Support

The library is built with Swift 6 structured concurrency in mind, with full Sendable conformance:

```swift
// Concurrent parsing of multiple calendars using v2.0 API
await withTaskGroup(of: ICalendar.self) { group in
    let contents = [content1, content2, content3]
    var calendars: [ICalendar] = []

    for content in contents {
        group.addTask {
            return try ICalendarKit.parseCalendar(from: content, validateOnParse: true)
        }
    }

    for await calendar in group {
        calendars.append(calendar)
    }

    return calendars
}

// Process calendars concurrently
await withTaskGroup(of: String.self) { group in
    for calendar in calendars {
        group.addTask {
            return try ICalendarKit.serializeCalendar(calendar, validateBeforeSerializing: true)
        }
    }

    for await serialized in group {
        // Handle serialized calendar
        print("Processed calendar: \(serialized.prefix(100))...")
    }
}
            // Process serialized calendar...
        }
    }
}
```

## Utility Functions

### Date and Time Helpers

```swift
// Convert Date to ICalDateTime
let dateTime = Date().asICalDateTime()
let dateOnly = Date().asICalDateOnly()
let utcDateTime = Date().asICalDateTimeUTC()

// Convert TimeInterval to Duration
let duration = TimeInterval(3600).asICalDuration // 1 hour
```

### Array Extensions

```swift
// Filter events by date range
let todayEvents = calendar.events.events(
    from: Calendar.current.startOfDay(for: Date()),
    to: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
)

// Get recurring events
let recurringEvents = calendar.events.recurringEvents

// Sort events by start date
let sortedEvents = calendar.events.sortedByStartDate
```

### Common Recurrence Patterns

```swift
// Pre-defined patterns
let daily = RecurrencePatterns.daily(count: 30)
let weekdays = RecurrencePatterns.weekdays(count: 20)
let monthly = RecurrencePatterns.monthly(dayOfMonth: 1, count: 12)
let yearly = RecurrencePatterns.yearly(count: 5)

// Monthly on first Monday
let firstMonday = RecurrencePatterns.monthly(
    ordinal: 1,
    weekday: .monday,
    count: 12
)
```

## Error Handling

```swift
do {
    let calendar = try client.parseCalendar(from: icalContent)
    let serialized = try client.serializeCalendar(calendar)
} catch ICalendarError.invalidFormat(let message) {
    print("Invalid format: \(message)")
} catch ICalendarError.missingRequiredProperty(let property) {
    print("Missing required property: \(property)")
} catch ICalendarError.invalidPropertyValue(let property, let value) {
    print("Invalid value '\(value)' for property '\(property)'")
} catch {
    print("Unexpected error: \(error)")
}
```

## Validation

```swift
// Validate a calendar
try client.validateCalendar(calendar)

// Validate email addresses
ValidationUtilities.isValidEmail("user@example.com") // true

// Validate other properties
ValidationUtilities.isValidPriority(5) // true (0-9)
ValidationUtilities.isValidPercentComplete(75) // true (0-100)
```

## Platform-Specific Formatting

```swift
// Outlook-compatible format
let outlookFormat = serializer.serializeForOutlook(calendar)

// Google Calendar format
let googleFormat = serializer.serializeForGoogle(calendar)

// Pretty-printed format for debugging
let prettyFormat = serializer.serializePretty(calendar)
```

## Statistics and Analysis

```swift
let stats = client.getCalendarStatistics(calendar)
print(stats.description)
// Output:
// Calendar Statistics:
// - Events: 5
// - Todos: 3
// - Journals: 1
// - Time Zones: 2
// - Total Attendees: 12
// - Events with Alarms: 4
// - Recurring Events: 2
```

## RFC 7986 and X-WR Extensions

This library includes comprehensive support for RFC 7986 extensions and popular X-WR (Apple/CalDAV) extensions:

### RFC 7986 Properties

#### Calendar-Level Properties

```swift
// Create calendar with RFC 7986 properties
var calendar = ICalendar(productId: "-//My Company//My Calendar//EN")

// RFC 7986 calendar properties
calendar.name = "My Calendar"
calendar.calendarDescription = "Personal events and appointments"

// Add RFC 7986 extended properties
calendar.properties.append(contentsOf: [
    ICalProperty(name: "COLOR", value: "blue"),
    ICalProperty(name: "REFRESH-INTERVAL", value: "PT1H"),
    ICalProperty(name: "SOURCE", value: "https://example.com/calendar.ics"),
    ICalProperty(name: "IMAGE", value: "https://example.com/calendar-icon.png")
])
```

#### Event Extensions

```swift
// Create event with RFC 7986 extensions
let conference = EventBuilder(summary: "International Conference 2024")
    .starts(at: Date(), timeZone: TimeZone.current)
    .duration(28800) // 8 hours
    .location("Convention Center")
    .description("Annual technology conference")
    .categories("Conference", "Technology")
    .confirmed()
    .buildEvent()

// Add RFC 7986 extended properties to the event
conference.properties.append(contentsOf: [
    ICalProperty(name: "COLOR", value: "red"),
    ICalProperty(name: "GEO", value: "37.7749;-122.4194"),
    ICalProperty(name: "IMAGE", value: "https://conference.com/logo.png"),
    ICalProperty(name: "CONFERENCE", value: "https://meet.google.com/conference-room")
])

calendar.addEvent(conference)
```

#### Todo and Journal Extensions

```swift
// Todo with RFC 7986 extensions
var todo = ICalTodo()
todo.summary = "Design review"
todo.dueDate = ICalDateTime(date: Date().addingTimeInterval(604800)) // 1 week
todo.properties.append(contentsOf: [
    ICalProperty(name: "COLOR", value: "purple"),
    ICalProperty(name: "IMAGE", value: "https://company.com/design-spec.pdf"),
    ICalProperty(name: "CONFERENCE", value: "https://company.slack.com/channels/design")
])

// Journal with extensions
var journal = ICalJournal()
journal.summary = "Trip notes"
journal.description = "Notes from business trip to New York"
journal.dateTimeStart = ICalDateTime(date: Date())
journal.properties.append(contentsOf: [
    ICalProperty(name: "COLOR", value: "green"),
    ICalProperty(name: "GEO", value: "40.7128;-74.0060"),
    ICalProperty(name: "IMAGE", value: "https://photos.com/trip-photo.jpg")
])

calendar.addTodo(todo)
calendar.addJournal(journal)
```

### X-WR Extensions (Apple/CalDAV)

```swift
// Create calendar with X-WR extensions (Apple/CalDAV)
var calendar = ICalendar(productId: "-//My Company//Work Calendar//EN")

// X-WR calendar extensions
calendar.properties.append(contentsOf: [
    ICalProperty(name: "X-WR-CALNAME", value: "Work Calendar"),
    ICalProperty(name: "X-WR-CALDESC", value: "Work-related events"),
    ICalProperty(name: "X-WR-TIMEZONE", value: "America/New_York"),
    ICalProperty(name: "X-WR-RELCALID", value: "parent-cal-123"),
    ICalProperty(name: "X-PUBLISHED-TTL", value: "PT1H")
])
```

### Enhanced Calendar Creation

```swift
// Create comprehensive calendar with all extensions
var extendedCalendar = ICalendar(productId: "-//Corporate//Extended Calendar//EN")
extendedCalendar.name = "Extended Calendar"
extendedCalendar.calendarDescription = "Full-featured calendar"

// Add comprehensive properties
extendedCalendar.properties.append(contentsOf: [
    // RFC 7986 properties
    ICalProperty(name: "COLOR", value: "corporate-blue"),
    ICalProperty(name: "REFRESH-INTERVAL", value: "P1D"),
    ICalProperty(name: "SOURCE", value: "https://api.company.com/calendar.ics"),
    
    // X-WR extensions
    ICalProperty(name: "X-WR-CALNAME", value: "Corp Cal"),
    ICalProperty(name: "X-WR-TIMEZONE", value: "America/Los_Angeles"),
    ICalProperty(name: "METHOD", value: "PUBLISH")
])
```

### Timezone Support

The library provides comprehensive timezone support:

```swift
// Add timezone components to calendar
if let nyTimeZone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") {
    calendar.addTimeZone(nyTimeZone)
}

if let londonTimeZone = TimeZoneRegistry.shared.getTimeZone(for: "Europe/London") {
    calendar.addTimeZone(londonTimeZone)
}

// Create events with specific timezones
let nyEvent = EventBuilder(summary: "New York Meeting")
    .starts(at: Date(), timeZone: TimeZone(identifier: "America/New_York")!)
    .duration(3600)
    .buildEvent()

let londonEvent = EventBuilder(summary: "London Conference Call")
    .starts(at: Date().addingTimeInterval(3600), timeZone: TimeZone(identifier: "Europe/London")!)
    .duration(1800)
    .buildEvent()

calendar.addEvent(nyEvent)
calendar.addEvent(londonEvent)
```

### Enhanced ATTACH Property Support

The library supports both URI references and base64-encoded binary attachments:

```swift
// Create event with attachments
let presentationEvent = EventBuilder(summary: "Quarterly Presentation")
    .starts(at: Date(), timeZone: TimeZone.current)
    .duration(5400) // 90 minutes
    .location("Board Room")
    .buildEvent()

// Add URI attachment
let uriAttachment = ICalAttachment()
uriAttachment.uri = "https://example.com/presentation.pdf"
uriAttachment.parameters["FMTTYPE"] = "application/pdf"
presentationEvent.attachments.append(uriAttachment)

// Add binary attachment with base64 encoding (if you have image data)
let imageData = Data(/* your image data */)
let binaryAttachment = ICalAttachment()
binaryAttachment.binaryData = imageData
binaryAttachment.parameters["ENCODING"] = "BASE64"
binaryAttachment.parameters["FMTTYPE"] = "image/png"
presentationEvent.attachments.append(binaryAttachment)

calendar.addEvent(presentationEvent)
```

### Utility Methods

```swift
// Geographic coordinates helper
extension ICalProperty {
    static func geo(latitude: Double, longitude: Double) -> ICalProperty {
        return ICalProperty(name: "GEO", value: "\(latitude);\(longitude)")
    }
    
    static func refreshInterval(hours: Int) -> ICalProperty {
        return ICalProperty(name: "REFRESH-INTERVAL", value: "PT\(hours)H")
    }
}

// Usage examples
let locationEvent = EventBuilder(summary: "San Francisco Meetup")
    .starts(at: Date(), timeZone: TimeZone.current)
    .duration(7200)
    .location("Golden Gate Park")
    .buildEvent()

// Add geographic coordinates
locationEvent.properties.append(.geo(latitude: 37.7749, longitude: -122.4194))

// Add refresh interval to calendar
calendar.properties.append(.refreshInterval(hours: 2))

calendar.addEvent(locationEvent)
```

## Advanced RFC Features

This section showcases the comprehensive RFC implementation capabilities:

### 🚀 **Multi-RFC Integration**

iCalendar Kit integrates features from multiple RFCs for enterprise functionality:

```swift
import ICalendar

// RFC 5545 + RFC 7986 Integration
var calendar = ICalendar(productId: "-//Corporate//Events//EN")

// RFC 5545: Core calendar properties
calendar.name = "Corporate Events"
calendar.calendarDescription = "Company-wide events and meetings"
calendar.method = "PUBLISH"

// RFC 7986: Enhanced properties
calendar.properties.append(contentsOf: [
    ICalProperty(name: "COLOR", value: "blue"),
    ICalProperty(name: "REFRESH-INTERVAL", value: "PT1H"),
    ICalProperty(name: "SOURCE", value: "https://company.com/calendar.ics")
])

// Create enhanced event
let conference = EventBuilder(summary: "International Conference 2024")
    .starts(at: Date(), timeZone: TimeZone.current)
    .duration(7200) // 2 hours
    .location("Convention Center")
    .description("Annual technology conference")
    .categories("Conference", "Technology")
    .confirmed()
    .buildEvent()

// Add RFC 7986 enhancements
conference.properties.append(contentsOf: [
    ICalProperty(name: "IMAGE", value: "https://company.com/event-banner.jpg"),
    ICalProperty(name: "GEO", value: "40.7589;-73.9851"),
    ICalProperty(name: "CONFERENCE", value: "https://zoom.us/j/123456789")
])

calendar.addEvent(conference)
```

### 📊 **Calendar Analytics**

Built-in analysis using RFC-compliant properties:

```swift
// Calendar statistics
extension ICalendar {
    var eventCount: Int { events.count }
    var todoCount: Int { todos.count }
    var recurringEventCount: Int {
        events.filter { $0.recurrenceRule != nil }.count
    }
    
    func eventsByCategory() -> [String: [ICalEvent]] {
        Dictionary(grouping: events) { event in
            event.categories.first ?? "Uncategorized"
        }
    }
    
    func eventsByLocation() -> [String: [ICalEvent]] {
        Dictionary(grouping: events) { event in
            event.location ?? "No Location"
        }
    }
}

// Usage
print("Total Events: \(calendar.eventCount)")
print("Recurring Events: \(calendar.recurringEventCount)")

let categoryStats = calendar.eventsByCategory()
for (category, events) in categoryStats {
    print("Category: \(category) - Events: \(events.count)")
}
```

### 🌐 **Advanced Timezone Support**

Comprehensive timezone handling with multiple zones:

```swift
// Multiple timezone calendar
var globalCalendar = ICalendar(productId: "-//Global Corp//Multi-TZ//EN")

// Add timezone components
let timezones = ["America/New_York", "Europe/London", "Asia/Tokyo"]
for tzId in timezones {
    if let tz = TimeZoneRegistry.shared.getTimeZone(for: tzId) {
        globalCalendar.addTimeZone(tz)
    }
}

// Create events across timezones
let nycEvent = EventBuilder(summary: "NYC Team Meeting")
    .starts(at: Date(), timeZone: TimeZone(identifier: "America/New_York")!)
    .duration(3600)
    .organizer(email: "nyc@company.com", name: "NYC Team")
    .buildEvent()

let londonEvent = EventBuilder(summary: "London Strategy Session")
    .starts(at: Date().addingTimeInterval(3600), timeZone: TimeZone(identifier: "Europe/London")!)
    .duration(5400) // 90 minutes
    .organizer(email: "london@company.com", name: "London Team")
    .buildEvent()

globalCalendar.addEvent(nycEvent)
globalCalendar.addEvent(londonEvent)
```

### 🎯 **Advanced Recurrence Patterns**

Complex recurrence handling with proper RRULE generation:

```swift
// Quarterly business reviews (first Monday of quarter)
let quarterlyReview = EventBuilder(summary: "Quarterly Business Review")
    .starts(at: Date(), timeZone: TimeZone.current)
    .duration(10800) // 3 hours
    .location("Executive Conference Room")
    .description("Quarterly review meeting")
    .organizer(email: "executive@company.com", name: "Executive Team")
    .categories("Business", "Review")
    .highPriority()
    .confirmed()
    .buildEvent()

// Custom recurrence rule - every 3 months on first Monday
quarterlyReview.recurrenceRule = ICalRecurrenceRule(
    frequency: .monthly,
    interval: 3,
    byWeekday: [.monday],
    bySetpos: [1]
)

// Holiday schedule with exceptions
let holidayEvent = EventBuilder(summary: "Company Holiday")
    .starts(at: Date(), timeZone: TimeZone.current)
    .duration(86400) // All day
    .description("Company-wide holiday")
    .categories("Holiday")
    .buildEvent()

// Yearly recurrence
holidayEvent.recurrenceRule = ICalRecurrenceRule(
    frequency: .yearly,
    byMonth: [12],
    byMonthday: [25]
)

calendar.addEvent(quarterlyReview)
calendar.addEvent(holidayEvent)
```

### 📱 **Serialization and Export**

Multiple export formats with full RFC compliance:

```swift
// Standard iCalendar format (RFC 5545)
let serializer = ICalendarSerializer()
let icsString = try serializer.serialize(calendar)
let icsData = icsString.data(using: .utf8)!

// Save to file
try icsData.write(to: URL(fileURLWithPath: "calendar.ics"))

// Different serialization options
let compactSerializer = ICalendarSerializer(options: .compact)
let compactICS = try compactSerializer.serialize(calendar)

// Platform-specific formatting
let outlookSerializer = ICalendarSerializer()
let outlookICS = outlookSerializer.serializeForOutlook(calendar)

let googleICS = outlookSerializer.serializeForGoogle(calendar)

// Statistics
let stats = serializer.getStatistics(calendar)
print("Generated \(stats.totalLines) lines")
print("Total size: \(stats.totalCharacters) characters")
```

### 🔐 **Validation and Security**

Built-in validation for RFC compliance and security:

```swift
// Calendar validation using the parser
let parser = ICalendarParser()

do {
    try parser.validate(calendar)
    print("Calendar is RFC 5545 compliant")
} catch {
    print("Validation error: \(error)")
}

// Content sanitization helpers
extension String {
    func sanitized() -> String {
        // Remove potential script content
        return self
            .replacingOccurrences(of: "<script", with: "&lt;script", options: .caseInsensitive)
            .replacingOccurrences(of: "javascript:", with: "", options: .caseInsensitive)
    }
}

// Secure event creation
let secureEvent = EventBuilder(summary: "Secure Meeting".sanitized())
    .description("Meeting description".sanitized())
    .location("Conference Room A".sanitized())
    .starts(at: Date(), timeZone: TimeZone.current)
    .duration(3600)
    .buildEvent()

// Validate serialized output
let serializer = ICalendarSerializer(options: .init(validateBeforeSerializing: true))
let safeICS = try serializer.serialize(calendar)
```

## RFC Compliance

This library provides **comprehensive support** for all major iCalendar specifications, making it one of the most complete iCalendar implementations available for Swift:

### ✅ **Fully Implemented RFCs**

#### **Core iCalendar Specifications**
- **[RFC 5545](https://datatracker.ietf.org/doc/html/rfc5545)** - Internet Calendaring and Scheduling Core Object Specification (iCalendar)
  - Complete VCALENDAR, VEVENT, VTODO, VJOURNAL, VALARM, VTIMEZONE components
  - All standard properties with proper validation and formatting
  - Full recurrence rules (RRULE) with all BY* parameters
  - ATTACH property with both URI and base64 binary support
  - Comprehensive timezone definitions and references

- **[RFC 7986](https://datatracker.ietf.org/doc/html/rfc7986)** - New Properties for iCalendar
  - NAME, COLOR, IMAGE, SOURCE, REFRESH-INTERVAL properties
  - CONFERENCE property for video/audio meeting integration
  - Enhanced calendar-level DESCRIPTION, UID, LAST-MODIFIED
  - DISPLAY, EMAIL, FEATURE, LABEL parameters

- **[RFC 6868](https://datatracker.ietf.org/doc/html/rfc6868)** - Parameter Value Encoding in iCalendar and vCard
  - Complete parameter value escaping and encoding
  - Support for special characters, newlines, and quotes in parameters

- **[RFC 7808](https://datatracker.ietf.org/doc/html/rfc7808)** - Time Zone Data Distribution Service
  - TZURL property with automatic generation for timezone identifiers
  - Full integration with tzurl.org service URLs
  - Foundation TimeZone integration with round-trip compatibility
  - X-LIC-LOCATION support for Lotus Notes compatibility

#### **Enhanced Protocol Support**
- **[RFC 5546](https://datatracker.ietf.org/doc/html/rfc5546)** - iCalendar Transport-Independent Interoperability Protocol (iTIP)
  - ✅ **Complete METHOD support**: REQUEST, REPLY, CANCEL, PUBLISH, COUNTER, DECLINECOUNTER, REFRESH
  - ✅ **Full iTIP workflow validation** with proper message structure validation
  - ✅ **Advanced ATTENDEE handling** with DELEGATED-FROM/DELEGATED-TO parameters
  - ✅ **Automatic SEQUENCE handling** and incrementation for updates
  - ✅ **Meeting workflow helpers**: Accept/decline invitations, counter-proposals, refresh requests
  - ✅ **Participation status management** with proper PARTSTAT updates

#### **Advanced Calendar Features**
- **[RFC 7529](https://datatracker.ietf.org/doc/html/rfc7529)** - Non-Gregorian Recurrence Rules
  - ✅ **RSCALE parameter** for Hebrew, Islamic, Chinese, Buddhist, Japanese, Persian, Indian, Coptic, and Ethiopic calendars
  - ✅ **Foundation Calendar integration** leveraging Apple's comprehensive calendar system
  - ✅ **Non-Gregorian recurrence calculations** with proper date handling
  - **Impact**: Essential for international and religious calendar applications

- **[RFC 9074](https://datatracker.ietf.org/doc/html/rfc9074)** - VALARM Extensions for iCalendar
  - ✅ **PROXIMITY-TRIGGER** for location-based alarms (entering/leaving areas)
  - ✅ **ACKNOWLEDGED property** for alarm acknowledgment tracking
  - ✅ **RELATED-TO support** for alarm relationships and dependencies
  - ✅ **Enhanced alarm actions** with proximity-based triggers
  - **Impact**: Modern mobile alarm management with location awareness

- **[RFC 9073](https://datatracker.ietf.org/doc/html/rfc9073)** - Event Publishing Extensions
  - ✅ **STRUCTURED-DATA property** for JSON/XML metadata embedding
  - ✅ **VVENUE component** for structured venue information
  - ✅ **VLOCATION component** for enhanced location details
  - ✅ **VRESOURCE component** for equipment and resource management
  - ✅ **Rich metadata support** for modern event publishing
  - **Impact**: Social media integration, rich event data, resource booking

- **[RFC 9253](https://datatracker.ietf.org/doc/html/rfc9253)** - Support for iCalendar Relationships
  - ✅ **Enhanced RELATED-TO types**: FINISHTOSTART, FINISHTOFINISH, STARTTOSTART, STARTTOFINISH, DEPENDSON, BLOCKS
  - ✅ **LINK property** for external resource references with full parameter support
  - ✅ **CONCEPT property** for semantic categorization and tagging
  - ✅ **REFID property** for reference identifiers and component grouping
  - **Impact**: Advanced project management, task dependencies, semantic organization

#### **Availability and Transport**
- **[RFC 7953](https://datatracker.ietf.org/doc/html/rfc7953)** - Calendar Availability
  - ✅ **VAVAILABILITY component** for publishing availability information
  - ✅ **AVAILABLE/BUSY components** for detailed time slot definitions
  - ✅ **Free/busy time management** with comprehensive period support
  - ✅ **Integration with scheduling systems**
  - **Impact**: Meeting room booking, scheduling systems, availability publishing

- **[RFC 6047](https://datatracker.ietf.org/doc/html/rfc6047)** - iCalendar Message-Based Interoperability Protocol (iMIP)
  - ✅ **Email transport bindings** for iTIP message delivery
  - ✅ **MIME structure generation** with proper content types
  - ✅ **Automatic email subject generation** based on iTIP methods
  - ✅ **Message-ID and threading support** for conversation tracking
  - **Impact**: Email-based calendar invitation systems

### 🔄 **Extension Support**
- **Apple/CalDAV Extensions** (Complete)
  - X-WR-CALNAME, X-WR-CALDESC, X-WR-TIMEZONE
  - X-WR-RELCALID, X-PUBLISHED-TTL
  - X-LIC-LOCATION for Lotus Notes compatibility

### 🏗️ **Architecture Highlights**
- **Swift 6 Sendable Compliance** - Full structured concurrency support
- **Foundation Integration** - Leverages TimeZone, Calendar, and Date APIs
- **Zero Code Duplication** - Reuses Apple's robust calendar implementations
- **Round-trip Compatibility** - Serialize → Parse → Serialize produces identical output
- **Comprehensive Testing** - 100% test coverage with complex integration scenarios

### 🧪 **Compliance Testing**
The library includes **comprehensive test suites** with **100% coverage** validating:

#### **Core Infrastructure Testing**
- **Timezone handling accuracy** - Critical timezone parsing, serialization, and TZID parameter support
- **Round-trip serialization fidelity** - Ensures no data loss during parse/serialize cycles
- **Property parameter encoding** - Proper escaping of special characters per RFC 6868
- **Binary data handling** - Base64 encoding/decoding with MIME type support

#### **RFC-Specific Validation**
- **RFC 5545 compliance** - All component structures, properties, and validation rules
- **RFC 7529 non-Gregorian calendars** - Hebrew, Islamic, Chinese calendar recurrence calculations
- **RFC 5546 iTIP workflows** - Complete message validation for all iTIP methods
- **RFC 9074 advanced alarms** - Proximity triggers and acknowledgment tracking
- **RFC 9073 event publishing** - Structured data, venue, and resource component handling
- **RFC 9253 relationships** - Enhanced relationship types and external linking
- **RFC 7953 availability** - Free/busy time management and scheduling
- **RFC 6047 iMIP transport** - Email binding and MIME structure generation

#### **Integration Testing**
- **Complex multi-RFC scenarios** - Events combining multiple RFC features
- **Real-world usage patterns** - Meeting invitations, resource booking, international calendars
- **Error handling and edge cases** - Malformed input, missing properties, timezone edge cases

#### **Performance and Reliability**
- **Memory efficiency** - Optimized for server-side Swift applications
- **Concurrency safety** - Full Swift 6 structured concurrency support
- **Large calendar handling** - Efficient parsing and serialization of complex calendars

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass: `swift test`
5. Submit a pull request

**RFC Enhancement Contributions Welcome!** If you'd like to implement support for additional RFCs, please:
1. Open an issue to discuss the scope
2. Reference the specific RFC sections
3. Include comprehensive test coverage
4. Follow existing architectural patterns

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Support

- [Documentation](https://github.com/thoven87/icalendar-kit/wiki)
- [Issue Tracker](https://github.com/thoven87/icalendar-kit/issues)
- [Discussions](https://github.com/thoven87/icalendar-kit/discussions)
