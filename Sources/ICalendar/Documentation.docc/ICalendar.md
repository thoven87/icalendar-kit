# ``ICalendar``

A comprehensive Swift library for parsing, creating, and managing iCalendar (RFC 5545) data with full timezone support and enterprise features.

## Overview

iCalendar Kit provides a comprehensive Swift implementation for creating, parsing, and managing iCalendar (RFC 5545) events, todos, journals, and related components. This library is designed for enterprise applications, calendar services, and any Swift application requiring robust calendar functionality.

With the modern EventBuilder API, you can create feature-complete calendar events using a clean, type-safe interface that supports all essential iCalendar properties including transparency, versioning, location services, theming, and modern meeting features.

### Key Features

- **RFC Compliance**: Full support for RFC 5545, RFC 7986, RFC 6868, RFC 7808, and many other iCalendar-related specifications
- **Maximum Compatibility**: RFC 7986 standard properties with automatic legacy X-WR fallbacks for universal calendar support
- **Unified Alarm API**: Type-safe alarm creation with RFC 5545 compliance and action-specific requirements
- **Enterprise Ready**: Production-ready with comprehensive timezone handling and calendar feed support
- **Email Integration**: Built-in iTIP/iMIP support for calendar invitations and responses
- **Swift 6 Compatible**: Built with modern Swift concurrency and sendable conformance
- **Cross-Platform**: Works in modern apps (Google Calendar) and legacy systems (older Apple Calendar)

## Getting Started

### Basic Usage with RFC 7986 Compatibility

Create calendars with maximum compatibility using RFC 7986 properties that automatically include legacy X-WR equivalents:

```swift
import ICalendar

// Create calendar with RFC 7986 properties (automatic legacy compatibility)
var calendar = ICalendar(productId: "-//My App//Modern Calendar//EN")
calendar.name = "My Team Calendar"  // Sets both NAME and X-WR-CALNAME
calendar.calendarDescription = "Personal events and meetings"  // Sets both DESCRIPTION and X-WR-CALDESC
calendar.refreshInterval = ICalDuration(hours: 6)  // Sets both REFRESH-INTERVAL and X-PUBLISHED-TTL
calendar.color = "#2196F3"  // Material Blue

// Create event with unified alarm API
let organizer = ICalAttendee(email: "manager@company.com", commonName: "Manager")

let teamMeeting = EventBuilder(summary: "Team Meeting")
    .starts(at: Date(), timeZone: .current)
    .duration(3600) // 1 hour
    .location("Conference Room A")
    .description("Weekly team sync meeting")
    .organizer(email: "manager@company.com", name: "Manager")
    // Type-safe, RFC 5545 compliant alarms
    .addAlarm(.display(description: "Meeting in 15 minutes"), trigger: .minutesBefore(15))
    .addAlarm(.email(description: "Meeting reminder", summary: "Team Meeting", to: organizer), trigger: .minutesBefore(60))
    .addAlarm(.audio(), trigger: .minutesBefore(5))
    .buildEvent()

calendar.addEvent(teamMeeting)

// Export to iCalendar format (includes both RFC 7986 and legacy properties)
let icsContent = try ICalendarSerializer().serialize(calendar)
```

### Unified Alarm API

The unified alarm API provides compile-time safety and ensures all RFC 5545 requirements are met:

```swift
let attendee = ICalAttendee(email: "user@company.com", commonName: "User")

let event = EventBuilder(summary: "Important Meeting")
    .starts(at: Date(), timeZone: .current)
    .duration(3600)
    
    // DISPLAY alarms require description
    .addAlarm(.display(description: "Meeting soon"), trigger: .minutesBefore(15))
    
    // EMAIL alarms require description, summary, and attendee
    .addAlarm(.email(
        description: "Don't forget the meeting",
        summary: "Meeting Reminder",
        to: attendee
    ), trigger: .minutesBefore(60))
    
    // AUDIO alarms have optional attachment
    .addAlarm(.audio(), trigger: .minutesBefore(5))
    
    // Multiple alarms at once
    .addAlarms([
        .display(description: "5 minute warning"),
        .display(description: "1 minute warning"),
        .audio()
    ], triggers: [
        .minutesBefore(5),
        .minutesBefore(1),
        .eventStart
    ])
    
    .buildEvent()
```

### RFC 7986 Properties with Legacy Compatibility

All RFC 7986 properties automatically include their legacy X-WR equivalents for maximum compatibility:

```swift
var calendar = ICalendar(productId: "-//My App//EN")

// RFC 7986 → Legacy Property Mappings:
calendar.name = "Business Calendar"                    // NAME + X-WR-CALNAME
calendar.calendarDescription = "Company events"        // DESCRIPTION + X-WR-CALDESC
calendar.refreshInterval = ICalDuration(hours: 24)     // REFRESH-INTERVAL + X-PUBLISHED-TTL

// Generated ICS includes both for universal compatibility:
// NAME:Business Calendar
// X-WR-CALNAME:Business Calendar
// DESCRIPTION:Company events  
// X-WR-CALDESC:Company events
// REFRESH-INTERVAL:PT24H
// X-PUBLISHED-TTL:PT24H
```

## Complete Example - Enterprise Calendar

Here's a comprehensive example showcasing all the key features including RFC 7986 compatibility, unified alarms, and timezone handling:

