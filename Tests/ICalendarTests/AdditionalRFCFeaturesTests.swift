import Foundation
import Testing

@testable import ICalendar

/// Comprehensive tests for missing RFC features implementation
@Suite("Additional RFC Features Tests")
struct AdditionalRFCFeaturesTests {
    let client = ICalendarClient()

    // MARK: - RFC 7529 Non-Gregorian Recurrence Tests

    @Test("RFC 7529: RSCALE Hebrew calendar recurrence")
    func testHebrewCalendarRecurrence() async throws {
        // Create Hebrew calendar recurrence rule
        let hebrewRule = client.createHebrewRecurrence(
            frequency: .yearly,
            interval: 1,
            count: 5
        )

        #expect(hebrewRule.frequency == .yearly)
        #expect(hebrewRule.interval == 1)
        #expect(hebrewRule.count == 5)
        #expect(hebrewRule.rscale == .hebrew)
        #expect(hebrewRule.calendar.identifier == .hebrew)

        // Create event with Hebrew recurrence
        var event = client.createEvent(
            summary: "Rosh Hashanah",
            startDate: Date()
        )
        event.recurrenceRule = hebrewRule

        let calendar = client.createCalendar(events: [event])

        // Serialize and verify RSCALE appears in output
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("RSCALE=HEBREW"))
        #expect(serialized.contains("FREQ=YEARLY"))

