import Foundation
import Testing

@testable import ICalendar

struct ICalendarRFC7986ExtensionsTests {

    let client = ICalendarClient(configuration: .default)

    // MARK: - Calendar Level Properties Tests

    @Test("Calendar NAME property")
    func testCalendarNameProperty() async throws {
        var calendar = client.createCalendar()

        // Test setting and getting name
        calendar.name = "My Personal Calendar"
        #expect(calendar.name == "My Personal Calendar")

        // Test serialization includes name
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("NAME:My Personal Calendar"))
    }

    @Test("Calendar DESCRIPTION property")
    func testCalendarDescriptionProperty() async throws {
        var calendar = client.createCalendar()

        // Test setting and getting calendar description
        calendar.calendarDescription = "Personal events and appointments"
        #expect(calendar.calendarDescription == "Personal events and appointments")

        // Test serialization includes description
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("DESCRIPTION:Personal events and appointments"))
    }

    @Test("Calendar UID property")
    func testCalendarUIDProperty() async throws {
        var calendar = client.createCalendar()

        // Test setting and getting calendar UID
        let testUID = "12345678-1234-5678-9012-123456789012"
        calendar.calendarUID = testUID
        #expect(calendar.calendarUID == testUID)

        // Test serialization includes UID
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("UID:\(testUID)"))
    }

    @Test("Calendar COLOR property")
    func testCalendarColorProperty() async throws {
        var calendar = client.createCalendar()

        // Test setting and getting color
        calendar.color = "blue"
        #expect(calendar.color == "blue")

        // Test serialization includes color
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("COLOR:blue"))
    }

    @Test("Calendar REFRESH-INTERVAL property")
    func testRefreshIntervalProperty() async throws {
        var calendar = client.createCalendar()

        // Test creating and setting refresh interval
        let interval = client.createRefreshInterval(days: 7)
        calendar.refreshInterval = interval
        #expect(calendar.refreshInterval?.days == 7)

        // Test serialization includes refresh interval
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("REFRESH-INTERVAL"))
        #expect(serialized.contains("P7D"))
    }

    @Test("Calendar SOURCE property")
    func testSourceProperty() async throws {
        var calendar = client.createCalendar()

        // Test setting and getting source
        let sourceURL = "https://example.com/calendar.ics"
        calendar.source = sourceURL
        #expect(calendar.source == sourceURL)

        // Test serialization includes source
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("SOURCE:\(sourceURL)"))
    }

    @Test("Calendar IMAGE properties")
    func testCalendarImagesProperty() async throws {
        var calendar = client.createCalendar()

        // Test setting and getting multiple images
        let images = [
            "https://example.com/image1.png",
            "https://example.com/image2.jpg",
        ]
        calendar.images = images
        #expect(calendar.images.count == 2)
        #expect(calendar.images.contains("https://example.com/image1.png"))
        #expect(calendar.images.contains("https://example.com/image2.jpg"))

        // Test serialization includes images
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("IMAGE:https://example.com/image1.png"))
        #expect(serialized.contains("IMAGE:https://example.com/image2.jpg"))
    }

    // MARK: - X-WR Extension Properties Tests

    @Test("X-WR-CALNAME property")
    func testXWRDisplayNameProperty() async throws {
        var calendar = client.createCalendar()

        // Test setting and getting display name
        calendar.displayName = "Work Calendar"
        #expect(calendar.displayName == "Work Calendar")

        // Test serialization includes X-WR-CALNAME
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("X-WR-CALNAME:Work Calendar"))
    }

    @Test("X-WR-CALDESC property")
    func testXWRDescriptionProperty() async throws {
        var calendar = client.createCalendar()

        // Test setting and getting X-WR description
        calendar.xwrDescription = "Calendar for work-related events"
        #expect(calendar.xwrDescription == "Calendar for work-related events")

        // Test serialization includes X-WR-CALDESC
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("X-WR-CALDESC:Calendar for work-related events"))
    }

    @Test("X-WR-TIMEZONE property")
    func testXWRTimeZoneProperty() async throws {
        var calendar = client.createCalendar()

        // Test setting and getting X-WR timezone
        calendar.xwrTimeZone = "America/New_York"
        #expect(calendar.xwrTimeZone == "America/New_York")

        // Test serialization includes X-WR-TIMEZONE
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("X-WR-TIMEZONE:America/New_York"))
    }

    @Test("X-WR-RELCALID property")
    func testRelatedCalendarIdProperty() async throws {
        var calendar = client.createCalendar()

        // Test setting and getting related calendar ID
        let relatedID = "parent-calendar-id-123"
        calendar.relatedCalendarId = relatedID
        #expect(calendar.relatedCalendarId == relatedID)

        // Test serialization includes X-WR-RELCALID
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("X-WR-RELCALID:\(relatedID)"))
    }

    @Test("X-PUBLISHED-TTL property")
    func testPublishedTTLProperty() async throws {
        var calendar = client.createCalendar()

        // Test setting and getting published TTL
        calendar.publishedTTL = "PT1H"
        #expect(calendar.publishedTTL == "PT1H")

        // Test serialization includes X-PUBLISHED-TTL
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("X-PUBLISHED-TTL:PT1H"))
    }

    // MARK: - Event Extension Properties Tests

    @Test("Event COLOR property")
    func testEventColorProperty() async throws {
        var calendar = client.createCalendar()
        var event = client.createEvent(
            summary: "Test Event",
            startDate: Date()
        )

        // Test setting and getting event color
        event.color = "red"
        #expect(event.color == "red")

        calendar.addEvent(event)

        // Test serialization includes event color
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("COLOR:red"))
    }

    @Test("Event IMAGE properties")
    func testEventImagesProperty() async throws {
        var calendar = client.createCalendar()
        var event = client.createEvent(
            summary: "Conference",
            startDate: Date()
        )

        // Test setting and getting event images
        event.images = [
            "https://example.com/conference-logo.png",
            "https://example.com/venue-photo.jpg",
        ]
        #expect(event.images.count == 2)

        calendar.addEvent(event)

        // Test serialization includes event images
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("IMAGE:https://example.com/conference-logo.png"))
        #expect(serialized.contains("IMAGE:https://example.com/venue-photo.jpg"))
    }

    @Test("Event CONFERENCE properties")
    func testEventConferencesProperty() async throws {
        var calendar = client.createCalendar()
        var event = client.createEvent(
            summary: "Team Meeting",
            startDate: Date()
        )

        // Test setting and getting event conferences
        event.conferences = [
            "https://meet.example.com/room/abc123",
            "tel:+1-555-123-4567,,123456",
        ]
        #expect(event.conferences.count == 2)

        calendar.addEvent(event)

        // Test serialization includes conference information
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("CONFERENCE:https://meet.example.com/room/abc123"))
        #expect(serialized.contains("CONFERENCE:tel:+1-555-123-4567\\,\\,123456"))
    }

    @Test("Event GEO property")
    func testEventGeoProperty() async throws {
        var calendar = client.createCalendar()
        var event = client.createEvent(
            summary: "Outdoor Event",
            startDate: Date(),
            location: "Central Park"
        )

        // Test setting and getting geographic coordinates
        let geo = client.createGeoCoordinate(latitude: 40.785091, longitude: -73.968285)
        event.geo = geo

        #expect(abs((event.geo?.latitude ?? 0) - 40.785091) < 0.000001)
        #expect(abs((event.geo?.longitude ?? 0) - (-73.968285)) < 0.000001)

        calendar.addEvent(event)

        // Test serialization includes geo coordinates
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("GEO:40.785091\\;-73.968285"))
    }

    // MARK: - Todo Extension Properties Tests

    @Test("Todo COLOR property")
    func testTodoColorProperty() async throws {
        var calendar = client.createCalendar()
        var todo = client.createTodo(summary: "Complete project")

        // Test setting and getting todo color
        todo.color = "orange"
        #expect(todo.color == "orange")

        calendar.addTodo(todo)

        // Test serialization includes todo color
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("COLOR:orange"))
    }

    @Test("Todo IMAGE properties")
    func testTodoImagesProperty() async throws {
        var calendar = client.createCalendar()
        var todo = client.createTodo(summary: "Design review")

        // Test setting and getting todo images
        todo.images = ["https://example.com/design-mockup.png"]
        #expect(todo.images.count == 1)
        #expect(todo.images.first == "https://example.com/design-mockup.png")

        calendar.addTodo(todo)

        // Test serialization includes todo image
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("IMAGE:https://example.com/design-mockup.png"))
    }

    // MARK: - Journal Extension Properties Tests

    @Test("Journal COLOR property")
    func testJournalColorProperty() async throws {
        var calendar = client.createCalendar()
        var journal = ICalJournal(summary: "Daily thoughts")

        // Test setting and getting journal color
        journal.color = "purple"
        #expect(journal.color == "purple")

        calendar.addJournal(journal)

        // Test serialization includes journal color
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("COLOR:purple"))
    }

    // MARK: - Convenience Methods Tests

    @Test("Create calendar with extensions")
    func testCreateCalendarWithExtensions() async throws {
        let calendar = client.createCalendar(
            name: "My Extended Calendar",
            description: "A calendar with all the new features",
            color: "green",
            displayName: "Extended Cal",
            timeZone: TimeZone(identifier: "America/Los_Angeles")!,
            refreshInterval: client.createRefreshInterval(hours: 1),
            source: "https://example.com/calendar.ics"
        )

        #expect(calendar.name == "My Extended Calendar")
        #expect(calendar.calendarDescription == "A calendar with all the new features")
        #expect(calendar.color == "green")
        #expect(calendar.displayName == "Extended Cal")
        #expect(calendar.xwrTimeZone == "America/Los_Angeles")
        #expect(calendar.refreshInterval?.hours == 1)
        #expect(calendar.source == "https://example.com/calendar.ics")
    }

    @Test("Update event with extensions")
    func testUpdateEventWithExtensions() async throws {
        var calendar = client.createCalendar()
        let event = client.createEvent(summary: "Test Event", startDate: Date())
        calendar.addEvent(event)

        // Test updating event color
        let colorUpdated = client.updateEventColor(
            in: &calendar,
            eventUID: event.uid,
            newColor: "blue"
        )
        #expect(colorUpdated)
        #expect(calendar.events.first?.color == "blue")

        // Test adding event image
        let imageAdded = client.addEventImage(
            in: &calendar,
            eventUID: event.uid,
            imageURI: "https://example.com/event-image.png"
        )
        #expect(imageAdded)
        #expect(calendar.events.first?.images.contains("https://example.com/event-image.png") == true)

        // Test updating event location with geo coordinates
        let locationUpdated = client.updateEventLocation(
            in: &calendar,
            eventUID: event.uid,
            latitude: 37.7749,
            longitude: -122.4194,
            location: "San Francisco, CA"
        )
        #expect(locationUpdated)
        #expect(abs((calendar.events.first?.geo?.latitude ?? 0) - 37.7749) < 0.0001)
        #expect(calendar.events.first?.location == "San Francisco, CA")

        // Test adding conference information
        let conferenceAdded = client.addEventConference(
            in: &calendar,
            eventUID: event.uid,
            conferenceURI: "https://zoom.us/j/123456789"
        )
        #expect(conferenceAdded)
        #expect(calendar.events.first?.conferences.contains("https://zoom.us/j/123456789") == true)
    }

    // MARK: - Geo Coordinate Tests

    @Test("Geographic coordinate string conversion")
    func testGeoCoordinateStringConversion() async throws {
        let geo = ICalGeoCoordinate(latitude: 40.7128, longitude: -74.0060)

        // Test string representation
        #expect(geo.stringValue == "40.712800;-74.006000")

        // Test initialization from string
        let geoFromString = ICalGeoCoordinate(from: "40.712800;-74.006000")
        #expect(geoFromString != nil)
        #expect(abs((geoFromString?.latitude ?? 0) - 40.7128) < 0.000001)
        #expect(abs((geoFromString?.longitude ?? 0) - (-74.0060)) < 0.000001)

        // Test invalid string
        let invalidGeo = ICalGeoCoordinate(from: "invalid")
        #expect(invalidGeo == nil)
    }

    // MARK: - Integration Tests

    @Test("Base64 IMAGE property support")
    func testBase64ImageProperty() async throws {
        var calendar = client.createCalendar()
        let event = client.createEvent(summary: "Event with Binary Image", startDate: Date())

        // Test binary image creation using base64 decoded data
        let base64String = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        let testImageData = Data(base64Encoded: base64String)!
        let binaryImageProperty = client.createBinaryImage(testImageData, mediaType: "image/png")

        #expect(binaryImageProperty.name == "IMAGE")
        #expect(binaryImageProperty.parameters["ENCODING"] == "BASE64")
        #expect(binaryImageProperty.parameters["VALUE"] == "BINARY")
        #expect(binaryImageProperty.parameters["FMTTYPE"] == "image/png")
        #expect(binaryImageProperty.value == ICalendarFormatter.encodeBase64(testImageData))

        // Test URI image creation
        let uriImageProperty = client.createURIImage("https://example.com/image.png", mediaType: "image/png")
        #expect(uriImageProperty.name == "IMAGE")
        #expect(uriImageProperty.parameters["VALUE"] == "URI")
        #expect(uriImageProperty.parameters["FMTTYPE"] == "image/png")
        #expect(uriImageProperty.value == "https://example.com/image.png")

        // Add event to calendar first, then add binary image to it
        calendar.addEvent(event)
        let binaryAdded = client.addBinaryImageToEvent(
            in: &calendar,
            eventUID: event.uid,
            imageData: testImageData,
            mediaType: "image/png"
        )
        #expect(binaryAdded)

        // Test serialization includes image property
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("IMAGE"))
        #expect(serialized.contains("ENCODING=BASE64"))
        #expect(serialized.contains("VALUE=BINARY"))
        #expect(serialized.contains("FMTTYPE=image/png"))

        // Test round-trip parsing
        let parser = ICalendarParser()
        let parsedCalendar = try parser.parse(serialized)
        #expect(parsedCalendar.events.count == 1)

        let imageProperties = parsedCalendar.events.first!.properties.filter { $0.name == "IMAGE" }
        #expect(imageProperties.count == 1)

        let imageProperty = imageProperties.first!
        #expect(imageProperty.parameters["ENCODING"] == "BASE64")
        #expect(imageProperty.parameters["VALUE"] == "BINARY")
        #expect(imageProperty.parameters["FMTTYPE"] == "image/png")

        // Test base64 decoding
        if let decodedData = ICalendarFormatter.decodeBase64(imageProperty.value) {
            #expect(decodedData == testImageData)
        } else {
            #expect(Bool(false), "Failed to decode base64 image data")
        }
    }

    @Test("Full calendar with extensions")
    func testFullCalendarWithExtensions() async throws {
        // Create a calendar with all extensions
        var calendar = client.createCalendar(
            name: "Complete Test Calendar",
            description: "Testing all RFC 7986 and X-WR extensions",
            color: "teal",
            displayName: "Test Cal",
            timeZone: TimeZone(identifier: "UTC")!,
            refreshInterval: client.createRefreshInterval(days: 1)
        )

        // Add event with extensions
        var event = client.createEvent(
            summary: "Extended Event",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Conference Center"
        )
        event.color = "red"
        event.geo = client.createGeoCoordinate(latitude: 37.7749, longitude: -122.4194)
        event.images = ["https://example.com/event.png"]
        event.conferences = ["https://meet.google.com/abc-defg-hij"]

        calendar.addEvent(event)

        // Serialize and verify all properties are present
        let serialized: String = try client.serializeCalendar(calendar)

        // Verify calendar properties
        #expect(serialized.contains("NAME:Complete Test Calendar"))
        #expect(serialized.contains("DESCRIPTION:Testing all RFC 7986 and X-WR extensions"))
        #expect(serialized.contains("COLOR:teal"))
        #expect(serialized.contains("X-WR-CALNAME:Test Cal"))
        #expect(serialized.contains("X-WR-TIMEZONE:UTC"))
        #expect(serialized.contains("REFRESH-INTERVAL"))

        // Verify event properties
        #expect(serialized.contains("SUMMARY:Extended Event"))
        #expect(serialized.contains("COLOR:red"))
        #expect(serialized.contains("GEO:37.774900\\;-122.419400"))
        #expect(serialized.contains("IMAGE:https://example.com/event.png"))
        #expect(serialized.contains("CONFERENCE:https://meet.google.com/abc-defg-hij"))

        // Test parsing the serialized calendar back
        let parser = ICalendarParser()
        let parsedCalendar = try parser.parse(serialized)

        #expect(parsedCalendar.name == "Complete Test Calendar")
        #expect(parsedCalendar.color == "teal")
        #expect(parsedCalendar.displayName == "Test Cal")
        #expect(parsedCalendar.events.count == 1)

        let parsedEvent = parsedCalendar.events.first!
        #expect(parsedEvent.color == "red")
        #expect(parsedEvent.images.count == 1)
        #expect(parsedEvent.conferences.count == 1)
        #expect(parsedEvent.geo != nil)
        #expect(abs((parsedEvent.geo?.latitude ?? 0) - 37.7749) < 0.0001)
    }

    // MARK: - Timezone TZURL Tests

    @Test("TZURL generation utilities")
    func testTZURLGeneration() async throws {
        let client = ICalendarClient()

        // Test TZURL generation with string
        let tzUrl = client.generateTZURL(for: "Asia/Tokyo")
        #expect(tzUrl == "http://tzurl.org/zoneinfo-outlook/Asia/Tokyo")

        let altTzUrl = client.generateAlternativeTZURL(for: "Australia/Sydney")
        #expect(altTzUrl == "https://www.tzurl.org/zoneinfo-outlook/Australia/Sydney")

        // Test TZURL generation with Foundation TimeZone
        if let timeZone = TimeZone(identifier: "Europe/Paris") {
            let tzUrlFromTimeZone = client.generateTZURL(for: timeZone)
            #expect(tzUrlFromTimeZone == "http://tzurl.org/zoneinfo-outlook/Europe/Paris")

            let altTzUrlFromTimeZone = client.generateAlternativeTZURL(for: timeZone)
            #expect(altTzUrlFromTimeZone == "https://www.tzurl.org/zoneinfo-outlook/Europe/Paris")
        }
    }

    @Test("X-WR-TIMEZONE Foundation TimeZone integration")
    func testXWRTimeZoneIntegration() async throws {
        // Test calendar X-WR-TIMEZONE with Foundation TimeZone
        var calendar = client.createCalendar()

        if let tz = TimeZone(identifier: "Pacific/Auckland") {
            calendar.setXwrTimeZone(tz)
            #expect(calendar.xwrTimeZone == "Pacific/Auckland")

            // Test round-trip
            let retrievedTZ = calendar.xwrFoundationTimeZone
            #expect(retrievedTZ?.identifier == "Pacific/Auckland")
        }

        // Test serialization of X-WR-TIMEZONE
        if let tz = TimeZone(identifier: "America/Los_Angeles") {
            calendar.setXwrTimeZone(tz)
            let serialized: String = try client.serializeCalendar(calendar)
            #expect(serialized.contains("X-WR-TIMEZONE:America/Los_Angeles"))
        }
    }

    // MARK: - Enhanced ATTACH Property Tests

    @Test("Enhanced ATTACH property support")
    func testEnhancedAttachProperty() async throws {
        let client = ICalendarClient()
        var calendar = client.createCalendar()
        let event = client.createEvent(summary: "Event with Attachments", startDate: Date())
        calendar.addEvent(event)

        // Test URI attachment
        let uriAttachment = client.createURIAttachment("https://example.com/document.pdf", mediaType: "application/pdf")
        #expect(uriAttachment.type == .uri)
        #expect(uriAttachment.value == "https://example.com/document.pdf")
        #expect(uriAttachment.mediaType == "application/pdf")

        // Test binary attachment
        let testData = Data("Sample attachment content".utf8)
        let binaryAttachment = client.createBinaryAttachment(testData, mediaType: "text/plain")
        #expect(binaryAttachment.type == .binary)
        #expect(binaryAttachment.mediaType == "text/plain")
        #expect(binaryAttachment.encoding == "BASE64")

        // Test binary data decoding
        #expect(binaryAttachment.decodedData == testData)

        // Add attachments to event
        let uriAdded = client.addURIAttachmentToEvent(
            in: &calendar,
            eventUID: event.uid,
            uri: "https://example.com/agenda.pdf",
            mediaType: "application/pdf"
        )
        #expect(uriAdded)

        let binaryAdded = client.addBinaryAttachmentToEvent(
            in: &calendar,
            eventUID: event.uid,
            data: testData,
            mediaType: "text/plain"
        )
        #expect(binaryAdded)

        // Test serialization
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("ATTACH;FMTTYPE=application/pdf;VALUE=URI:https://example.com/agenda.pdf"))
        #expect(serialized.contains("ATTACH;ENCODING=BASE64;FMTTYPE=text/plain;VALUE=BINARY:"))

        // Test round-trip parsing
        let parser = ICalendarParser()
        let parsedCalendar = try parser.parse(serialized)
        #expect(parsedCalendar.events.count == 1)

        let parsedEvent = parsedCalendar.events.first!
        #expect(parsedEvent.attachments.count == 2)

        let uriAttach = parsedEvent.attachments.first { $0.type == .uri }
        #expect(uriAttach?.value == "https://example.com/agenda.pdf")
        #expect(uriAttach?.mediaType == "application/pdf")

        let binaryAttach = parsedEvent.attachments.first { $0.type == .binary }
        #expect(binaryAttach?.mediaType == "text/plain")
        #expect(binaryAttach?.decodedData == testData)
    }

    @Test("ATTACH property for todos and journals")
    func testAttachPropertyForAllComponents() async throws {
        let client = ICalendarClient()
        var calendar = client.createCalendar()

        // Test todo with attachment
        var todo = client.createTodo(summary: "Task with attachment")
        let todoAttachment = client.createURIAttachment("https://example.com/spec.pdf", mediaType: "application/pdf")
        todo.attachments = [todoAttachment]
        calendar.addTodo(todo)

        // Test journal with attachment
        var journal = ICalJournal(summary: "Journal with attachment")
        let journalData = Data("Journal attachment data".utf8)
        let journalAttachment = client.createBinaryAttachment(journalData, mediaType: "text/plain")
        journal.attachments = [journalAttachment]
        calendar.addJournal(journal)

        // Test serialization
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("BEGIN:VTODO"))
        #expect(serialized.contains("ATTACH;FMTTYPE=application/pdf;VALUE=URI:https://example.com/spec.pdf"))
        #expect(serialized.contains("BEGIN:VJOURNAL"))
        #expect(serialized.contains("ATTACH;ENCODING=BASE64;FMTTYPE=text/plain;VALUE=BINARY:"))

        // Test round-trip parsing
        let parser = ICalendarParser()
        let parsedCalendar = try parser.parse(serialized)
        #expect(parsedCalendar.todos.count == 1)
        #expect(parsedCalendar.journals.count == 1)

        let parsedTodo = parsedCalendar.todos.first!
        #expect(parsedTodo.attachments.count == 1)
        #expect(parsedTodo.attachments.first?.type == .uri)

        let parsedJournal = parsedCalendar.journals.first!
        #expect(parsedJournal.attachments.count == 1)
        #expect(parsedJournal.attachments.first?.type == .binary)
        #expect(parsedJournal.attachments.first?.decodedData == journalData)
    }

    @Test("Legacy ATTACH property compatibility")
    func testLegacyAttachCompatibility() async throws {
        let client = ICalendarClient()

        // Test legacy audio alarm with attach property
        let alarm = client.createAudioAlarm(triggerMinutesBefore: 5, audioFile: "reminder.wav")
        #expect(alarm.attach == "reminder.wav")

        // Test that legacy attach still works with new attachments property
        #expect(alarm.attachments.count == 1)
        #expect(alarm.attachments.first?.type == .uri)
        #expect(alarm.attachments.first?.value == "reminder.wav")
    }
}