```swift
import ICalendar

/// Production-ready calendar with maximum compatibility
func createEnterpriseCalendar() throws -> String {
    // Create calendar with RFC 7986 properties (automatic legacy compatibility)
    var calendar = ICalendar(productId: "-//Enterprise Corp//Business Calendar v2.0//EN")
    
    // RFC 7986 properties (automatically includes X-WR equivalents)
    calendar.name = "Enterprise Business Calendar"
    calendar.calendarDescription = "Official company calendar with meetings, deadlines, and events"
    calendar.refreshInterval = ICalDuration(hours: 6)  // Refresh every 6 hours
    calendar.color = "#1976D2"  // Corporate blue
    calendar.source = "https://api.enterprise.com/calendar.ics"
    
    // Create attendees
    let ceo = ICalAttendee(email: "ceo@enterprise.com", commonName: "CEO")
    let manager = ICalAttendee(email: "manager@enterprise.com", commonName: "Project Manager")
    
    // Executive Meeting with Email Notifications
    let executiveMeeting = EventBuilder(summary: "📊 Quarterly Business Review")
        .starts(at: Date().addingTimeInterval(86400), timeZone: .current)  // Tomorrow
        .duration(7200)  // 2 hours
        .location("Executive Boardroom")
        .description("Comprehensive Q4 performance review with stakeholder presentations")
        .organizer(email: "ceo@enterprise.com", name: "CEO")
        .addAttendee(email: "manager@enterprise.com", name: "Project Manager", role: .requiredParticipant)
        .addAttendee(email: "team@enterprise.com", name: "Development Team", role: .optionalParticipant, userType: .group)
        .highPriority()
        .confirmed()
        // Progressive alarm strategy with type-safe API
        .addAlarm(.email(
            description: "Quarterly review tomorrow - please prepare your reports",
            summary: "Business Review Preparation",
            to: ceo
        ), trigger: .minutesBefore(1440))  // 24 hours
        .addAlarm(.display(description: "Business review in 30 minutes"), trigger: .minutesBefore(30))
        .addAlarm(.audio(), trigger: .minutesBefore(10))  // Sound notification
        .buildEvent()
    
    // Recurring Team Standup
    let dailyStandup = EventBuilder(summary: "🚀 Daily Team Standup")
        .starts(at: nextMondayAt9AM(), timeZone: .current)
        .duration(900)  // 15 minutes
        .location("Conference Room A / Virtual")
        .description("Daily team coordination and blocker discussion")
        .organizer(email: "manager@enterprise.com", name: "Project Manager")
        .repeatsWeekly(every: 1, on: [.monday, .tuesday, .wednesday, .thursday, .friday])
        .confirmed()
        // Multiple alarms for recurring events
        .addAlarms([
            .display(description: "Standup in 10 minutes"),
            .display(description: "Standup starting now")
        ], triggers: [
            .minutesBefore(10),
            .eventStart
        ])
        .buildEvent()
    
    // Add events to calendar
    calendar.addEvent(executiveMeeting)
    calendar.addEvent(dailyStandup)
    
    // Serialize with validation
    return try ICalendarSerializer().serialize(calendar)
}

private func nextMondayAt9AM() -> Date {
    let calendar = Calendar.current
    let now = Date()
    let nextMonday = calendar.nextDate(after: now, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime)!
    return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: nextMonday)!
}
```

### Timezone-Aware Events

Handle events across multiple timezones with proper VTIMEZONE components:

```swift
// Create events in different timezones
let nycTimezone = TimeZone(identifier: "America/New_York")!
let londonTimezone = TimeZone(identifier: "Europe/London")!

let calendar = ICalendar.calendar(productId: "-//Global Corp//EN") {
    CalendarName("Global Meetings")
    DefaultTimeZone(nycTimezone)
    
    ICalendarFactory.createEvent(
        summary: "Global All-Hands",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600),
        timeZone: nycTimezone
    )
    
    ICalendarFactory.createEvent(
        summary: "London Team Sync",
        startDate: Date().addingTimeInterval(86400), // tomorrow
        endDate: Date().addingTimeInterval(90000),
        timeZone: londonTimezone
    )
}
```

### Modern EventBuilder API

The EventBuilder provides a comprehensive, type-safe API for creating modern iCalendar events with all RFC-compliant properties:

#### Complete Property Support

```swift
let event = EventBuilder(summary: "Company Retreat 2024")
    .description("Annual team building and strategic planning")
    .location("Napa Valley Resort")
    
    // Scheduling
    .starts(at: Date(), timeZone: .current)
    .duration(28800) // 8 hours
    
    // Status and Priority
    .confirmed()
    .highPriority()
    .publicEvent()
    
    // Modern Properties (NEW!)
    .transparent()              // Shows as "Available" 
    .sequence(1)               // Event version for updates
    .geoCoordinates(latitude: 38.2975, longitude: -122.2869)
    .color(hex: "E74C3C")      // Visual theming
    .conference("https://zoom.us/retreat-2024")
    .image("https://company.com/retreat-banner.jpg")
    .attachment("agenda.pdf", mediaType: "application/pdf")
    
    // Attendees and Organization
    .organizer(email: "hr@company.com", name: "HR Team")
    .addAttendee(email: "ceo@company.com", name: "CEO", 
                role: .chair, status: .accepted)
    .categories("Company", "Retreat", "Annual")
    
    // Alarms and Reminders
    .addAlarm(.display(description: "Retreat tomorrow!"), 
              trigger: .minutesBefore(1440))
    .buildEvent()
```

#### Availability and Transparency

Control how events appear in calendar applications:

```swift
// Available time - others can schedule over this
let officeHours = EventBuilder(summary: "Office Hours")
    .transparent()  // Shows as "Available"
    .buildEvent()

// Busy time - blocks calendar
let focusTime = EventBuilder(summary: "Deep Work")
    .opaque()      // Shows as "Busy"
    .buildEvent()
```

#### Event Versioning and Updates

Use sequence numbers for proper event updates:

```swift
// Original event
let meeting = EventBuilder(summary: "Team Meeting")
    .sequence(0)  // Initial version
    .buildEvent()

// Updated event
let updatedMeeting = EventBuilder(summary: "Team Meeting - UPDATED")
    .sequence(1)  // Version 1
    .buildEvent()
```

#### Location and Geographic Data

Add GPS coordinates for location services:

