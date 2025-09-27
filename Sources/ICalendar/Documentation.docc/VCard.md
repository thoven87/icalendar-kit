# ``VCard``

Comprehensive vCard (RFC 6350) support for contact and address book management with seamless calendar integration.

## Overview

The VCard module provides complete support for the vCard specification (RFC 6350), enabling robust contact management, address book functionality, and seamless integration with calendar systems. Built with Swift 6 concurrency and sendable conformance, it's designed for both client-side applications and server-side contact management services.

### Key Features

- **RFC 6350 Compliance**: Full support for vCard 2.1, 3.0, and 4.0 specifications
- **Swift 6 Compatible**: Built with modern Swift concurrency and sendable conformance
- **Contact Types**: Support for individuals, organizations, groups, and distribution lists
- **Comprehensive Properties**: Names, addresses, phone numbers, emails, photos, and more
- **Calendar Integration**: Seamless interoperability with iCalendar events and attendees
- **Server-Ready**: Built for enterprise contact management and directory services

## Getting Started

### Basic Contact Creation

Create and manage contacts using the high-level ``VCardClient`` interface:

```swift
import ICalendar

let client = VCardClient()

// Create a personal contact
var contact = client.createPersonVCard(
    formattedName: "Dr. Sarah Johnson",
    familyName: "Johnson",
    givenName: "Sarah",
    prefix: "Dr."
)

// Add comprehensive contact information
contact.emailAddresses = [
    "sarah.johnson@hospital.com",
    "sarah@personal.email"
]

contact.phoneNumbers = [
    "+1-555-123-4567",  // Primary
    "+1-555-987-6543"   // Mobile
]

contact.addresses = [
    VCardAddress(
        streetAddress: "123 Medical Plaza",
        locality: "San Francisco",
        region: "CA",
        postalCode: "94102",
        country: "USA",
        label: "Work"
    ),
    VCardAddress(
        streetAddress: "456 Home Street",
        locality: "San Francisco",
        region: "CA",
        postalCode: "94110",
        country: "USA",
        label: "Home"
    )
]

contact.title = "Chief Medical Officer"
contact.organization = VCardOrganization(
    organizationName: "SF General Hospital",
    organizationalUnits: ["Emergency Medicine", "Administration"]
)

// Export to vCard format
let vcfContent = try client.serializeVCard(contact)
```

## Topics

### Core Components

- ``VCardClient``
- ``VCard``
- ``VCardProperty``
- ``VCardVersion``

### Contact Information

- ``VCardName``
- ``VCardAddress``
- ``VCardOrganization``
- ``VCardKind``

### Parsing and Serialization

- ``VCardParser``
- ``VCardSerializer``
- ``VCardFormatter``

### Utilities and Extensions

- ``VCardUtilities``
- Contact searching and filtering
- Bulk import/export operations

## Contact Types

### Individual Contacts

Create detailed personal contact records:

```swift
let client = VCardClient()

var person = client.createPersonVCard(
    formattedName: "Maria Elena Rodriguez-Smith",
    familyName: "Rodriguez-Smith",
    givenName: "Maria",
    middleName: "Elena"
)

// Add detailed personal information
person.nicknames = ["Mari", "Elena"]
person.birthday = "1985-03-15"
person.gender = "F"
person.languages = ["en", "es", "fr"]

// Professional information
person.title = "Senior Software Engineer"
person.role = "iOS Development Lead"
person.organization = VCardOrganization(
    organizationName: "TechCorp Inc.",
    organizationalUnits: ["Mobile Engineering", "iOS Team"]
)

// Contact methods with preferences
person.emailAddresses = [
    "maria.rodriguez@techcorp.com",    // Work (preferred)
    "maria.elena@personal.com"        // Personal
]

person.phoneNumbers = [
    "+1-555-200-1234",  // Work
    "+1-555-200-5678",  // Mobile
    "+1-555-200-9999"   // Home
]

// Social and web presence
person.url = "https://maria-elena.dev"
person.socialProfiles = [
    "https://github.com/maria-elena",
    "https://linkedin.com/in/maria-rodriguez-smith"
]

// Notes and categories
person.note = "Expert in iOS development and Swift. Speaks fluent English, Spanish, and French."
person.categories = ["Colleague", "iOS Expert", "Team Lead"]
```

