# ``ICalendar``

A comprehensive Swift library for parsing, creating, and managing iCalendar (RFC 5545) data with full timezone support and enterprise features.

## Overview

iCalendar Kit is a modern, Swift 6-compliant library that provides complete support for the iCalendar specification and its extensions. Built for enterprise applications, it offers robust timezone handling, calendar feed generation, email integration, and comprehensive RFC compliance.

### Key Features

- **RFC Compliance**: Full support for RFC 5545, RFC 7986, RFC 6868, RFC 7808, and many other iCalendar-related specifications
- **Enterprise Ready**: Production-ready with comprehensive timezone handling and calendar feed support
- **Email Integration**: Built-in iTIP/iMIP support for calendar invitations and responses
- **Swift 6 Compatible**: Built with modern Swift concurrency and sendable conformance
- **Cross-Platform**: Works on iOS, macOS, and server-side Swift

## Getting Started

### Basic Usage

Create and work with calendar events using the new result builder syntax in version 2.0:

```swift
import ICalendar

// Create a calendar with events using CalendarBuilder result builder
// Using the new CalendarBuilder result builder syntax
let calendar = ICalendar.calendar(productId: "-//My App//EN") {
    CalendarName("My Calendar")
    CalendarDescription("Personal calendar events")
    CalendarMethod("PUBLISH")
    
    ICalendarFactory.createEvent(
        summary: "Team Meeting",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600),
        location: "Conference Room A",
        description: "Weekly team sync meeting"
    )
}

// Export to iCalendar format
let icsContent = try ICalendarKit.serializeCalendar(calendar)
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

### Using EventBuilder for Complex Events

Create multiple events with rich properties using the EventBuilder result builder:

```swift
// Create events using EventBuilder
let events = EventBuilder {
    EventBuilder(summary: "Daily Standup")
        .startDate(Date())
        .duration(ICalendarFactory.createDuration(minutes: 30))
        .location("Virtual - Zoom")
        .description("Daily team standup meeting")
        .recurrence(ICalendarFactory.createDailyRecurrence(count: 30))
        .addAlarm(ICalendarFactory.createDisplayAlarm(description: "Meeting in 15 minutes", triggerMinutesBefore: 15))
    
    EventBuilder(summary: "Project Planning")
        .startDate(Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        .duration(ICalendarFactory.createDuration(hours: 2))
        .location("Conference Room B")
        .attendees([
            ICalendarFactory.createAttendee(email: "alice@company.com", name: "Alice", role: .requiredParticipant),
            ICalendarFactory.createAttendee(email: "bob@company.com", name: "Bob", role: .optionalParticipant)
        ])
        .organizer(ICalendarFactory.createOrganizer(email: "manager@company.com", name: "Team Manager"))
}

// Create calendar with branded configuration
let calendar = ICalendar.calendar(productId: "-//My Company//Project Calendar//EN") {
    BrandedCalendar(
        organizationName: "My Company",
        organizationURL: "https://company.com",
        brandColor: "#0066CC"
    )
    
    for event in events {
        event
    }
}
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