```swift
let conference = EventBuilder(summary: "Tech Conference")
    .location("Moscone Center")
    .geoCoordinates(latitude: 37.7840, longitude: -122.4014)
    .buildEvent()
```

#### Visual Theming and Branding

Add colors and imagery to events:

```swift
let brandedEvent = EventBuilder(summary: "Company All-Hands")
    .color("red")                    // Named color
    .color(hex: "3498DB")           // Hex color
    .image("https://company.com/banner.jpg")
    .buildEvent()
```

#### Modern Meeting Features

RFC 7986 compliant video meetings and file attachments:

```swift
let modernMeeting = EventBuilder(summary: "Product Review")
    .conference("https://teams.microsoft.com/meet/abc123")
    .attachment("spec.pdf", mediaType: "application/pdf")
    .attachment("https://github.com/project/feature")
    .buildEvent()
```

#### Complete EventBuilder Property Reference

| Category | Properties | Description |
|----------|------------|-------------|
| **Scheduling** | `starts()`, `ends()`, `duration()`, `allDay()` | Event timing |
| **Status** | `confirmed()`, `tentative()`, `cancelled()` | Event status |
| **Priority** | `priority()`, `highPriority()`, `normalPriority()`, `lowPriority()` | Event importance |
| **Classification** | `publicEvent()`, `privateEvent()`, `confidential()` | Access control |
| **Availability** | `transparent()`, `opaque()`, `transparency()` | Calendar blocking |
| **Versioning** | `sequence()` | Event update tracking |
| **Location** | `location()`, `geoCoordinates()` | Physical location |
| **Visual** | `color()`, `color(hex:)`, `image()`, `addImage()` | Theming and branding |
| **Modern** | `conference()`, `attachment()` | Video calls and files |
| **People** | `organizer()`, `addAttendee()`, `addAttendees()` | Meeting participants |
| **Content** | `description()`, `htmlDescription()`, `categories()`, `url()` | Event information |
| **Recurrence** | `repeats*()` methods, `except()` | Recurring events |
| **Alarms** | `addAlarm()`, `addAlarms()`, `reminderBefore()` | Notifications |
| **Timestamps** | `created()`, `createdNow()`, `lastModifiedNow()` | Audit trail |
| **Advanced** | `customProperty()`, `modify()` | Power user features |
| **RFC 9073** | `venue()`, `locationComponent()`, `resource()` | Structured venue/resource data |

### Real-World EventBuilder Examples

#### Corporate Meeting with All Features

```swift
let corporateMeeting = EventBuilder(summary: "Q4 Board Meeting")
    .description("Quarterly board review with financial presentations")
    .location("Executive Conference Room")
    .starts(at: Date().addingTimeInterval(86400), timeZone: .current)
    .duration(7200) // 2 hours
    
    // Status and importance
    .confirmed()
    .highPriority()
    .confidential()
    
    // Modern features
    .sequence(0)    // Initial version
    .opaque()       // Blocks calendar time
    .color(hex: "8B0000") // Dark red for executive meetings
    .geoCoordinates(latitude: 40.7589, longitude: -73.9851)
    .conference("https://zoom.us/board-meeting")
    .attachment("financial-report.pdf", mediaType: "application/pdf")
    .image("https://company.com/board-banner.jpg")
    
    // Attendees
    .organizer(email: "board@company.com", name: "Board Secretary")
    .addAttendee(email: "ceo@company.com", name: "CEO", 
                role: .chair, status: .accepted)
    .addAttendee(email: "cfo@company.com", name: "CFO", 
                role: .requiredParticipant, rsvp: true)
    
    // Categories and alarms
    .categories("Executive", "Board", "Confidential")
    .addAlarm(.email(
        description: "Board meeting tomorrow - please review materials",
        summary: "Board Meeting Reminder",
        to: ICalAttendee(email: "ceo@company.com", commonName: "CEO")
    ), trigger: .minutesBefore(1440)) // 24 hours
    .addAlarm(.display(description: "Board meeting in 30 minutes"), 
              trigger: .minutesBefore(30))
    
    .buildEvent()
```

#### Team Event with Recurrence

```swift
let teamStandup = EventBuilder(summary: "Daily Team Standup")
    .description("Quick team sync and blocker discussion")
    .location("Team Room / Virtual")
    .starts(at: nextMondayAt9AM(), timeZone: .current)
    .duration(900) // 15 minutes
    
    // Make it available time (others can schedule over if needed)
    .transparent()
    .sequence(0)
    .color("blue")
    .conference("https://meet.google.com/daily-standup")
    
    // Team coordination
    .organizer(email: "lead@team.com", name: "Team Lead")
    .addAttendee(email: "dev1@team.com", name: "Developer 1")
    .addAttendee(email: "dev2@team.com", name: "Developer 2")
    .categories("Team", "Standup", "Daily")
    
    // Recurring weekdays
    .repeatsWeekly(every: 1, on: [.monday, .tuesday, .wednesday, .thursday, .friday])
    .reminderBefore(minutes: 5)
    
    .buildEvent()
```

#### Client Event with Location Services

```swift
let clientMeeting = EventBuilder(summary: "Client Presentation")
    .description("Product demo and contract discussion")
    .location("Client Office - Downtown")
    .starts(at: Date().addingTimeInterval(3600), timeZone: .current)
    .duration(5400) // 90 minutes
    
    // Business critical - blocks time
    .confirmed()
    .highPriority()
    .opaque()
    .sequence(0)
    .color(hex: "228B22") // Green for client meetings
    
    // GPS for navigation
    .geoCoordinates(latitude: 37.7749, longitude: -122.4194)
    .attachment("proposal.pdf", mediaType: "application/pdf")
    .attachment("demo-slides.pptx", mediaType: "application/vnd.ms-powerpoint")
    
    // External participants
    .organizer(email: "sales@company.com", name: "Sales Lead")
    .addAttendee(email: "client@external.com", name: "Client Contact",
                role: .requiredParticipant, userType: .individual)
    .categories("Client", "Sales", "External")
    
    // Progressive reminders
    .addAlarm(.display(description: "Client meeting in 2 hours - prepare materials"), 
              trigger: .minutesBefore(120))
    .addAlarm(.display(description: "Client meeting in 30 minutes"), 
              trigger: .minutesBefore(30))
    
    .buildEvent()
```

