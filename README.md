# iCalendar Kit

A comprehensive Swift 6 library for parsing and creating iCalendar (RFC 5545) events with full support for structured concurrency, Sendable conformance, and modern Swift features.

## Features

- **RFC Compliant**: Full support for RFC 5545, RFC 5546, RFC 6868, RFC 7529, and RFC 7986
- **Swift 6 Ready**: Complete Sendable conformance and structured concurrency support
- **Type Safe**: Uses structs instead of classes with comprehensive type  operations
- **Comprehensive**: Support for events, todos, journals, alarms, time zones, and recurrence rules
- **Builder Pattern**: Fluent API for easy calendar and event creation
- **Extensible**: Support for custom properties and extensions

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 6.0+
- Xcode 16.0+

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

let client = ICalendar()

// Create a simple event
let event = client.createEvent(
    summary: "Team Meeting",
    startDate: Date(),
    endDate: Date().addingTimeInterval(3600), // 1 hour later
    location: "Conference Room A",
    description: "Weekly team sync meeting"
)

// Create a calendar and add the event
var calendar = client.createCalendar(productId: "-//My App//EN")
calendar.addEvent(event)

// Serialize to iCalendar format
let icalString = try client.serializeCalendar(calendar)
print(icalString)
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

let calendar = try client.parseCalendar(from: icalContent)
print("Found \(calendar.events.count) events")
```

## Advanced Usage

### Creating Recurring Events

```swift
// Daily recurrence for 10 days
let dailyRule = client.createDailyRecurrence(interval: 1, count: 10)

// Weekly on Monday, Wednesday, Friday
let weeklyRule = client.createWeeklyRecurrence(
    daysOfWeek: [.monday, .wednesday, .friday],
    count: 8
)

// Monthly on the 15th
let monthlyRule = client.createMonthlyRecurrence(
    dayOfMonth: 15,
    count: 12
)

let recurringEvent = client.createRecurringEvent(
    summary: "Recurring Meeting",
    startDate: Date(),
    endDate: Date().addingTimeInterval(3600),
    recurrenceRule: weeklyRule
)
```

### Adding Attendees and Organizer

```swift
let organizer = client.createOrganizer(
    email: "organizer@company.com",
    name: "Meeting Organizer"
)

let attendees = [
    client.createAttendee(
        email: "john@company.com",
        name: "John Doe",
        role: .requiredParticipant,
        status: .needsAction,
        rsvp: true
    ),
    client.createAttendee(
        email: "jane@company.com",
        name: "Jane Smith",
        role: .optionalParticipant
    )
]

let meetingCalendar = client.createMeetingInvitation(
    summary: "Project Kickoff",
    startDate: Date(),
    endDate: Date().addingTimeInterval(7200),
    location: "Main Conference Room",
    description: "Kickoff meeting for the new project",
    organizer: organizer,
    attendees: attendees,
    reminderMinutes: 15
)
```

### Using the Builder Pattern

```swift
// Event builder
let event = ICalEventBuilder(summary: "Design Review")
    .description("Review of the new user interface designs")
    .location("Design Studio")
    .startDate(Date())
    .endDate(Date().addingTimeInterval(5400)) // 1.5 hours
    .status(.confirmed)
    .priority(5)
    .organizer(organizer)
    .attendees(attendees)
    .alarm(client.createDisplayAlarm(
        description: "Design review starting soon",
        triggerMinutesBefore: 10
    ))
    .build()

// Calendar builder
let calendar = ICalendarBuilder(productId: "-//Design App//EN")
    .method("REQUEST")
    .addEvent(event)
    .build()
```

### Working with Time Zones

```swift
// Create events with specific time zones
let pstTimeZone = TimeZone(identifier: "America/Los_Angeles")!
let event = client.createEvent(
    summary: "West Coast Meeting",
    startDate: Date(),
    endDate: Date().addingTimeInterval(3600)
)

// The datetime will include timezone information
event.dateTimeStart = ICalDateTime(
    date: Date(),
    timeZone: pstTimeZone
)
```

### Creating To-Do Items

```swift
let todo = client.createTodo(
    summary: "Complete project documentation",
    dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
    priority: 3,
    description: "Write comprehensive documentation for the API"
)

todo.percentComplete = 25
todo.status = .inProcess

var calendar = client.createCalendar()
calendar.addTodo(todo)
```

### Working with Alarms

```swift
// Display alarm 15 minutes before
let displayAlarm = client.createDisplayAlarm(
    description: "Meeting reminder",
    triggerMinutesBefore: 15
)

// Audio alarm 5 minutes before
let audioAlarm = client.createAudioAlarm(
    triggerMinutesBefore: 5,
    audioFile: "reminder.wav"
)

// Email alarm 1 day before
let emailAlarm = client.createEmailAlarm(
    summary: "Meeting Tomorrow",
    description: "Don't forget about the important meeting tomorrow",
    attendees: [organizer],
    triggerMinutesBefore: 1440 // 24 hours
)

event.addAlarm(displayAlarm)
event.addAlarm(audioAlarm)
event.addAlarm(emailAlarm)
```

## Configuration

### Client Configuration

```swift
let configuration = ICalendar.Configuration(
    defaultProductId: "-//My Company//My App//EN",
    validateOnParse: true,
    validateOnSerialize: true,
    enableExtensions: true
)

let client = ICalendar(configuration: configuration)
```

### Serialization Options

```swift
let serializationOptions = ICalendarSerializer.SerializationOptions(
    lineLength: 75,
    sortProperties: true,
    includeOptionalProperties: true,
    validateBeforeSerializing: true
)

let serializer = ICalendarSerializer(options: serializationOptions)
let serialized = try serializer.serialize(calendar)
```

## Structured Concurrency Support

The library is built with Swift 6 structured concurrency in mind:

```swift
// Concurrent parsing of multiple calendars
let calendar1 = client.parseCalendar(from: content1)
let calendar2 = client.parseCalendar(from: content2)
let calendar3 = client.parseCalendar(from: content3)

let calendars = try [calendar1, calendar2, calendar3]

// Process calendars concurrently
withTaskGroup { group in
    for calendar in calendars {
        group.addTask {
            let serialized = try client.serializeCalendar(calendar)
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

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass: `swift test`
5. Submit a pull request

## RFC Compliance

This library implements the following RFCs:

- **RFC 5545**: Internet Calendaring and Scheduling Core Object Specification (iCalendar)
- **RFC 5546**: iCalendar Transport-Independent Interoperability Protocol (iTIP)
- **RFC 6868**: Parameter Value Encoding in iCalendar and vCard
- **RFC 7529**: Non-Gregorian Recurrence Rules in iCalendar
- **RFC 7986**: New Properties for iCalendar

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Support

- [Documentation](https://github.com/thoven87/icalendar-kit/wiki)
- [Issue Tracker](https://github.com/thoven87/icalendar-kit/issues)
- [Discussions](https://github.com/thoven87/icalendar-kit/discussions)
