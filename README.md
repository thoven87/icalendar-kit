# iCalendar Kit

A comprehensive Swift 6 library for parsing and creating iCalendar (RFC 5545) events with full support for structured concurrency, Sendable conformance, and modern Swift features.

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fthoven87%2Ficalendar-kit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/thoven87/icalendar-kit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fthoven87%2Ficalendar-kit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/thoven87/icalendar-kit)
[![CI](https://github.com/thoven87/icalendar-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/thoven87/icalendar-kit/actions/workflows/ci.yml)

## Features

- **RFC Compliant**: Full support for RFC 5545, 7986, 6868, 7808, and more
- **Swift 6 Ready**: Complete Sendable conformance and structured concurrency support
- **Modern API**: Fluent EventBuilder with transparency, versioning, location, and theming support
- **Maximum Compatibility**: Automatic legacy X-WR fallbacks for older calendar systems
- **Comprehensive**: Events, todos, journals, alarms, time zones, recurrence rules, and VCards
- **Type Safe**: Unified alarm API with RFC-compliant action-specific requirements

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/thoven87/icalendar-kit.git", from: "2.0.0")
]
```

## Quick Start

### Creating Events

```swift
import ICalendar

let event = EventBuilder(summary: "Team Meeting")
    .starts(at: Date(), timeZone: .current)
    .duration(3600)
    .location("Conference Room A")
    .description("Weekly team sync")
    
    // Modern properties
    .transparent()  // Shows as available time
    .sequence(1)    // Event version
    .geoCoordinates(latitude: 37.7749, longitude: -122.4194)
    .color(hex: "FF5733")
    .conference("https://zoom.us/j/123456789")
    .attachment("agenda.pdf", mediaType: "application/pdf")
    
    // Attendees and alarms
    .organizer(email: "manager@company.com", name: "Manager")
    .addAlarm(.display(description: "Meeting in 15 min"), trigger: .minutesBefore(15))
    .buildEvent()

var calendar = ICalendar(productId: "-//My App//EN")
calendar.addEvent(event)

let icsString = try ICalendarSerializer().serialize(calendar)
```

### Parsing Calendars

```swift
let icalContent = """
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//My App//EN
BEGIN:VEVENT
UID:event-123
SUMMARY:Important Meeting
DTSTART:20240101T140000Z
DTEND:20240101T150000Z
END:VEVENT
END:VCALENDAR
"""

let calendar = try ICalendarKit.parseCalendar(from: icalContent)
print("Found \(calendar.events.count) events")
```

### Working with VCards

```swift
let contact = VCardBuilder(name: "John Doe")
    .email("john@company.com")
    .phone("+1-555-0123")
    .organization("Tech Corp")
    .buildVCard()

let vcfString = try VCardSerializer().serialize([contact])
```

## EventBuilder Properties

The modern `EventBuilder` API supports all essential iCalendar properties:

| Category | Properties |
|----------|------------|
| **Scheduling** | `starts()`, `ends()`, `duration()`, `allDay()` |
| **Status** | `confirmed()`, `tentative()`, `cancelled()` |
| **Priority** | `priority()`, `highPriority()`, `lowPriority()` |
| **Classification** | `publicEvent()`, `privateEvent()`, `confidential()` |
| **Availability** | `transparent()`, `opaque()`, `transparency()` |
| **Versioning** | `sequence()` |
| **Location** | `location()`, `geoCoordinates()` |
| **Visual** | `color()`, `color(hex:)`, `image()` |
| **Modern** | `conference()`, `attachment()` |
| **RFC 9073** | `venue()`, `locationComponent()`, `resource()` |
| **People** | `organizer()`, `addAttendee()` |
| **Recurrence** | `repeats*()` methods |
| **Alarms** | `addAlarm()`, `reminderBefore()` |

## Documentation

For comprehensive documentation, examples, and advanced usage:

📖 **[Complete Documentation](Sources/ICalendar/Documentation.docc/ICalendar.md)**

Includes:
- Advanced EventBuilder usage
- Recurring events and time zones
- RFC compliance details
- Server integration examples
- VCard contact management
- Migration guides

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 6.0+
- Xcode 16.0+
- Linux

## RFC Compliance

| RFC | Description | Status |
|-----|-------------|---------|
| **RFC 5545** | iCalendar Core | ✅ Complete |
| **RFC 7986** | Calendar Extensions | ✅ Complete |
| **RFC 6868** | Parameter Encoding | ✅ Complete |
| **RFC 7808** | Time Zone Data | ✅ Complete |
| **RFC 9073** | Event Publishing Extensions | ✅ Complete |

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our [GitHub repository](https://github.com/thoven87/icalendar-kit).

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

- 📖 [Documentation](Sources/ICalendar/Documentation.docc/ICalendar.md)
- 🐛 [Issue Tracker](https://github.com/thoven87/icalendar-kit/issues)
- 💬 [Discussions](https://github.com/thoven87/icalendar-kit/discussions)