#### Enterprise Event with RFC 9073 Components

```swift
let conferenceEvent = EventBuilder(summary: "Tech Conference 2024")
    .description("Annual technology conference with industry leaders")
    .starts(at: Date().addingTimeInterval(86400), timeZone: .current)
    .duration(28800) // 8 hours
    
    // Basic event properties
    .confirmed()
    .publicEvent()
    .color(hex: "2E86AB")
    .categories("Conference", "Technology", "Networking")
    
    // RFC 9073: Structured venue information
    .venue(
        name: "Grand Convention Center",
        description: "Premier conference facility with state-of-the-art technology",
        streetAddress: "123 Convention Boulevard",
        locality: "San Francisco",
        region: "CA",
        postalCode: "94102",
        country: "USA"
    )
    
    // RFC 9073: Enhanced location components
    .locationComponent(
        name: "Main Auditorium",
        description: "Primary presentation hall with 2000-person capacity",
        latitude: 37.7749,
        longitude: -122.4194,
        types: ["AUDITORIUM", "PRESENTATION"]
    )
    .locationComponent(
        name: "Exhibition Hall B",
        description: "Vendor booths and networking area",
        latitude: 37.7750,
        longitude: -122.4195,
        types: ["EXHIBITION", "NETWORKING"]
    )
    
    // RFC 9073: Resource components for equipment and facilities
    .resource(
        name: "4K Projection System",
        description: "High-resolution presentation system with wireless connectivity",
        type: "AUDIO_VISUAL",
        capacity: 2000,
        features: ["4K", "WIRELESS", "BACKUP_SYSTEM"],
        categories: ["Technology", "Presentation"]
    )
    .resource(
        name: "Live Streaming Equipment",
        description: "Professional broadcasting setup for remote attendees",
        type: "BROADCAST",
        features: ["MULTI_CAMERA", "AUDIO_MIXING", "CLOUD_RECORDING"],
        categories: ["Technology", "Remote"]
    )
    
    // Modern meeting features
    .conference("https://live.conference2024.com/main-stream")
    .attachment("conference-program.pdf", mediaType: "application/pdf")
    .attachment("speaker-bios.pdf", mediaType: "application/pdf")
    
    .buildEvent()
```

### Helper Functions

```swift
// Helper function for examples
private func nextMondayAt9AM() -> Date {
    let calendar = Calendar.current
    let now = Date()
    let nextMonday = calendar.nextDate(after: now, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime)!
    return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: nextMonday)!
}
```

### EventBuilder to iCalendar Property Mapping

EventBuilder methods generate standard iCalendar properties as specified by RFCs:

| EventBuilder Method | iCalendar Property | RFC Standard | Example Output |
|---------------------|-------------------|--------------|----------------|
| `.transparent()` | `TRANSP:TRANSPARENT` | RFC 5545 | Shows as available time |
| `.opaque()` | `TRANSP:OPAQUE` | RFC 5545 | Shows as busy time |
| `.sequence(1)` | `SEQUENCE:1` | RFC 5545 | Event version tracking |
| `.geoCoordinates(lat, lng)` | `GEO:37.7749;-122.4194` | RFC 5545 | GPS coordinates |
| `.color(hex: "FF5733")` | `COLOR:#FF5733` | RFC 7986 | Calendar theming |
| `.conference(url)` | `CONFERENCE:https://...` | RFC 7986 | Video meeting links |
| `.image(url)` | `IMAGE:https://...` | RFC 7986 | Event imagery |
| `.attachment(url, type)` | `ATTACH;FMTTYPE=pdf:https://...` | RFC 5545 | File attachments |
| `.confirmed()` | `STATUS:CONFIRMED` | RFC 5545 | Event confirmation |
| `.highPriority()` | `PRIORITY:1` | RFC 5545 | High importance |
| `.publicEvent()` | `CLASS:PUBLIC` | RFC 5545 | Access classification |
| `.organizer(email, name)` | `ORGANIZER;CN=Name:mailto:email` | RFC 5545 | Meeting organizer |
| `.categories("Work", "Meeting")` | `CATEGORIES:Work,Meeting` | RFC 5545 | Event categorization |
| `.venue(name, address)` | `VVENUE` component | RFC 9073 | Structured venue data |
| `.locationComponent(name, geo)` | `VLOCATION` component | RFC 9073 | Enhanced location details |
| `.resource(name, type, features)` | `VRESOURCE` component | RFC 9073 | Equipment and facilities |

#### Generated iCalendar Example

```swift
let event = EventBuilder(summary: "Modern Meeting")
    .transparent()
    .sequence(1)
    .color(hex: "3498DB")
    .conference("https://zoom.us/j/123")
    .attachment("agenda.pdf", mediaType: "application/pdf")
    .buildEvent()
```

### Geographic Coordinate Standardization

**Important Note**: This library has standardized on `ICalGeoCoordinate` for all geographic coordinate handling. Previous versions had two different types (`ICalGeo` and `ICalGeoCoordinate`), but we've unified on `ICalGeoCoordinate` for consistency and better functionality.

**Key Benefits of ICalGeoCoordinate:**
- ✅ **String conversion**: Built-in `stringValue` property and `init?(from string:)` parsing
- ✅ **RFC compliance**: Proper "latitude;longitude" format serialization  
- ✅ **Error handling**: Safe parsing with optional initialization
- ✅ **Consistency**: Used across all components (events, venues, locations, etc.)

