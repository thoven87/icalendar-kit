import Foundation
import Testing

@testable import ICalendar

/// Tests for RFC 9073 Event Publishing Extensions components
@Suite("RFC 9073 Event Publishing Extensions Tests")
struct RFC9073ComponentTests {

    // MARK: - VVENUE Component Tests

    @Test("VVENUE component creation and properties")
    func testVVenueComponentCreation() {
        var venue = ICalVenue(properties: [], components: [])

        venue.name = "Conference Center"
        venue.description = "Main conference venue for tech events"
        venue.streetAddress = "123 Main Street"
        venue.locality = "San Francisco"
        venue.region = "CA"
        venue.country = "USA"
        venue.postalCode = "94102"
        venue.geo = ICalGeo(latitude: 37.7749, longitude: -122.4194)
        venue.locationTypes = ["VENUE", "CONFERENCE"]
        venue.categories = ["Technology", "Conference"]

        #expect(venue.name == "Conference Center")
        #expect(venue.description == "Main conference venue for tech events")
        #expect(venue.streetAddress == "123 Main Street")
        #expect(venue.locality == "San Francisco")
        #expect(venue.region == "CA")
        #expect(venue.country == "USA")
        #expect(venue.postalCode == "94102")
        #expect(venue.geo?.latitude == 37.7749)
        #expect(venue.geo?.longitude == -122.4194)
        #expect(venue.locationTypes.contains("VENUE"))
        #expect(venue.categories.contains("Technology"))
    }

    @Test("VVENUE component in event")
    func testVVenueInEvent() {
        let venue = ICalVenue(
            properties: [
                ICalProperty(name: "NAME", value: "Tech Hub"),
                ICalProperty(name: "DESCRIPTION", value: "Innovation center"),
            ],
            components: []
        )

        var event = ICalEvent(uid: "venue-event@example.com", summary: "Tech Conference")
        event.addVenue(venue)

        #expect(event.venues.count == 1)
        #expect(event.venues.first?.name == "Tech Hub")
    }

    @Test("VVENUE serialization")
    func testVVenueSerialization() {
        var calendar = ICalendar(productId: "RFC9073//Test//EN") {
            ICalEvent(uid: "venue-test@example.com", summary: "Event with Venue")
        }

        let venue = ICalVenue(
            properties: [
                ICalProperty(name: "NAME", value: "Convention Center"),
                ICalProperty(name: "DESCRIPTION", value: "Large event space"),
                ICalProperty(name: "STREET-ADDRESS", value: "456 Convention Blvd"),
                ICalProperty(name: "LOCALITY", value: "Los Angeles"),
                ICalProperty(name: "REGION", value: "CA"),
                ICalProperty(name: "COUNTRY", value: "USA"),
            ],
            components: []
        )

        calendar.updateEvent(withUID: "venue-test@example.com") { event in
            event.addVenue(venue)
        }

        let serialized: String = try! ICalendarKit.serializeCalendar(calendar)

        #expect(serialized.contains("BEGIN:VVENUE"))
        #expect(serialized.contains("NAME:Convention Center"))
        #expect(serialized.contains("DESCRIPTION:Large event space"))
        #expect(serialized.contains("STREET-ADDRESS:456 Convention Blvd"))
        #expect(serialized.contains("LOCALITY:Los Angeles"))
        #expect(serialized.contains("END:VVENUE"))
    }

    // MARK: - VLOCATION Component Tests

    @Test("VLOCATION component creation")
    func testVLocationComponentCreation() {
        var location = ICalLocationComponent(properties: [], components: [])

        location.name = "Meeting Room A"
        location.description = "Corner meeting room with video conference"
        location.locationTypes = ["ROOM", "MEETING"]
        location.capacity = 12

        #expect(location.name == "Meeting Room A")
        #expect(location.description == "Corner meeting room with video conference")
        #expect(location.locationTypes.contains("ROOM"))
        #expect(location.capacity == 12)
    }

    @Test("VLOCATION in calendar structure")
    func testVLocationInCalendar() {
        let location = ICalLocationComponent(
            properties: [
                ICalProperty(name: "NAME", value: "Virtual Meeting Room"),
                ICalProperty(name: "DESCRIPTION", value: "Zoom conference room"),
                ICalProperty(name: "LOCATION-TYPE", value: "VIRTUAL"),
            ],
            components: []
        )

        var calendar = ICalendar(productId: "RFC9073//Location//EN")
        calendar.addLocationComponent(location)

        #expect(calendar.locationComponents.count == 1)
        #expect(calendar.locationComponents.first?.name == "Virtual Meeting Room")
    }