### Organization Contacts

Manage company and institutional contacts:

```swift
var company = client.createOrganizationVCard(
    organizationName: "Global Tech Solutions",
    organizationalUnits: ["Sales", "Customer Success"]
)

company.emailAddresses = [
    "info@globaltech.com",
    "sales@globaltech.com",
    "support@globaltech.com"
]

company.phoneNumbers = [
    "+1-800-555-TECH",  // Main
    "+1-555-123-SALES", // Sales
    "+1-555-123-HELP"   // Support
]

company.addresses = [
    VCardAddress(
        streetAddress: "1000 Innovation Drive\nSuite 200",
        locality: "Silicon Valley",
        region: "CA",
        postalCode: "94000",
        country: "USA",
        label: "Corporate HQ"
    ),
    VCardAddress(
        streetAddress: "500 Tech Park Lane",
        locality: "Austin",
        region: "TX",
        postalCode: "78701",
        country: "USA",
        label: "Development Center"
    )
]

company.url = "https://globaltech.com"
company.note = "Leading provider of enterprise technology solutions"
company.categories = ["Technology", "B2B", "Enterprise"]
```

### Group Contacts and Distribution Lists

Create groups for teams, mailing lists, and distribution groups:

```swift
var teamGroup = client.createGroupVCard(
    groupName: "iOS Development Team",
    members: [
        "mailto:maria@techcorp.com",
        "mailto:john@techcorp.com",
        "mailto:sarah@techcorp.com",
        "mailto:mike@techcorp.com"
    ]
)

teamGroup.emailAddresses = ["ios-team@techcorp.com"]
teamGroup.note = "Main iOS development team - all hands meetings Fridays at 3pm"
teamGroup.categories = ["Team", "Development", "iOS"]

// Create project-specific group
var projectGroup = client.createGroupVCard(
    groupName: "Project Phoenix Team",
    members: [
        "mailto:alice@techcorp.com",
        "mailto:bob@techcorp.com",
        "mailto:charlie@externalparter.com"
    ]
)

projectGroup.emailAddresses = ["phoenix-project@techcorp.com"]
projectGroup.note = "Project Phoenix development team including external partners"
projectGroup.categories = ["Project", "Confidential"]
```

## Advanced Features

### Multiple vCard Versions

Handle different vCard versions for compatibility:

```swift
// Create vCard 4.0 (modern, feature-rich)
let modernClient = VCardClient(configuration: .init(defaultVersion: .v4_0))
var modernContact = modernClient.createPersonVCard(formattedName: "John Doe")
modernContact.gender = "M"
modernContact.languages = ["en", "fr"]

// Create vCard 3.0 (broad compatibility)
let compatibleClient = VCardClient(configuration: .init(defaultVersion: .v3_0))
var compatibleContact = compatibleClient.createPersonVCard(formattedName: "Jane Smith")

// Create vCard 2.1 (legacy systems)
let legacyClient = VCardClient(configuration: .init(defaultVersion: .v2_1))
var legacyContact = legacyClient.createPersonVCard(formattedName: "Bob Johnson")
```

### Photo and Avatar Management

Handle contact photos across different vCard versions:

```swift
// URL-based photos (preferred for vCard 4.0)
contact.photo = "https://example.com/photos/john-doe.jpg"

// Base64 embedded photos (for compatibility)
if let photoData = UIImage(named: "contact-photo")?.jpegData(compressionQuality: 0.8) {
    let base64Photo = photoData.base64EncodedString()
    contact.photo = "data:image/jpeg;base64,\(base64Photo)"
}

// Handle multiple photo formats
contact.photos = [
    "https://example.com/photos/john-large.jpg",    // High resolution
    "https://example.com/photos/john-thumb.jpg",    // Thumbnail
    "data:image/jpeg;base64,\(thumbnailBase64)"     // Embedded thumbnail
]
```

### Bulk Operations

Efficiently handle large contact datasets:

```swift
// Parse large vCard files
let vcfFileContent = try String(contentsOfFile: "contacts.vcf")
let allContacts = try client.parseVCards(from: vcfFileContent)

// Process contacts in batches
let batchSize = 100
for batch in allContacts.chunked(into: batchSize) {
    try await processContactBatch(batch)
}

// Export with custom formatting
let exportedVCF = try client.serializeVCards(
    allContacts,
    options: VCardSerializer.SerializationOptions(
        version: .v4_0,
        prettyPrint: true,
        validateBeforeSerializing: true
    )
)
```

### Contact Search and Filtering

Implement powerful contact search functionality:

```swift
extension Array where Element == VCard {
    func findByName(_ searchTerm: String) -> [VCard] {
        return filter { contact in
            let formattedName = contact.formattedName?.lowercased() ?? ""
            let familyName = contact.name?.familyNames.joined().lowercased() ?? ""
            let givenName = contact.name?.givenNames.joined().lowercased() ?? ""

            let term = searchTerm.lowercased()
            return formattedName.contains(term) ||
                   familyName.contains(term) ||
                   givenName.contains(term)
        }
    }

    func findByEmail(_ email: String) -> [VCard] {
        return filter { contact in
            contact.emailAddresses.contains { $0.lowercased() == email.lowercased() }
        }
    }

    func findByOrganization(_ orgName: String) -> [VCard] {
        return filter { contact in
            contact.organization?.organizationName.lowercased().contains(orgName.lowercased()) ?? false
        }
    }

    func findByCategory(_ category: String) -> [VCard] {
        return filter { contact in
            contact.categories.contains { $0.lowercased() == category.lowercased() }
        }
    }
}

// Usage examples
let salesContacts = allContacts.findByCategory("Sales")
let techCorpEmployees = allContacts.findByOrganization("TechCorp")
let johnDoeContacts = allContacts.findByName("John Doe")
```

## Calendar Integration

### Converting Between Contacts and Attendees

Seamlessly integrate vCard contacts with iCalendar events:

```swift
extension VCard {
    func toICalAttendee() -> ICalAttendee? {
        guard let email = emailAddresses.first else { return nil }

        return ICalAttendee(
            email: email,
            commonName: formattedName,
            role: .requiredParticipant,
            participationStatus: .needsAction,
            rsvp: true
        )
    }
}

extension ICalAttendee {
    func toVCard() -> VCard {
        let client = VCardClient()
        var contact = client.createPersonVCard(formattedName: commonName ?? email)
        contact.emailAddresses = [email]
        return contact
    }
}

// Create event with contacts as attendees
let client = ICalendarClient()
let contacts = try VCardClient().parseVCards(from: vcfContent)

var event = client.createEvent(
    summary: "Team Meeting",
    startDate: Date(),
    endDate: Date().addingTimeInterval(3600)
)

// Convert contacts to attendees
event.attendees = contacts.compactMap { $0.toICalAttendee() }

// Create calendar and add event
var calendar = client.createCalendar()
calendar.addEvent(event)
```

### Contact-Based Event Creation

```swift
func createMeetingWithContacts(
    title: String,
    startDate: Date,
    duration: TimeInterval,
    organizer: VCard,
    attendees: [VCard],
    location: String? = nil
) -> ICalendar {

    let iCalClient = ICalendarClient()
    var calendar = iCalClient.createCalendar()

    var event = iCalClient.createEvent(
        summary: title,
        startDate: startDate,
        endDate: startDate.addingTimeInterval(duration),
        location: location
    )

    // Set organizer from vCard
    if let organizerEmail = organizer.emailAddresses.first {
        event.organizer = organizerEmail
    }

    // Convert attendees
    event.attendees = attendees.compactMap { contact in
        guard let email = contact.emailAddresses.first else { return nil }
        return ICalAttendee(
            email: email,
            commonName: contact.formattedName,
            role: .requiredParticipant,
            participationStatus: .needsAction,
            rsvp: true
        )
    }

    calendar.addEvent(event)
    return calendar
}
```

## Server-Side Implementation

### RESTful Contact API

Create a comprehensive contact management API:

```swift
import Hummingbird
import ICalendar

struct ContactAPI {
    let client = VCardClient()

    func configureRoutes(_ router: Router<some RequestContext>) {

        // Get all contacts
        router.get("/contacts") { request, context in
            let contacts = try await loadContactsFromDatabase()
            let vcfContent = try client.serializeVCards(contacts)

            return Response(
                status: .ok,
                headers: HTTPFields([
                    .contentType: "text/vcard; charset=utf-8"
                ]),
                body: .init(byteBuffer: ByteBuffer(string: vcfContent))
            )
        }

        // Get specific contact
        router.get("/contacts/:id") { request, context in
            guard let contactId = request.parameters.get("id") else {
                throw HTTPError(.badRequest)
            }

            let contact = try await getContact(id: contactId)
            let vcfContent = try client.serializeVCard(contact)

            return Response(
                status: .ok,
                headers: HTTPFields([
                    .contentType: "text/vcard; charset=utf-8"
                ]),
                body: .init(byteBuffer: ByteBuffer(string: vcfContent))
            )
        }

        // Create new contact
        router.post("/contacts") { request, context in
            let vcfContent = try await request.body.collect(upTo: .max)
            let newContact = try client.parseVCard(from: String(buffer: vcfContent))

            let savedContact = try await saveContactToDatabase(newContact)
            let responseVCF = try client.serializeVCard(savedContact)

            return Response(
                status: .created,
                headers: HTTPFields([
                    .contentType: "text/vcard; charset=utf-8"
                ]),
                body: .init(byteBuffer: ByteBuffer(string: responseVCF))
            )
        }

        // Update existing contact
        router.put("/contacts/:id") { request, context in
            guard let contactId = request.parameters.get("id") else {
                throw HTTPError(.badRequest)
            }

            let vcfContent = try await request.body.collect(upTo: .max)
            var updatedContact = try client.parseVCard(from: String(buffer: vcfContent))

            let savedContact = try await updateContactInDatabase(id: contactId, contact: updatedContact)
            let responseVCF = try client.serializeVCard(savedContact)

            return Response(
                status: .ok,
                headers: HTTPFields([
                    .contentType: "text/vcard; charset=utf-8"
                ]),
                body: .init(byteBuffer: ByteBuffer(string: responseVCF))
            )
        }

        // Delete contact
        router.delete("/contacts/:id") { request, context in
            guard let contactId = request.parameters.get("id") else {
                throw HTTPError(.badRequest)
            }

            try await deleteContactFromDatabase(id: contactId)
            return Response(status: .noContent)
        }

        // Search contacts
        router.get("/contacts/search") { request, context in
            let query = request.uri.queryParameters["q"] ?? ""
            let contacts = try await searchContactsInDatabase(query: query)
            let vcfContent = try client.serializeVCards(contacts)

            return Response(
                status: .ok,
                headers: HTTPFields([
                    .contentType: "text/vcard; charset=utf-8"
                ]),
                body: .init(byteBuffer: ByteBuffer(string: vcfContent))
            )
        }

        // Bulk import
        router.post("/contacts/import") { request, context in
            let vcfContent = try await request.body.collect(upTo: .max)
            let importedContacts = try client.parseVCards(from: String(buffer: vcfContent))

            let savedContacts = try await saveContactsToDatabase(importedContacts)

            return Response(
                status: .ok,
                headers: HTTPFields([
                    .contentType: "application/json"
                ]),
                body: .init(byteBuffer: ByteBuffer(string: """
                    {"imported": \(savedContacts.count), "status": "success"}
                """))
            )
        }

        // Export specific groups
        router.get("/contacts/groups/:group/export") { request, context in
            guard let groupName = request.parameters.get("group") else {
                throw HTTPError(.badRequest)
            }

            let groupContacts = try await getContactsByCategory(category: groupName)
            let vcfContent = try client.serializeVCards(groupContacts)

            return Response(
                status: .ok,
                headers: HTTPFields([
                    .contentType: "text/vcard; charset=utf-8",
                    .contentDisposition: "attachment; filename=\(groupName.lowercased()).vcf"
                ]),
                body: .init(byteBuffer: ByteBuffer(string: vcfContent))
            )
        }
    }
}
```

### CardDAV Server Support

Implement CardDAV protocol for contact synchronization:

```swift
struct CardDAVServer {
    let client = VCardClient()

    func configureCardDAVRoutes(_ router: Router<some RequestContext>) {

        // CardDAV discovery
        router.on(.OPTIONS, "/carddav/**") { request, context in
            return Response(
                status: .ok,
                headers: HTTPFields([
                    HTTPField.Name("DAV")!: "1, 2, 3, addressbook",
                    HTTPField.Name("Allow")!: "GET, HEAD, PUT, DELETE, OPTIONS, PROPFIND, PROPPATCH, REPORT"
                ])
            )
        }

        // Address book collection
        router.on(.PROPFIND, "/carddav/addressbooks/:user/:collection/") { request, context in
            // Implementation for CardDAV PROPFIND requests
            let response = generatePropFindResponse()
            return Response(
                status: .multiStatus,
                headers: HTTPFields([
                    .contentType: "application/xml; charset=utf-8"
                ]),
                body: .init(byteBuffer: ByteBuffer(string: response))
            )
        }

        // Individual vCard resources
        router.get("/carddav/addressbooks/:user/:collection/:card.vcf") { request, context in
            guard let cardId = request.parameters.get("card") else {
                throw HTTPError(.badRequest)
            }

            let contact = try await getContact(id: cardId)
            let vcfContent = try client.serializeVCard(contact)

            return Response(
                status: .ok,
                headers: HTTPFields([
                    .contentType: "text/vcard; charset=utf-8",
                    HTTPField.Name("ETag")!: generateETag(for: contact)
                ]),
                body: .init(byteBuffer: ByteBuffer(string: vcfContent))
            )
        }
    }

    private func generateETag(for contact: VCard) -> String {
        // Generate ETag based on contact content for caching
        let content = try! client.serializeVCard(contact)
        return "\"\(content.hashValue)\""
    }
}
```

## Best Practices

### Performance Optimization

```swift
// Use lazy loading for large contact lists
struct ContactManager {
    private let client = VCardClient()
    private var contactCache: [String: VCard] = [:]

    func loadContact(id: String) async throws -> VCard {
        if let cached = contactCache[id] {
            return cached
        }

        let contact = try await loadContactFromDatabase(id: id)
        contactCache[id] = contact
        return contact
    }

    // Batch processing for efficiency
    func processContacts(_ contacts: [VCard], batchSize: Int = 50) async throws {
        for batch in contacts.chunked(into: batchSize) {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for contact in batch {
                    group.addTask {
                        try await processContact(contact)
                    }
                }
                try await group.waitForAll()
            }
        }
    }
}
```

### Data Validation

```swift
extension VCard {
    func validate() throws {
        guard let formattedName = formattedName, !formattedName.isEmpty else {
            throw VCardError.missingRequiredProperty("FN")
        }

        // Validate email formats
        for email in emailAddresses {
            guard email.contains("@") && email.contains(".") else {
                throw VCardError.invalidEmail(email)
            }
        }

        // Validate phone number formats
        for phone in phoneNumbers {
            guard phone.count >= 10 else {
                throw VCardError.invalidPhoneNumber(phone)
            }
        }
    }

    func sanitize() -> VCard {
        var sanitized = self

        // Clean up phone numbers
        sanitized.phoneNumbers = phoneNumbers.map { phone in
            phone.replacingOccurrences(of: "[^+0-9]", with: "", options: .regularExpression)
        }

        // Clean up email addresses
        sanitized.emailAddresses = emailAddresses.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        return sanitized
    }
}
```

### Security Considerations

```swift
// Sanitize input for security
extension VCardClient {
    func parseSecurely(from content: String) throws -> VCard {
        // Limit content size
        guard content.count < 1_000_000 else {
            throw VCardError.contentTooLarge
        }

        // Sanitize content
        let sanitized = content.replacingOccurrences(of: "<script", with: "&lt;script")
        return try parseVCard(from: sanitized)
    }
}

// Encrypt sensitive data
extension VCard {
    func encryptSensitiveData() -> VCard {
        var encrypted = self
        // Implement encryption for sensitive fields
        // encrypted.socialSecurityNumber = encrypt(socialSecurityNumber)
        return encrypted
    }
}
```