**Usage Example:**
```swift
// All geographic coordinates use ICalGeoCoordinate
let event = EventBuilder(summary: "Global Meeting")
    .geoCoordinates(latitude: 37.7749, longitude: -122.4194)  // Main event location
    .venue(name: "Conference Center", ...)                     // Venue coordinates
    .locationComponent(name: "Room A", latitude: 37.7750, longitude: -122.4195)  // Room coordinates
    .buildEvent()

// All generate consistent GEO:37.774900;-122.419400 format
```

**Generated iCalendar Output:**
```
BEGIN:VEVENT
UID:unique-event-id
DTSTAMP:20240101T120000Z
SUMMARY:Modern Meeting
TRANSP:TRANSPARENT
SEQUENCE:1
COLOR:#3498DB
CONFERENCE:https://zoom.us/j/123
ATTACH;FMTTYPE=application/pdf:agenda.pdf
END:VEVENT
```

**Generated RFC 9073 Output:**
```
BEGIN:VVENUE
NAME:Conference Center
DESCRIPTION:Main conference venue
STREET-ADDRESS:123 Main Street
LOCALITY:San Francisco
REGION:CA
COUNTRY:USA
POSTALCODE:94102
GEO:37.774900;-122.419400
END:VVENUE

BEGIN:VLOCATION
NAME:Main Auditorium
DESCRIPTION:Primary presentation hall
GEO:37.774900;-122.419400
LOCATION-TYPE:AUDITORIUM,PRESENTATION
END:VLOCATION

BEGIN:VRESOURCE
NAME:4K Projection System
DESCRIPTION:Professional AV equipment
RESOURCE-TYPE:AUDIO_VISUAL
CAPACITY:2000
FEATURES:4K,WIRELESS,BACKUP_SYSTEM
CATEGORIES:Technology,Presentation
END:VRESOURCE
```

## EventBuilder Complete Feature Overview

The EventBuilder API is the primary interface for creating modern, RFC-compliant calendar events. It provides comprehensive support for all standard and extended iCalendar properties.

### Feature Comparison

| Feature Category | EventBuilder Support | RFC Standard | Generated Property |
|-----------------|---------------------|--------------|-------------------|
| **Basic Scheduling** | ✅ Complete | RFC 5545 | DTSTART, DTEND, DURATION |
| **Event Status** | ✅ Complete | RFC 5545 | STATUS, PRIORITY, CLASS |
| **Availability** | ✅ Complete | RFC 5545 | TRANSP (NEW!) |
| **Versioning** | ✅ Complete | RFC 5545 | SEQUENCE (NEW!) |
| **Location Services** | ✅ Complete | RFC 5545 | LOCATION, GEO (NEW!) |
| **Visual Theming** | ✅ Complete | RFC 7986 | COLOR, IMAGE (NEW!) |
| **Modern Meetings** | ✅ Complete | RFC 7986 | CONFERENCE, ATTACH (NEW!) |
| **RFC 9073 Components** | ✅ Complete | RFC 9073 | VVENUE, VLOCATION, VRESOURCE (NEW!) |
| **Participants** | ✅ Complete | RFC 5545 | ORGANIZER, ATTENDEE |
| **Recurrence** | ✅ Complete | RFC 5545 | RRULE, EXDATE |
| **Alarms** | ✅ Complete | RFC 5545 | VALARM components |

### Migration from Manual Properties

**Before (Manual Property Setting):**
```swift
// Old approach - error prone and verbose
var event = ICalEvent(summary: "Meeting")
event.properties.append(ICalProperty(name: "TRANSP", value: "TRANSPARENT"))
event.properties.append(ICalProperty(name: "GEO", value: "37.7749;-122.4194"))
event.properties.append(ICalProperty(name: "COLOR", value: "#FF5733"))
```

**After (EventBuilder API):**
```swift
// New approach - type-safe and intuitive
let event = EventBuilder(summary: "Meeting")
    .transparent()
    .geoCoordinates(latitude: 37.7749, longitude: -122.4194)
    .color(hex: "FF5733")
    .buildEvent()
```

### Parsing and Working with External Calendars

```swift
// Parse an external calendar
let icsContent = """
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//External//Calendar//EN
METHOD:PUBLISH
BEGIN:VEVENT
UID:external-event-123
DTSTAMP:20240101T120000Z
DTSTART:20240101T140000Z
DTEND:20240101T150000Z
SUMMARY:External Meeting
LOCATION:Remote Office
END:VEVENT
END:VCALENDAR
"""

let externalCalendar = try ICalendarKit.parseCalendar(from: icsContent)
print("Found \(externalCalendar.events.count) events")

// Find specific events
let todayEvents = ICalendarKit.findEvents(
    in: externalCalendar,
    from: Calendar.current.startOfDay(for: Date()),
    to: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
)

// Get calendar statistics
let stats = ICalendarKit.getCalendarStatistics(externalCalendar)
print("Calendar has \(stats.eventCount) events, \(stats.eventsWithAlarms) with alarms")
```

## Topics

### Core Components

- ``ICalendar`` - Core calendar container
- ``CalendarBuilder`` - Result builder for creating calendars
- ``EventBuilder`` - Result builder for creating events
- ``ICalEvent`` - Calendar events
- ``ICalTodo`` - Task/todo items
- ``ICalJournal`` - Journal entries

### Timezone Support

- ``ICalTimeZone``
- ``ICalDateTime``
- Creating timezone-aware events
- Handling daylight saving time transitions

### Calendar Feeds and Subscriptions

- Creating public calendar feeds
- Subscription management
- HTTP headers for calendar feeds
- Multi-timezone coordination

### Email Integration

- ``ICalEmailTransport``
- Meeting invitations (iTIP REQUEST)
- RSVP responses (iTIP REPLY)
- Meeting cancellations (iTIP CANCEL)
- MIME email generation