    // MARK: - VRESOURCE Component Tests

    @Test("VRESOURCE component creation")
    func testVResourceComponentCreation() {
        var resource = ICalResourceComponent(properties: [], components: [])

        resource.name = "Projector"
        resource.description = "4K HD Projector"
        resource.resourceType = "EQUIPMENT"
        resource.categories = ["Audio-Visual", "Presentation"]

        #expect(resource.name == "Projector")
        #expect(resource.description == "4K HD Projector")
        #expect(resource.resourceType == "EQUIPMENT")
        #expect(resource.categories.contains("Audio-Visual"))
    }

    @Test("VRESOURCE in event")
    func testVResourceInEvent() {
        let resource = ICalResourceComponent(
            properties: [
                ICalProperty(name: "NAME", value: "Conference Bridge"),
                ICalProperty(name: "DESCRIPTION", value: "Audio conference system"),
                ICalProperty(name: "RESOURCE-TYPE", value: "EQUIPMENT"),
            ],
            components: []
        )

        var event = ICalEvent(uid: "resource-event@example.com", summary: "Meeting with Resources")
        event.addResource(resource)

        #expect(event.resources.count == 1)
        #expect(event.resources.first?.name == "Conference Bridge")
    }

    // MARK: - Structured Data Tests

    @Test("Structured data property")
    func testStructuredDataProperty() {
        let jsonData = """
            {
                "type": "TechConference",
                "duration": "PT8H",
                "speakers": ["Dr. Smith", "Prof. Johnson"],
                "topics": ["AI", "Machine Learning", "Data Science"]
            }
            """

        var event = ICalEvent(uid: "structured-data@example.com", summary: "AI Conference")
        event.structuredData = ICalStructuredData(type: .json, data: jsonData)

        #expect(event.structuredData?.data == jsonData)

        // Test that it serializes correctly
        let calendar = ICalendar(productId: "RFC9073//StructuredData//EN") {
            event
        }

        let serialized: String = try! ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("STRUCTURED-DATA:"))
        #expect(serialized.contains("TechConference"))
    }

    @Test("Structured data with MIME type")
    func testStructuredDataWithMimeType() {
        let xmlData = """
            <conference>
                <name>Tech Summit 2024</name>
                <duration>8 hours</duration>
            </conference>
            """

        var event = ICalEvent(uid: "xml-data@example.com", summary: "XML Data Event")
        event.properties.append(
            ICalProperty(
                name: "STRUCTURED-DATA",
                value: xmlData,
                parameters: ["FMTTYPE": "application/xml"]
            )
        )

        let calendar = ICalendar(productId: "RFC9073//XML//EN") {
            event
        }

        let serialized: String = try! ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("STRUCTURED-DATA;FMTTYPE=application/xml:"))
        #expect(serialized.contains("Tech Summit"))
    }

    // MARK: - Complex Integration Tests

    @Test("Event with multiple RFC 9073 components")
    func testComplexEventWithPublishingExtensions() {
        // Create venue
        let venue = ICalVenue(
            properties: [
                ICalProperty(name: "NAME", value: "Tech Campus"),
                ICalProperty(name: "DESCRIPTION", value: "Modern technology campus"),
                ICalProperty(name: "STREET-ADDRESS", value: "1 Innovation Way"),
                ICalProperty(name: "LOCALITY", value: "Palo Alto"),
                ICalProperty(name: "REGION", value: "CA"),
            ],
            components: []
        )

        // Create location within venue
        let location = ICalLocationComponent(
            properties: [
                ICalProperty(name: "NAME", value: "Auditorium A"),
                ICalProperty(name: "DESCRIPTION", value: "Main presentation hall"),
                ICalProperty(name: "LOCATION-TYPE", value: "AUDITORIUM"),
                ICalProperty(name: "CAPACITY", value: "500"),
            ],
            components: []
        )

        // Create resources
        let projector = ICalResourceComponent(
            properties: [
                ICalProperty(name: "NAME", value: "4K Projector"),
                ICalProperty(name: "RESOURCE-TYPE", value: "EQUIPMENT"),
            ],
            components: []
        )

        let microphone = ICalResourceComponent(
            properties: [
                ICalProperty(name: "NAME", value: "Wireless Microphone"),
                ICalProperty(name: "RESOURCE-TYPE", value: "EQUIPMENT"),
            ],
            components: []
        )

        // Create event with all components
        var event = ICalEvent(uid: "complex-event@example.com", summary: "Annual Tech Conference")
        event.description = "Our biggest technology conference of the year"
        event.addVenue(venue)
        event.addLocation(location)
        event.addResource(projector)
        event.addResource(microphone)

        // Add structured data
        let jsonData = """
            {
                "eventType": "conference",
                "expectedAttendees": 400,
                "mainTracks": ["AI", "Cloud", "Security"],
                "catering": true
            }
            """
        event.structuredData = ICalStructuredData(type: .json, data: jsonData)

        let calendar = ICalendar(productId: "RFC9073//Complex//EN") {
            event
        }

        // Verify all components are present
        #expect(event.venues.count == 1)
        #expect(event.locations.count == 1)
        #expect(event.resources.count == 2)
        #expect(event.structuredData != nil)

        // Test serialization
        let serialized: String = try! ICalendarKit.serializeCalendar(calendar)

        #expect(serialized.contains("BEGIN:VVENUE"))
        #expect(serialized.contains("NAME:Tech Campus"))
        #expect(serialized.contains("BEGIN:VLOCATION"))
        #expect(serialized.contains("NAME:Auditorium A"))
        #expect(serialized.contains("BEGIN:VRESOURCE"))
        #expect(serialized.contains("NAME:4K Projector"))
        #expect(serialized.contains("NAME:Wireless Microphone"))
        #expect(serialized.contains("STRUCTURED-DATA:"))
        #expect(serialized.contains("expectedAttendees"))
    }

    // MARK: - Validation Tests

    @Test("RFC 9073 components validation")
    func testRFC9073ComponentsValidation() {
        let calendar = ICalendar(productId: "RFC9073//Validation//EN") {
            ICalEvent(uid: "validation-test@example.com", summary: "Validation Test Event")
        }

        var event = calendar.events.first!

        // Add minimal valid venue
        let venue = ICalVenue(
            properties: [
                ICalProperty(name: "NAME", value: "Test Venue")
            ],
            components: []
        )
        event.addVenue(venue)

        let result = calendar.validate()
        #expect(result.isValid || result.hasWarnings)
    }

    @Test("Empty RFC 9073 components handling")
    func testEmptyComponentsHandling() {
        var event = ICalEvent(uid: "empty-components@example.com", summary: "Empty Components Test")

        // Add empty venue (should be handled gracefully)
        let emptyVenue = ICalVenue(properties: [], components: [])
        event.addVenue(emptyVenue)

        #expect(event.venues.count == 1)
        #expect(event.venues.first?.name == nil)
    }

    // MARK: - Parsing Tests

    @Test("Parse calendar with RFC 9073 components")
    func testParseCalendarWithRFC9073Components() {
        let icsContent = """
            BEGIN:VCALENDAR
            VERSION:2.0
            PRODID:RFC9073//Parse Test//EN
            BEGIN:VEVENT
            UID:parse-test@example.com
            SUMMARY:Parsed Event
            DTSTART:20241003T120000Z
            DTEND:20241003T130000Z
            BEGIN:VVENUE
            NAME:Parsed Venue
            DESCRIPTION:Test venue for parsing
            END:VVENUE
            BEGIN:VLOCATION
            NAME:Parsed Location
            LOCATION-TYPE:ROOM
            END:VLOCATION
            BEGIN:VRESOURCE
            NAME:Parsed Resource
            RESOURCE-TYPE:EQUIPMENT
            END:VRESOURCE
            STRUCTURED-DATA:{"type":"test","valid":true}
            END:VEVENT
            END:VCALENDAR
            """

        let parser = ICalendarParser()
        do {
            let calendar = try parser.parse(icsContent)

            #expect(calendar.events.count == 1)

            let event = calendar.events.first!
            #expect(event.summary == "Parsed Event")
            #expect(event.venues.count == 1)
            #expect(event.venues.first?.name == "Parsed Venue")
            #expect(event.locations.count == 1)
            #expect(event.locations.first?.name == "Parsed Location")
            #expect(event.resources.count == 1)
            #expect(event.resources.first?.name == "Parsed Resource")
            #expect(event.structuredData?.data.contains("\"type\":\"test\"") == true)

        } catch {
            Issue.record("Failed to parse calendar with RFC 9073 components: \(error)")
        }
    }
}