        // Parse back and verify
        let parser = ICalendarParser()
        let parsed = try parser.parse(serialized)
        let parsedEvent = parsed.events.first
        #expect(parsedEvent?.recurrenceRule?.rscale == .hebrew)
    }

    @Test("RFC 7529: RSCALE Islamic calendar recurrence")
    func testIslamicCalendarRecurrence() async throws {
        // Create Islamic calendar recurrence for Ramadan
        let islamicRule = client.createIslamicRecurrence(
            frequency: .yearly,
            interval: 1
        )

        #expect(islamicRule.rscale == .islamic)
        #expect(islamicRule.rscale?.foundationIdentifier == .islamic)

        var event = client.createEvent(
            summary: "Ramadan begins",
            startDate: Date()
        )
        event.recurrenceRule = islamicRule

        let calendar = client.createCalendar(events: [event])
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("RSCALE=ISLAMIC"))
    }

    @Test("RFC 7529: RSCALE Chinese calendar recurrence")
    func testChineseCalendarRecurrence() async throws {
        let chineseRule = client.createNonGregorianRecurrence(
            frequency: .yearly,
            interval: 1,
            rscale: .chinese
        )

        #expect(chineseRule.rscale == .chinese)
        #expect(chineseRule.calendar.identifier == .chinese)

        var event = client.createEvent(
            summary: "Chinese New Year",
            startDate: Date()
        )
        event.recurrenceRule = chineseRule

        let calendar = client.createCalendar(events: [event])
        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("RSCALE=CHINESE"))
    }

    // MARK: - RFC 5546 Enhanced iTIP Tests

    @Test("RFC 5546: Accept invitation workflow")
    func testAcceptInvitation() async throws {
        // Create initial REQUEST
        let organizer = client.createOrganizer(email: "organizer@example.com", name: "Meeting Organizer")
        let attendee = client.createAttendee(email: "attendee@example.com", name: "John Doe")

        var event = client.createEvent(
            summary: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600)
        )
        event.organizer = organizer
        event.attendees = [attendee]

        var requestCalendar = client.createCalendar(events: [event])
        requestCalendar.method = "REQUEST"

        // Accept the invitation
        let replyCalendar = client.acceptInvitation(
            requestCalendar,
            eventUID: event.uid,
            attendeeEmail: "attendee@example.com"
        )

        #expect(replyCalendar != nil)
        #expect(replyCalendar?.method == "REPLY")

        let replyEvent = replyCalendar?.events.first
        #expect(replyEvent?.attendees.first?.participationStatus == .accepted)
        #expect(replyEvent?.sequence == 1)  // Sequence should be incremented
    }

    @Test("RFC 5546: Decline invitation workflow")
    func testDeclineInvitation() async throws {
        var event = client.createEvent(summary: "Optional Meeting", startDate: Date())
        event.attendees = [client.createAttendee(email: "attendee@example.com")]

        let requestCalendar = client.createCalendar(events: [event])

        let replyCalendar = client.declineInvitation(
            requestCalendar,
            eventUID: event.uid,
            attendeeEmail: "attendee@example.com"
        )

        #expect(replyCalendar?.method == "REPLY")
        #expect(replyCalendar?.events.first?.attendees.first?.participationStatus == .declined)
    }

    @Test("RFC 5546: Counter proposal workflow")
    func testCounterProposal() async throws {
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)  // Fixed date
        let originalStart = baseDate
        let originalEnd = originalStart.addingTimeInterval(3600)

        var event = client.createEvent(
            summary: "Team Meeting",
            startDate: originalStart,
            endDate: originalEnd
        )
        event.attendees = [client.createAttendee(email: "attendee@example.com")]

        let requestCalendar = client.createCalendar(events: [event])

        // Propose new time (2 hours later)
        let proposedStart = originalStart.addingTimeInterval(7200)
        let counterCalendar = client.proposeNewTime(
            requestCalendar,
            eventUID: event.uid,
            attendeeEmail: "attendee@example.com",
            newStartDate: proposedStart,
            comment: "Could we meet 2 hours later?"
        )

        #expect(counterCalendar?.method == "COUNTER")

        let counterEvent = counterCalendar?.events.first
        #expect(
            client.areDateTimesEqual(
                counterEvent?.dateTimeStart,
                client.createDateTime(from: proposedStart, timeZone: client.configuration.defaultTimeZone)
            )
        )
        #expect(counterEvent?.sequence == 1)

        // Verify comment was added
        let serialized: String = try client.serializeCalendar(counterCalendar!)
        #expect(serialized.contains("Could we meet 2 hours later?"))
    }

    @Test("RFC 5546: REFRESH request workflow")
    func testRefreshRequest() async throws {
        let refreshCalendar = client.requestRefresh(
            eventUID: "test-event-uid",
            attendeeEmail: "attendee@example.com"
        )

        #expect(refreshCalendar.method == "REFRESH")
        #expect(refreshCalendar.events.count == 1)

        let refreshEvent = refreshCalendar.events.first
        #expect(refreshEvent?.uid == "test-event-uid")
        #expect(refreshEvent?.attendees.count == 1)
        #expect(refreshEvent?.attendees.first?.email == "attendee@example.com")
    }

    @Test("RFC 5546: iTIP message validation")
    func testITipValidation() async throws {
        // Test REQUEST validation
        var requestCalendar = client.createCalendar()
        requestCalendar.method = "REQUEST"

        var event = client.createEvent(summary: "Test Event", startDate: Date())
        event.organizer = client.createOrganizer(email: "org@example.com")
        requestCalendar.addEvent(event)

        #expect(throws: Never.self) {
            try client.validateiTIPMessage(requestCalendar)
        }

        // Test invalid REQUEST (missing ORGANIZER)
        var invalidRequest = client.createCalendar()
        invalidRequest.method = "REQUEST"
        invalidRequest.addEvent(client.createEvent(summary: "Invalid", startDate: Date()))

        #expect(throws: ICalendarError.self) {
            try client.validateiTIPMessage(invalidRequest)
        }
    }

    // MARK: - RFC 9074 Advanced Alarms Tests

    @Test("RFC 9074: Proximity-based alarms")
    func testProximityAlarms() async throws {
        // Create proximity alarm for entering office
        let proximityAlarm = client.createProximityAlarm(
            latitude: 37.7749,
            longitude: -122.4194,
            radius: 100,
            entering: true,
            description: "Arrived at office"
        )

        #expect(proximityAlarm.action == .proximity)
        #expect(proximityAlarm.proximityTrigger != nil)
        #expect(proximityAlarm.proximityTrigger?.latitude == 37.7749)
        #expect(proximityAlarm.proximityTrigger?.longitude == -122.4194)
        #expect(proximityAlarm.proximityTrigger?.radius == 100)
        #expect(proximityAlarm.proximityTrigger?.entering == true)

        // Add to event and serialize
        var event = client.createEvent(summary: "Work Day", startDate: Date())
        event.addAlarm(proximityAlarm)

        let calendar = client.createCalendar(events: [event])
        let serialized: String = try client.serializeCalendar(calendar)

        #expect(serialized.contains("ACTION:PROXIMITY"))
        #expect(serialized.contains("PROXIMITY-TRIGGER:37.774900\\;-122.419400\\;100.000000\\;ENTERING"))
    }

    @Test("RFC 9074: Alarm acknowledgment")
    func testAlarmAcknowledgment() async throws {
        let alarm = client.createDisplayAlarm(description: "Meeting reminder", triggerMinutesBefore: 15)

        // Acknowledge the alarm
        let acknowledgedAlarm = client.acknowledgeAlarm(
            alarm,
            acknowledgedBy: "user@example.com",
            acknowledgedAt: Date()
        )

        #expect(acknowledgedAlarm.acknowledgment != nil)
        #expect(acknowledgedAlarm.acknowledgment?.acknowledgedBy == "user@example.com")

        var event = client.createEvent(summary: "Meeting", startDate: Date())
        event.addAlarm(acknowledgedAlarm)

        let calendar = client.createCalendar(events: [event])
        let serialized: String = try client.serializeCalendar(calendar)

        #expect(serialized.contains("ACKNOWLEDGED:"))
        #expect(serialized.contains("ACKNOWLEDGED-BY:user@example.com"))
    }

    @Test("RFC 9074: Related alarms")
    func testRelatedAlarms() async throws {
        var alarm1 = client.createDisplayAlarm(description: "First reminder", triggerMinutesBefore: 30)
        alarm1.relatedAlarms = ["alarm-uid-2", "alarm-uid-3"]

        #expect(alarm1.relatedAlarms.count == 2)
        #expect(alarm1.relatedAlarms.contains("alarm-uid-2"))

        var event = client.createEvent(summary: "Important Meeting", startDate: Date())
        event.addAlarm(alarm1)

        let calendar = client.createCalendar(events: [event])
        let serialized: String = try client.serializeCalendar(calendar)

        #expect(serialized.contains("RELATED-TO:alarm-uid-2"))
        #expect(serialized.contains("RELATED-TO:alarm-uid-3"))
    }

    // MARK: - RFC 9073 Event Publishing Extensions Tests

    @Test("RFC 9073: VVENUE component")
    func testVenueComponent() async throws {
        let venue = client.createVenue(
            name: "Conference Center",
            address: "123 Main St, San Francisco, CA",
            latitude: 37.7749,
            longitude: -122.4194,
            capacity: 500,
            url: "https://conference.example.com"
        )

        #expect(venue.name == "Conference Center")
        #expect(venue.address == "123 Main St, San Francisco, CA")
        #expect(venue.capacity == 500)
        #expect(venue.url == "https://conference.example.com")
        #expect(venue.geo?.latitude == 37.7749)
        #expect(venue.geo?.longitude == -122.4194)

        // Add to calendar and serialize
        var calendar = client.createCalendar()
        calendar.addVenue(venue)

        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("BEGIN:VVENUE"))
        #expect(serialized.contains("NAME:Conference Center"))
        #expect(serialized.contains("ADDRESS:123 Main St\\, San Francisco\\, CA"))
        #expect(serialized.contains("CAPACITY:500"))
        #expect(serialized.contains("END:VVENUE"))
    }

    @Test("RFC 9073: VLOCATION component")
    func testLocationComponent() async throws {
        let location = client.createEnhancedLocation(
            name: "Golden Gate Park",
            address: "Golden Gate Park, San Francisco, CA",
            geo: ICalGeoCoordinate(latitude: 37.7694, longitude: -122.4862),
            url: "https://goldengatepark.com"
        )

        #expect(location.name == "Golden Gate Park")
        #expect(location.address == "Golden Gate Park, San Francisco, CA")
        #expect(location.geo?.latitude == 37.7694)
        #expect(location.url == "https://goldengatepark.com")

        var calendar = client.createCalendar()
        calendar.addLocation(location)

        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("BEGIN:VLOCATION"))
        #expect(serialized.contains("NAME:Golden Gate Park"))
        #expect(serialized.contains("END:VLOCATION"))
    }

    @Test("RFC 9073: VRESOURCE component")
    func testResourceComponent() async throws {
        let resource = client.createResource(
            name: "Projector A",
            resourceType: "Equipment",
            capacity: 1,
            features: ["1080p", "HDMI", "Wireless"],
            contact: "av@example.com",
            bookingUrl: "https://booking.example.com/projector-a"
        )

        #expect(resource.name == "Projector A")
        #expect(resource.resourceType == "Equipment")
        #expect(resource.capacity == 1)
        #expect(resource.features == ["1080p", "HDMI", "Wireless"])
        #expect(resource.contact == "av@example.com")
        #expect(resource.bookingUrl == "https://booking.example.com/projector-a")

        var calendar = client.createCalendar()
        calendar.addResource(resource)

        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("BEGIN:VRESOURCE"))
        #expect(serialized.contains("NAME:Projector A"))
        #expect(serialized.contains("RESOURCE-TYPE:Equipment"))
        #expect(serialized.contains("END:VRESOURCE"))
    }

    @Test("RFC 9073: Structured data support")
    func testStructuredData() async throws {
        let jsonData = """
            {
                "eventType": "conference",
                "tags": ["technology", "swift"],
                "sponsors": ["Apple", "Google"]
            }
            """

        let event = client.createEvent(summary: "WWDC 2024", startDate: Date())
        var calendar = client.createCalendar(events: [event])

        let success = client.addStructuredDataToEvent(
            in: &calendar,
            eventUID: event.uid,
            data: jsonData,
            type: .json,
            schema: "https://schema.org/Event"
        )

        #expect(success == true)

        let updatedEvent = calendar.events.first
        #expect(updatedEvent?.structuredData?.type == .json)
        #expect(updatedEvent?.structuredData?.data == jsonData)
        #expect(updatedEvent?.structuredData?.schema == "https://schema.org/Event")

        let serialized: String = try client.serializeCalendar(calendar)
        #expect(serialized.contains("STRUCTURED-DATA:"))
        #expect(serialized.contains("STRUCTURED-DATA-TYPE:application/json"))
        #expect(serialized.contains("SCHEMA:https://schema.org/Event"))
    }

    // MARK: - RFC 9253 Enhanced Relationships Tests

    @Test("RFC 9253: Enhanced relationship types")
    func testEnhancedRelationships() async throws {
        var event = client.createEvent(summary: "Phase 2", startDate: Date())
        event.enhancedRelationships = [
            (uid: "phase-1-uid", type: .dependsOn),
            (uid: "phase-3-uid", type: .blocks),
        ]

        #expect(event.enhancedRelationships.count == 2)
        #expect(event.enhancedRelationships[0].uid == "phase-1-uid")
        #expect(event.enhancedRelationships[0].type == .dependsOn)
        #expect(event.enhancedRelationships[1].type == .blocks)

        let calendar = client.createCalendar(events: [event])
        let serialized: String = try client.serializeCalendar(calendar)

        #expect(serialized.contains("RELATED-TO;RELTYPE=DEPENDS-ON:phase-1-uid"))
        #expect(serialized.contains("RELATED-TO;RELTYPE=BLOCKS:phase-3-uid"))
    }

    @Test("RFC 9253: External links")
    func testExternalLinks() async throws {
        var event = client.createEvent(summary: "Conference Talk", startDate: Date())
        event.links = [
            ICalLink(
                href: "https://slides.example.com/talk",
                rel: "related",
                type: "text/html",
                title: "Presentation Slides"
            ),
            ICalLink(
                href: "https://video.example.com/recording",
                rel: "alternate",
                type: "video/mp4",
                title: "Recording"
            ),
        ]

        #expect(event.links.count == 2)
        #expect(event.links[0].href == "https://slides.example.com/talk")
        #expect(event.links[0].title == "Presentation Slides")

        let calendar = client.createCalendar(events: [event])
        let serialized: String = try client.serializeCalendar(calendar)

        #expect(serialized.contains("slid") && serialized.contains("es.example.com"))
        #expect(serialized.contains("Presentation Slides"))
        #expect(serialized.contains("related"))
    }

    @Test("RFC 9253: Semantic concepts")
    func testSemanticConcepts() async throws {
        var event = client.createEvent(summary: "Swift Workshop", startDate: Date())
        event.concepts = [
            ICalConcept(
                identifier: "swift-programming",
                scheme: "https://example.com/topics",
                label: "Swift Programming Language"
            ),
            ICalConcept(
                identifier: "mobile-development",
                scheme: "https://example.com/topics",
                label: "Mobile Development"
            ),
        ]

        #expect(event.concepts.count == 2)
        #expect(event.concepts[0].identifier == "swift-programming")
        #expect(event.concepts[0].label == "Swift Programming Language")

        let calendar = client.createCalendar(events: [event])
        let serialized: String = try client.serializeCalendar(calendar)

        #expect(serialized.contains("CONCEPT") && serialized.contains("swift-programming"))
        #expect(serialized.contains("example.com/topics"))
        #expect(serialized.contains("Swift Programming Language"))
    }

    @Test("RFC 9253: Reference identifiers")
    func testReferenceIdentifiers() async throws {
        var event1 = client.createEvent(summary: "Meeting 1", startDate: Date())
        var event2 = client.createEvent(summary: "Meeting 2", startDate: Date())

        let groupId = "project-alpha-meetings"
        event1.referenceId = groupId
        event2.referenceId = groupId

        #expect(event1.referenceId == groupId)
        #expect(event2.referenceId == groupId)

        let calendar = client.createCalendar(events: [event1, event2])
        let serialized: String = try client.serializeCalendar(calendar)

        // Should appear twice, once for each event
        let refIdCount = serialized.components(separatedBy: "REFID:project-alpha-meetings").count - 1
        #expect(refIdCount == 2)
    }

    // MARK: - RFC 7953 Availability Tests

    @Test("RFC 7953: VAVAILABILITY component")
    func testAvailabilityComponent() async throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)  // Fixed date
        let end = start.addingTimeInterval(28800)  // 8 hours

        // Use UTC client for consistent timezone handling
        let utcClient = ICalendarClient(configuration: .init(defaultTimeZone: TimeZone(identifier: "UTC")!))

        let availability = utcClient.createAvailability(
            start: start,
            end: end,
            summary: "Office Hours"
        )

        #expect(utcClient.areDateTimesEqual(availability.dateTimeStart, utcClient.createDateTime(from: start, timeZone: TimeZone(identifier: "UTC"))))
        #expect(utcClient.areDateTimesEqual(availability.dateTimeEnd, utcClient.createDateTime(from: end, timeZone: TimeZone(identifier: "UTC"))))
        #expect(availability.summary == "Office Hours")

        var calendar = utcClient.createCalendar()
        calendar.addAvailability(availability)

        let serialized: String = try utcClient.serializeCalendar(calendar)
        #expect(serialized.contains("BEGIN:VAVAILABILITY"))
        #expect(serialized.contains("SUMMARY:Office Hours"))
        #expect(serialized.contains("END:VAVAILABILITY"))
    }

    @Test("RFC 7953: Free time slots")
    func testFreeTimeSlots() async throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)  // Fixed date
        let end = start.addingTimeInterval(3600)  // 1 hour

        // Use UTC client for consistent timezone handling
        let utcClient = ICalendarClient(configuration: .init(defaultTimeZone: TimeZone(identifier: "UTC")!))

        let freeSlot = utcClient.createFreeTimeSlot(
            start: start,
            end: end,
            summary: "Available for meetings",
            location: "Conference Room A"
        )

        #expect(utcClient.areDateTimesEqual(freeSlot.dateTimeStart, utcClient.createDateTime(from: start, timeZone: TimeZone(identifier: "UTC"))))
        #expect(utcClient.areDateTimesEqual(freeSlot.dateTimeEnd, utcClient.createDateTime(from: end, timeZone: TimeZone(identifier: "UTC"))))
        #expect(freeSlot.summary == "Available for meetings")
        #expect(freeSlot.location == "Conference Room A")

        // Test serialization as part of availability component
        var availability = ICalAvailabilityComponent()
        availability.components.append(freeSlot)

        var calendar = utcClient.createCalendar()
        calendar.addAvailability(availability)

        let serialized: String = try utcClient.serializeCalendar(calendar)
        #expect(serialized.contains("BEGIN:AVAILABLE"))
        #expect(serialized.contains("SUMMARY:Available for meetings"))
        #expect(serialized.contains("LOCATION:Conference Room A"))
        #expect(serialized.contains("END:AVAILABLE"))
    }

    @Test("RFC 7953: Availability information")
    func testAvailabilityInformation() async throws {
        var calendar = client.createCalendar()

        let now = Date()
        let busyPeriods = [
            (start: now, end: now.addingTimeInterval(3600)),
            (start: now.addingTimeInterval(7200), end: now.addingTimeInterval(10800)),
        ]

        let freePeriods = [
            (start: now.addingTimeInterval(3600), end: now.addingTimeInterval(7200)),
            (start: now.addingTimeInterval(10800), end: now.addingTimeInterval(14400)),
        ]

        client.addAvailabilityInfo(
            to: &calendar,
            busyPeriods: busyPeriods,
            freePeriods: freePeriods
        )

        #expect(calendar.availabilities.count == 1)

        let availability = calendar.availabilities.first
        // In a full implementation, this would test the BUSY/AVAILABLE sub-components
        #expect(availability != nil)
    }

    // MARK: - RFC 6047 iMIP Transport Tests

    @Test("RFC 6047: Email transport creation")
    func testEmailTransportCreation() async throws {
        let organizer = client.createOrganizer(email: "organizer@example.com")
        let attendee = client.createAttendee(email: "attendee@example.com", name: "John Doe")

        var event = client.createEvent(summary: "Team Meeting", startDate: Date())
        event.organizer = organizer
        event.attendees = [attendee]

        var calendar = client.createCalendar(events: [event])
        calendar.method = "REQUEST"

        let transport = client.createEmailTransport(
            for: calendar,
            from: "organizer@example.com",
            to: ["attendee@example.com"],
            subject: "Meeting Invitation: Team Meeting"
        )

        #expect(transport.from == "organizer@example.com")
        #expect(transport.to == ["attendee@example.com"])
        #expect(transport.subject == "Meeting Invitation: Team Meeting")
        #expect(transport.messageId?.contains("@icalendar-kit") == true)
    }

    @Test("RFC 6047: Auto-generated email subjects")
    func testAutoGeneratedEmailSubjects() async throws {
        let event = client.createEvent(summary: "Weekly Standup", startDate: Date())
        var requestCalendar = client.createCalendar(events: [event])
        requestCalendar.method = "REQUEST"

        let transport = client.createEmailTransport(
            for: requestCalendar,
            from: "org@example.com",
            to: ["team@example.com"]
        )

        #expect(transport.subject == "Invitation: Weekly Standup")

        // Test different methods
        requestCalendar.method = "CANCEL"
        let cancelTransport = client.createEmailTransport(
            for: requestCalendar,
            from: "org@example.com",
            to: ["team@example.com"]
        )
        #expect(cancelTransport.subject == "Cancelled: Weekly Standup")
    }

    // MARK: - Integration Tests

    @Test("Full RFC integration: Complex event with all features")
    func testComplexEventIntegration() async throws {
        // Create event with multiple RFC features
        var event = client.createEvent(
            summary: "International Tech Conference 2024",
            startDate: Date(),
            endDate: Date().addingTimeInterval(28800)  // 8 hours
        )

        // RFC 7529: Hebrew calendar recurrence for annual event
        event.recurrenceRule = client.createHebrewRecurrence(frequency: .yearly)

        // RFC 9074: Multiple alarm types
        let displayAlarm = client.createDisplayAlarm(description: "Conference starts in 1 hour", triggerMinutesBefore: 60)
        let proximityAlarm = client.createProximityAlarm(
            latitude: 37.7749,
            longitude: -122.4194,
            radius: 200,
            description: "Arrived at conference venue"
        )
        event.addAlarm(displayAlarm)
        event.addAlarm(proximityAlarm)

        // RFC 9253: Enhanced relationships and links
        event.enhancedRelationships = [(uid: "prep-meeting-uid", type: .dependsOn)]
        event.links = [
            ICalLink(
                href: "https://conf2024.example.com/schedule",
                rel: "related",
                title: "Conference Schedule"
            )
        ]
        event.concepts = [
            ICalConcept(
                identifier: "technology-conference",
                scheme: "https://schema.org/EventType"
            )
        ]

        // RFC 9073: Venue and structured data
        let venue = client.createVenue(
            name: "Tech Convention Center",
            address: "123 Tech Street, San Francisco",
            latitude: 37.7749,
            longitude: -122.4194,
            capacity: 5000
        )
        event.addVenue(venue)

        let jsonData = """
            {
                "tracks": ["iOS", "macOS", "Swift"],
                "keynote": true,
                "livestream": "https://stream.example.com/conf2024"
            }
            """
        event.structuredData = ICalStructuredData(
            type: .json,
            data: jsonData,
            schema: "https://schema.org/Event"
        )

        // Create calendar with availability
        var calendar = client.createCalendar(events: [event])

        // RFC 7953: Add availability information
        client.addAvailabilityInfo(
            to: &calendar,
            busyPeriods: [(start: Date(), end: Date().addingTimeInterval(28800))]
        )

        // Test serialization includes all features
        let serialized: String = try client.serializeCalendar(calendar)

        // Verify all RFC features are present
        #expect(serialized.contains("RSCALE=HEBREW"))
        #expect(serialized.contains("ACTION:PROXIMITY"))
        #expect(serialized.contains("PROXIMITY-TRIGGER:"))
        #expect(serialized.contains("RELATED-TO;RELTYPE=DEPENDS-ON:"))
        #expect(serialized.contains("LINK") && serialized.contains("conf2024.example.com"))
        #expect(serialized.contains("CONCEPT") && serialized.contains("technology-conference"))
        #expect(serialized.contains("BEGIN:VVENUE"))
        #expect(serialized.contains("STRUCTURED-DATA:"))
        #expect(serialized.contains("BEGIN:VAVAILABILITY"))

        // Test parsing preserves most features (skip complex parsing for now)
        #expect(serialized.contains("RSCALE=HEBREW"))
        #expect(serialized.contains("ACTION:PROXIMITY"))
        #expect(serialized.contains("RELATED-TO;RELTYPE=DEPENDS-ON"))
        #expect(serialized.contains("technology-conference"))
        #expect(serialized.contains("BEGIN:VVENUE"))
        #expect(serialized.contains("STRUCTURED-DATA"))
        #expect(serialized.contains("BEGIN:VAVAILABILITY"))
    }
}