### Recurrence and Patterns

- ``ICalRecurrenceRule``
- ``ICalRecurrenceFrequency``
- Complex recurrence patterns
- Non-Gregorian calendar support

### Advanced Features

- RFC 7986 extensions (COLOR, IMAGE, CONFERENCE)
- X-WR properties for calendar clients
- Structured data embedding
- Enhanced location information

### VCard Support

For comprehensive vCard documentation, see ``VCard``.

- ``VCardClient``
- ``VCard``
- ``VCardName``
- ``VCardAddress``
- ``VCardOrganization``
- Contact management and address books
- RFC 6350 compliance
- Multiple vCard versions (2.1, 3.0, 4.0)

### Parsing and Serialization

- ``ICalendarParser``
- ``ICalendarSerializer``
- ``VCardParser``
- ``VCardSerializer``
- Error handling and validation
- Multiple output formats

## Example Applications

### Calendar Feed Server

#### Vapor Example

Create a server endpoint that provides calendar feeds:

```swift
import Vapor
import ICalendar

func calendarFeed(req: Request) async throws -> Response {
    let client = ICalendarClient()
    var calendar = client.createCalendar(
        name: "Public Events",
        description: "Subscribe to our public events"
    )

    // Add events from your data source
    let events = try await loadEventsFromDatabase()
    events.forEach { calendar.addEvent($0) }

    let icsContent = try client.export(calendar)

    let response = Response(status: .ok, body: .init(string: icsContent))
    response.headers.add(name: .contentType, value: "text/calendar; charset=utf-8")
    response.headers.add(name: "Cache-Control", value: "public, max-age=3600")

    return response
}
```

#### Hummingbird 2.0 Example

Create calendar feeds using Hummingbird 2.0's modern async/await API:

```swift
import Hummingbird
import ICalendar

struct CalendarService: Sendable {
    let client = ICalendarClient()

    func createPublicCalendar() async throws -> ICalendar {
        var calendar = client.createCalendar(
            name: "Public Events",
            description: "Subscribe to our public events"
        )

        // Add events from your data source
        let events = try await loadEventsFromDatabase()
        events.forEach { calendar.addEvent($0) }

        return calendar
    }
}

// Configure router
let router = Router()
let calendarService = CalendarService()

router.get("/calendar/events.ics") { request, context in
    let calendar = try await calendarService.createPublicCalendar()
    let icsContent = try calendarService.client.export(calendar)

    return Response(
        status: .ok,
        headers: HTTPFields([
            .contentType: "text/calendar; charset=utf-8",
            .cacheControl: "public, max-age=3600",
            .contentDisposition: "attachment; filename=events.ics"
        ]),
        body: .init(byteBuffer: ByteBuffer(string: icsContent))
    )
}

// Calendar subscription with context-aware features
router.get("/calendar/:calendarType/events.ics") { request, context in
    guard let calendarType = request.parameters.get("calendarType") else {
        throw HTTPError(.badRequest)
    }

    let calendarContext: ICalendarContext = switch calendarType {
    case "hebrew": .hebrew
    case "islamic": .islamic
    case "chinese": .chinese
    default: .default
    }

    var calendar = calendarService.client.createCalendar(
        name: "\(calendarType.capitalized) Calendar",
        context: calendarContext
    )

    // Add context-appropriate events
    let events = try await loadEventsForCalendarType(calendarType)
    events.forEach { calendar.addEvent($0) }

    let icsContent = try calendarService.client.export(calendar)

    return Response(
        status: .ok,
        headers: HTTPFields([
            .contentType: "text/calendar; charset=utf-8",
            .cacheControl: "public, max-age=1800"
        ]),
        body: .init(byteBuffer: ByteBuffer(string: icsContent))
    )
}

// Meeting invitation endpoint
router.post("/calendar/invite") { request, context in
    struct InviteRequest: Codable {
        let organizer: String
        let attendees: [String]
        let summary: String
        let startDate: Date
        let endDate: Date
        let location: String?
        let description: String?
    }

    let invite = try await request.decode(as: InviteRequest.self, context: context)

    let invitation = calendarService.client.createMeetingInvitation(
        summary: invite.summary,
        startDate: invite.startDate,
        endDate: invite.endDate,
        location: invite.location,
        description: invite.description,
        organizer: ICalAttendee(email: invite.organizer),
        attendees: invite.attendees.map { ICalAttendee(email: $0) }
    )

    let icsContent = try calendarService.client.export(invitation)

    return Response(
        status: .ok,
        headers: [
            .contentType: "text/calendar; charset=utf-8; method=REQUEST",
        ],
        body: .init(byteBuffer: ByteBuffer(string: icsContent))
    )
}
```

### Email Calendar Invitations

Send meeting invitations that automatically integrate with email clients:

```swift
func sendMeetingInvitation(
    organizer: String,
    attendees: [String],
    subject: String,
    startDate: Date,
    endDate: Date
) -> String {
    let client = ICalendarClient()
    var calendar = client.createCalendar()
    calendar.method = "REQUEST"  // iTIP method

    var event = client.createEvent(
        summary: subject,
        startDate: startDate,
        endDate: endDate,
        timeZone: TimeZone.current
    )

    event.organizer = "MAILTO:\(organizer)"

    // Add attendees
    for attendee in attendees {
        let attendeeProperty = ICalProperty(
            name: "ATTENDEE",
            value: "MAILTO:\(attendee)",
            parameters: [
                "ROLE": "REQ-PARTICIPANT",
                "PARTSTAT": "NEEDS-ACTION",
                "RSVP": "TRUE"
            ]
        )
        event.properties.append(attendeeProperty)
    }

    calendar.addEvent(event)
    return try! client.export(calendar)
}
```

### Multi-Timezone Calendar

Create calendars that work across global offices:

```swift
func createGlobalOfficeCalendar() -> ICalendar {
    let client = ICalendarClient()
    var calendar = client.createCalendar(
        name: "Global Operations",
        timeZone: "UTC"
    )

    // Add timezone definitions
    let offices = [
        ("New York", "America/New_York"),
        ("London", "Europe/London"),
        ("Tokyo", "Asia/Tokyo")
    ]

    for (city, timezoneId) in offices {
        guard let timeZone = TimeZone(identifier: timezoneId) else { continue }

        // Create VTIMEZONE component
        let vtimezone = ICalTimeZone(timeZoneId: timezoneId)
        vtimezone.timeZoneUrl = client.generateTZURL(for: timeZone)
        calendar.addTimeZone(vtimezone)

        // Add office-specific events
        let officeEvent = client.createEvent(
            summary: "\(city) All-Hands",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "\(city) Office",
            timeZone: timeZone
        )

        calendar.addEvent(officeEvent)
    }

    return calendar
}
```

## Performance and Best Practices

### Memory Management

The library is designed for efficiency with large calendars:

- All types conform to `Sendable` for Swift 6 concurrency
- Lazy property evaluation minimizes memory usage
- Stream-friendly parsing for large calendar files

### Timezone Best Practices

1. **Always specify timezones** for events that will be shared across geographic locations
2. **Use VTIMEZONE components** for proper DST handling
3. **Validate timezone identifiers** before creating events
4. **Consider floating time** only for events that should appear at the same local time everywhere

### Calendar Feed Optimization

1. **Set appropriate cache headers** to reduce server load
2. **Use ETags** for conditional requests
3. **Implement pagination** for large event sets
4. **Filter by date range** to minimize bandwidth

### Error Handling

The library provides comprehensive error handling:

```swift
do {
    let calendar = try client.parseCalendar(from: icsContent)
    // Process calendar
} catch let error as ICalendarError {
    switch error {
    case .invalidFormat(let details):
        print("Invalid calendar format: \(details)")
    case .missingRequiredProperty(let property):
        print("Missing required property: \(property)")
    case .invalidDateTime(let dateString):
        print("Invalid date/time: \(dateString)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

## Platform Support

- **iOS 18.0+**
- **macOS 15.0+**
- **Server-side Swift** (Ubuntu, CentOS, Amazon Linux)

## Related RFCs

The library implements the following standards:

- **RFC 5545**: Internet Calendaring and Scheduling Core Object Specification (iCalendar)
- **RFC 5546**: iCalendar Transport-Independent Interoperability Protocol (iTIP)
- **RFC 6047**: iCalendar Message-Based Interoperability Protocol (iMIP)
- **RFC 6321**: xCal: The XML Format for iCalendar
- **RFC 6868**: Parameter Value Encoding in iCalendar and vCard
- **RFC 7265**: jCal: The JSON Format for iCalendar
- **RFC 7529**: Non-Gregorian Recurrence Rules in iCalendar
- **RFC 7808**: Time Zone Data Distribution Service
- **RFC 7953**: Calendar Availability
- **RFC 7986**: New Properties for iCalendar
- **RFC 9073**: Event Publishing Extensions to iCalendar
- **RFC 9074**: VALARM Extensions for iCalendar
- **RFC 9253**: Support for iCalendar Relationships

## Community and Support

- **Issues**: Report bugs and feature requests on GitHub
- **Documentation**: Comprehensive documentation and examples included
- **Examples**: Complete example applications demonstrating all features
- **Testing**: Extensive test suite ensuring RFC compliance

## VCard Contact Management

The library includes comprehensive vCard (RFC 6350) support for contact and address book management, seamlessly integrating with calendar functionality.

### Basic VCard Usage

Create and manage contacts using the high-level ``VCardClient`` interface:

```swift
import ICalendar

let client = VCardClient()

// Create a personal contact
var person = client.createPersonVCard(
    formattedName: "John Doe",
    familyName: "Doe",
    givenName: "John"
)

// Add contact information
person.emailAddresses = ["john.doe@example.com", "john@personal.com"]
person.phoneNumbers = ["+1-555-123-4567"]
person.addresses = [
    VCardAddress(
        streetAddress: "123 Main Street",
        locality: "Anytown",
        region: "CA",
        postalCode: "12345",
        country: "USA",
        label: "Home"
    )
]

// Export to vCard format
let vcfContent = try client.serializeVCard(person)
```

### Organization Contacts

Create organizational contacts with structured information:

```swift
// Create an organization contact
var organization = client.createOrganizationVCard(
    organizationName: "Acme Corporation",
    organizationalUnits: ["Engineering", "iOS Team"]
)

organization.emailAddresses = ["contact@acme.com"]
organization.phoneNumbers = ["+1-555-987-6543"]
organization.url = "https://acme.com"

// Add a contact person within the organization
var contactPerson = client.createPersonVCard(
    formattedName: "Jane Smith",
    familyName: "Smith",
    givenName: "Jane"
)
contactPerson.title = "Engineering Manager"
contactPerson.organization = VCardOrganization(
    organizationName: "Acme Corporation",
    organizationalUnits: ["Engineering"]
)
```

### VCard Groups and Distribution Lists

Create group contacts for mailing lists and distribution groups:

```swift
// Create a group contact
var team = client.createGroupVCard(
    groupName: "iOS Development Team",
    members: [
        "mailto:john@acme.com",
        "mailto:jane@acme.com",
        "mailto:bob@acme.com"
    ]
)

team.emailAddresses = ["ios-team@acme.com"]
team.note = "Main iOS development team distribution list"
```

### Parsing and Managing VCard Collections

```swift
// Parse multiple vCards from a file or string
let vcfFileContent = """
BEGIN:VCARD
VERSION:4.0
FN:John Doe
N:Doe;John;;;
EMAIL:john@example.com
END:VCARD

BEGIN:VCARD
VERSION:4.0
FN:Jane Smith
N:Smith;Jane;;;
EMAIL:jane@example.com
END:VCARD
"""

let contacts = try client.parseVCards(from: vcfFileContent)

// Filter and search contacts
let johnContacts = contacts.filter {
    $0.formattedName?.contains("John") ?? false
}

// Export all contacts
let allContactsVCF = try client.serializeVCards(contacts)
```

### Address Book Integration Examples

#### Create Employee Directory

```swift
func createEmployeeDirectory() -> [VCard] {
    let client = VCardClient()
    var employees: [VCard] = []

    let employeeData = [
        ("John Doe", "Engineering", "john@company.com"),
        ("Jane Smith", "Design", "jane@company.com"),
        ("Bob Johnson", "Marketing", "bob@company.com")
    ]

    for (name, department, email) in employeeData {
        let nameParts = name.split(separator: " ")
        var employee = client.createPersonVCard(
            formattedName: name,
            familyName: String(nameParts.last ?? ""),
            givenName: String(nameParts.first ?? "")
        )

        employee.organization = VCardOrganization(
            organizationName: "My Company",
            organizationalUnits: [department]
        )
        employee.emailAddresses = [email]
        employee.title = "\(department) Specialist"

        employees.append(employee)
    }

    return employees
}
```

#### Customer Contact Management

```swift
func createCustomerContact(
    name: String,
    company: String,
    email: String,
    phone: String,
    address: String
) -> VCard {
    let client = VCardClient()

    let nameParts = name.split(separator: " ")
    var customer = client.createPersonVCard(
        formattedName: name,
        familyName: String(nameParts.last ?? ""),
        givenName: String(nameParts.first ?? "")
    )

    customer.organization = VCardOrganization(organizationName: company)
    customer.emailAddresses = [email]
    customer.phoneNumbers = [phone]

    // Parse address components (simplified)
    let addressComponents = address.split(separator: ",")
    if addressComponents.count >= 4 {
        customer.addresses = [
            VCardAddress(
                streetAddress: String(addressComponents[0]).trimmingCharacters(in: .whitespaces),
                locality: String(addressComponents[1]).trimmingCharacters(in: .whitespaces),
                region: String(addressComponents[2]).trimmingCharacters(in: .whitespaces),
                postalCode: String(addressComponents[3]).trimmingCharacters(in: .whitespaces),
                country: "USA",
                label: "Work"
            )
        ]
    }

    customer.note = "Customer contact created: \(Date().formatted())"
    return customer
}
```

### Server-Side VCard Integration

#### Hummingbird VCard API

```swift
import Hummingbird
import ICalendar

struct ContactService: Sendable {
    let client = VCardClient()

    func getAllContacts() async throws -> [VCard] {
        // Load from database or storage
        return try await loadContactsFromDatabase()
    }
}

// Configure router for VCard endpoints
let contactService = ContactService()

router.get("/contacts") { request, context in
    let contacts = try await contactService.getAllContacts()
    let vcfContent = try contactService.client.serializeVCards(contacts)

    return Response(
        status: .ok,
        headers: HTTPFields([
            .contentType: "text/vcard; charset=utf-8",
            .contentDisposition: "attachment; filename=contacts.vcf"
        ]),
        body: .init(byteBuffer: ByteBuffer(string: vcfContent))
    )
}

router.get("/contacts/:id/vcard") { request, context in
    guard let contactId = request.parameters.get("id") else {
        throw HTTPError(.badRequest)
    }

    let contact = try await contactService.getContact(id: contactId)
    let vcfContent = try contactService.client.serializeVCard(contact)

    return Response(
        status: .ok,
        headers: HTTPFields([
            .contentType: "text/vcard; charset=utf-8",
            .contentDisposition: "attachment; filename=contact.vcf"
        ]),
        body: .init(byteBuffer: ByteBuffer(string: vcfContent))
    )
}
```

#### Vapor VCard Integration

```swift
import Vapor
import ICalendar

func vCardRoutes(app: Application) throws {
    let client = VCardClient()

    app.get("contacts", "export") { req async throws -> Response in
        let contacts = try await loadAllContacts()
        let vcfContent = try client.serializeVCards(contacts)

        let response = Response(status: .ok, body: .init(string: vcfContent))
        response.headers.add(name: .contentType, value: "text/vcard; charset=utf-8")
        response.headers.add(name: "Content-Disposition", value: "attachment; filename=contacts.vcf")

        return response
    }

    app.post("contacts", "import") { req async throws -> HTTPStatus in
        let vcfContent = try req.content.decode(String.self)
        let importedContacts = try client.parseVCards(from: vcfContent)

        try await saveContactsToDatabase(importedContacts)
        return .created
    }
}
```

### VCard Best Practices

#### Version Management

```swift
// Create vCard with specific version
let v3Contact = client.createVCard(formattedName: "John Doe", version: .v3_0)
let v4Contact = client.createVCard(formattedName: "Jane Smith", version: .v4_0)

// Configure client for specific version
let v3Client = VCardClient(configuration: .init(defaultVersion: .v3_0))
let modernClient = VCardClient(configuration: .init(defaultVersion: .v4_0))
```

#### Data Validation

```swift
// Strict validation for enterprise use
let strictClient = VCardClient(configuration: .strict)

// Permissive parsing for legacy data
let permissiveClient = VCardClient(configuration: .permissive)
```

#### Photo and Avatar Support

```swift
// Add photo from URL
person.photo = "https://example.com/photos/john-doe.jpg"

// Add photo as base64 data (for vCard 3.0 compatibility)
let imageData = try Data(contentsOf: photoURL)
let base64Photo = imageData.base64EncodedString()
person.photo = "data:image/jpeg;base64,\(base64Photo)"
```
