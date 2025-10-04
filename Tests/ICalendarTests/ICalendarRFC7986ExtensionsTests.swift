import Foundation
import Testing

@testable import ICalendar

struct ICalendarRFC7986ExtensionsTests {

    // MARK: - Calendar Level Properties Tests

    @Test("Calendar NAME property")
    func testCalendarNameProperty() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        // Test setting and getting name
        calendar.name = "My Personal Calendar"
        #expect(calendar.name == "My Personal Calendar")

        // Test serialization includes name
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("NAME:My Personal Calendar"))
    }

    @Test("Calendar DESCRIPTION property")
    func testCalendarDescriptionProperty() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        // Test setting and getting calendar description
        calendar.calendarDescription = "Personal events and appointments"
        #expect(calendar.calendarDescription == "Personal events and appointments")

        // Test serialization includes description
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("DESCRIPTION:Personal events and appointments"))
    }

    @Test("Calendar COLOR property")
    func testCalendarColorProperty() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        // Test setting and getting color
        calendar.color = "blue"
        #expect(calendar.color == "blue")

        // Test serialization includes color
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("COLOR:blue"))
    }

    @Test("Calendar REFRESH-INTERVAL property")
    func testRefreshIntervalProperty() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        // Test creating and setting refresh interval
        let interval = ICalDuration(days: 7)
        calendar.refreshInterval = interval
        #expect(calendar.refreshInterval?.days == 7)

        // Test serialization includes refresh interval
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("REFRESH-INTERVAL"))
        #expect(serialized.contains("P7D"))
    }

    @Test("Calendar SOURCE property")
    func testSourceProperty() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        // Test setting and getting source
        let sourceURL = "https://example.com/calendar.ics"
        calendar.source = sourceURL
        #expect(calendar.source == sourceURL)

        // Test serialization includes source
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("SOURCE:\(sourceURL)"))
    }

    @Test("Calendar IMAGE property")
    func testCalendarImageProperty() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        // Test setting and getting image
        calendar.image = "https://example.com/image1.png"
        #expect(calendar.image == "https://example.com/image1.png")

        // Test serialization includes image
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("IMAGE:https://example.com/image1.png"))
    }

    // MARK: - X-WR Extension Properties Tests

    @Test("X-WR-CALNAME property")
    func testXWRDisplayNameProperty() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        // Test setting and getting display name
        calendar.displayName = "Work Calendar"
        #expect(calendar.displayName == "Work Calendar")

        // Test serialization includes X-WR-CALNAME
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("X-WR-CALNAME:Work Calendar"))
    }

    @Test("X-WR-CALDESC property")
    func testXWRDescriptionProperty() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        // Test setting and getting X-WR description
        calendar.xwrDescription = "Calendar for work-related events"
        #expect(calendar.xwrDescription == "Calendar for work-related events")

        // Test serialization includes X-WR-CALDESC
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("X-WR-CALDESC:Calendar for work-related events"))
    }

    @Test("X-WR-TIMEZONE property")
    func testXWRTimeZoneProperty() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        // Test setting and getting X-WR timezone
        calendar.xwrTimeZone = "America/New_York"
        #expect(calendar.xwrTimeZone == "America/New_York")

        // Test serialization includes X-WR-TIMEZONE
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("X-WR-TIMEZONE:America/New_York"))
    }

    @Test("X-WR-RELCALID property")
    func testRelatedCalendarIdProperty() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        // Test setting and getting related calendar ID
        let relatedID = "related-calendar-123"
        calendar.relatedCalendarId = relatedID
        #expect(calendar.relatedCalendarId == relatedID)

        // Test serialization includes X-WR-RELCALID
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("X-WR-RELCALID:\(relatedID)"))
    }

    @Test("X-PUBLISHED-TTL property")
    func testPublishedTTLProperty() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        // Test setting and getting published TTL
        calendar.publishedTTL = "PT1H"
        #expect(calendar.publishedTTL == "PT1H")

        // Test serialization includes X-PUBLISHED-TTL
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("X-PUBLISHED-TTL:PT1H"))
    }

    // MARK: - Event Extension Properties Tests

    @Test("Event COLOR property")
    func testEventColorProperty() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        var event = ICalEvent(uid: "test@example.com", summary: "Test Event")
        event.color = "red"
        calendar.addEvent(event)

        let retrievedEvent = calendar.events.first!
        #expect(retrievedEvent.color == "red")

        // Test serialization includes event color
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("COLOR:red"))
    }

    @Test("Event IMAGE property")
    func testEventImageProperty() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        var event = ICalEvent(uid: "conference@example.com", summary: "Conference")
        event.image = "https://example.com/conference-logo.png"
        calendar.addEvent(event)

        let retrievedEvent = calendar.events.first!
        #expect(retrievedEvent.image == "https://example.com/conference-logo.png")

        // Test serialization includes event image
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("IMAGE:https://example.com/conference-logo.png"))
    }

    @Test("Event CONFERENCE property")
    func testEventConferenceProperty() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        var event = ICalEvent(uid: "meeting@example.com", summary: "Team Meeting")
        event.properties.append(ICalProperty(name: "CONFERENCE", value: "https://meet.example.com/room/abc123"))
        calendar.addEvent(event)

        // Test serialization includes conference information
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("CONFERENCE:https://meet.example.com/room/abc123"))
    }

    @Test("Event GEO property")
    func testEventGeoProperty() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        var event = ICalEvent(uid: "outdoor@example.com", summary: "Outdoor Event")
        event.location = "Central Park"
        event.properties.append(ICalProperty(name: "GEO", value: "40.785091;-73.968285"))
        calendar.addEvent(event)

        let retrievedEvent = calendar.events.first!
        #expect(retrievedEvent.geo?.latitude == 40.785091)
        #expect(retrievedEvent.geo?.longitude == -73.968285)

        // Test serialization includes geo coordinates
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("GEO:40.785091\\;-73.968285"))
    }

    // MARK: - Complete Integration Tests

    @Test("Create calendar with all extensions")
    func testCreateCalendarWithExtensions() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")
        calendar.name = "My Extended Calendar"
        calendar.calendarDescription = "A calendar with all the new features"
        calendar.color = "green"
        calendar.displayName = "Extended Cal"
        calendar.setXwrTimeZone(TimeZone(identifier: "America/Los_Angeles")!)
        calendar.refreshInterval = ICalDuration(hours: 1)
        calendar.source = "https://example.com/calendar.ics"

        #expect(calendar.name == "My Extended Calendar")
        #expect(calendar.calendarDescription == "A calendar with all the new features")
        #expect(calendar.color == "green")
        #expect(calendar.displayName == "Extended Cal")
        #expect(calendar.xwrTimeZone == "America/Los_Angeles")

        #expect(calendar.refreshInterval?.hours == 1)
        #expect(calendar.source == "https://example.com/calendar.ics")
    }

    @Test("X-WR-TIMEZONE integration with Foundation TimeZone")
    func testXWRTimeZoneIntegration() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        if let tz = TimeZone(identifier: "Pacific/Auckland") {
            calendar.setXwrTimeZone(tz)
            #expect(calendar.xwrTimeZone == "Pacific/Auckland")

            // Test round-trip
            let retrievedTZ = calendar.xwrFoundationTimeZone
            #expect(retrievedTZ?.identifier == "Pacific/Auckland")
        }

        if let tz = TimeZone(identifier: "America/Los_Angeles") {
            calendar.setXwrTimeZone(tz)
            let serialized: String = try ICalendarKit.serializeCalendar(calendar)
            #expect(serialized.contains("X-WR-TIMEZONE:America/Los_Angeles"))
        }
    }

    // MARK: - Exception Dates Tests

    // MARK: - Exception Dates Tests

    @Test("Event exception dates functionality")
    func testEventExceptionDates() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")
        var event = ICalEvent(uid: "recurring@example.com", summary: "Recurring Meeting")

        // Test setting exception dates
        let exceptionDate1 = Date()
        let exceptionDate2 = Calendar.current.date(byAdding: .day, value: 7, to: exceptionDate1) ?? exceptionDate1

        event.exceptionDates = [ICalDateTime(date: exceptionDate1, timeZone: .current), ICalDateTime(date: exceptionDate2, timeZone: .current)]
        calendar.addEvent(event)

        let retrievedEvent = calendar.events.first!
        #expect(retrievedEvent.exceptionDates.count == 2)

        // Test serialization includes EXDATE
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("EXDATE"))
    }

    @Test("Event recurring with exception dates")
    func testRecurringWithExceptionDates() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        let startDate = Date()
        var event = ICalEvent(
            uid: "weekly-meeting@example.com",
            summary: "Weekly Team Meeting"
        )
        event.dateTimeStart = ICalDateTime(date: startDate, timeZone: .current)
        event.dateTimeEnd = ICalDateTime(date: startDate.addingTimeInterval(3600), timeZone: .current)

        // Add weekly recurrence
        let recurrenceRule = ICalRecurrenceRule(frequency: .weekly)
        event.recurrenceRule = recurrenceRule

        // Add exception dates for holidays
        let holiday1 = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate
        let holiday2 = Calendar.current.date(byAdding: .day, value: 14, to: startDate) ?? startDate
        event.exceptionDates = [ICalDateTime(date: holiday1, timeZone: .current), ICalDateTime(date: holiday2, timeZone: .current)]

        calendar.addEvent(event)

        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("RRULE:FREQ=WEEKLY"))
        #expect(serialized.contains("EXDATE"))
    }

    // MARK: - LOCATION and GEO Integration Tests

    @Test("Location with geo coordinates")
    func testLocationWithGeoCoordinates() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")
        var event = ICalEvent(uid: "conference@example.com", summary: "Annual Conference")

        event.location = "Convention Center, New York"
        event.geo = ICalGeoCoordinate(latitude: 40.7589, longitude: -73.9851)

        calendar.addEvent(event)

        let retrievedEvent = calendar.events.first!
        #expect(retrievedEvent.location == "Convention Center, New York")
        #expect(retrievedEvent.geo?.latitude == 40.7589)
        #expect(retrievedEvent.geo?.longitude == -73.9851)

        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("LOCATION:Convention Center\\, New York"))
        #expect(serialized.contains("GEO:40.758900\\;-73.985100"))
    }

    // MARK: - Complex Integration Tests

    @Test("Calendar with all RFC 7986 properties")
    func testCompleteRFC7986Calendar() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986Complete//EN")

        // Set all calendar-level RFC 7986 properties
        calendar.name = "Complete Test Calendar"
        calendar.calendarDescription = "Calendar testing all RFC 7986 features"
        calendar.color = "#FF5722"
        calendar.displayName = "RFC 7986 Test"
        calendar.xwrDescription = "Extended description for X-WR-CALDESC"
        calendar.xwrTimeZone = "America/New_York"
        calendar.relatedCalendarId = "parent-calendar-123"
        calendar.publishedTTL = "P1D"
        calendar.refreshInterval = ICalDuration(hours: 6)
        calendar.source = "https://example.com/rfc7986-calendar.ics"
        calendar.image = "https://example.com/calendar-image.png"

        // Add an event with RFC 7986 properties
        var event = ICalEvent(uid: "complete-event@example.com", summary: "Complete Event")
        event.dateTimeStart = ICalDateTime(date: Date(), timeZone: .current)
        event.dateTimeEnd = ICalDateTime(date: Date().addingTimeInterval(3600), timeZone: .current)
        event.location = "Test Location"
        event.geo = ICalGeoCoordinate(latitude: 37.7749, longitude: -122.4194)
        event.color = "blue"
        event.image = "https://example.com/event-image.png"
        event.properties.append(ICalProperty(name: "CONFERENCE", value: "https://meet.example.com/test", parameters: ["VALUE": "URI"]))

        calendar.addEvent(event)

        // Verify all properties are set
        #expect(calendar.name == "Complete Test Calendar")
        #expect(calendar.calendarDescription == "Calendar testing all RFC 7986 features")
        #expect(calendar.color == "#FF5722")
        #expect(calendar.displayName == "RFC 7986 Test")
        #expect(calendar.xwrTimeZone == "America/New_York")
        #expect(calendar.refreshInterval?.hours == 6)

        let retrievedEvent = calendar.events.first!
        #expect(retrievedEvent.color == "blue")
        #expect(retrievedEvent.image == "https://example.com/event-image.png")
        #expect(retrievedEvent.geo?.latitude == 37.7749)

        // Test serialization includes all properties
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("NAME:Complete Test Calendar"))
        #expect(serialized.contains("DESCRIPTION:Calendar testing all RFC 7986 features"))
        #expect(serialized.contains("COLOR:#FF5722"))
        #expect(serialized.contains("X-WR-CALNAME:RFC 7986 Test"))
        #expect(serialized.contains("X-WR-TIMEZONE:America/New_York"))
        #expect(serialized.contains("REFRESH-INTERVAL:PT6H"))
        #expect(serialized.contains("SOURCE:https://example.com/rfc7986-calendar.ics"))
        #expect(serialized.contains("IMAGE:https://example.com/calendar-image.png"))
        #expect(serialized.contains("COLOR:blue"))  // Event color
        #expect(serialized.contains("GEO:37.774900\\;-122.419400"))
        #expect(serialized.contains("CONFERENCE;VALUE=URI:https://meet.example.com/test"))
    }

    // MARK: - Edge Cases and Validation Tests

    @Test("Empty and nil property handling")
    func testEmptyPropertyHandling() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        // Test empty string handling
        calendar.name = ""
        calendar.color = ""
        calendar.displayName = ""

        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        // Empty properties should still be serialized
        #expect(serialized.contains("NAME:"))
        #expect(serialized.contains("COLOR:"))
        #expect(serialized.contains("X-WR-CALNAME:"))
    }

    @Test("Special characters in RFC 7986 properties")
    func testSpecialCharactersInProperties() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        // Test international characters and special symbols
        calendar.name = "Calendario de José María"
        calendar.calendarDescription = "Description with \"quotes\" and \nnewlines"
        calendar.displayName = "Cal with émojis 📅"

        #expect(calendar.name == "Calendario de José María")
        #expect(calendar.displayName == "Cal with émojis 📅")

        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(serialized.contains("Calendario de José María"))
        #expect(serialized.contains("📅"))
    }

    @Test("URL validation in source and image properties")
    func testURLValidation() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")

        // Test various URL formats
        let validURLs = [
            "https://example.com/calendar.ics",
            "http://calendar.example.org/feed.ics",
            "webcal://calendar.example.com/public.ics",
        ]

        for url in validURLs {
            calendar.source = url
            #expect(calendar.source == url)

            calendar.image = url
            #expect(calendar.image == url)
        }
    }

    // MARK: - Performance and Large Data Tests

    @Test("Large calendar with many RFC 7986 properties")
    func testLargeCalendarPerformance() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986Large//EN")
        calendar.name = "Large Performance Test Calendar"
        calendar.color = "purple"
        calendar.refreshInterval = ICalDuration(minutes: 30)

        // Add many events with RFC 7986 properties
        for i in 1...100 {
            var event = ICalEvent(uid: "event-\(i)@example.com", summary: "Event \(i)")
            event.dateTimeStart = ICalDateTime(date: Date().addingTimeInterval(TimeInterval(i * 3600)), timeZone: .current)
            event.dateTimeEnd = ICalDateTime(date: Date().addingTimeInterval(TimeInterval(i * 3600 + 1800)), timeZone: .current)
            event.color = i % 2 == 0 ? "red" : "blue"
            event.image = "https://example.com/event-\(i).png"

            if i % 10 == 0 {
                event.geo = ICalGeoCoordinate(latitude: Double(40 + i), longitude: Double(-70 - i))
            }

            calendar.addEvent(event)
        }

        #expect(calendar.events.count == 100)

        // Test that serialization completes in reasonable time
        let startTime = Date()
        let serialized: String = try ICalendarKit.serializeCalendar(calendar)
        let elapsedTime = Date().timeIntervalSince(startTime)

        #expect(elapsedTime < 5.0)  // Should complete in under 5 seconds
        #expect(serialized.contains("Event 1"))
        #expect(serialized.contains("Event 100"))
        #expect(serialized.contains("COLOR:red"))
        #expect(serialized.contains("COLOR:blue"))
    }

    // MARK: - RFC 7986 Compliance Validation Tests

    @Test("RFC 7986 property names case sensitivity")
    func testPropertyNameCaseSensitivity() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986//EN")
        calendar.name = "Case Test Calendar"

        let serialized: String = try ICalendarKit.serializeCalendar(calendar)

        // RFC 7986 property names should be uppercase
        #expect(serialized.contains("NAME:"))
        #expect(!serialized.contains("name:"))
        #expect(!serialized.contains("Name:"))
    }

    @Test("RFC 7986 compliance with existing RFC 5545")
    func testRFC5545Compatibility() async throws {
        var calendar = ICalendar(productId: "Test//RFC7986Compat//EN")

        // Mix RFC 5545 and RFC 7986 properties
        calendar.name = "Compatibility Test"  // RFC 7986
        calendar.properties.append(ICalProperty(name: "METHOD", value: "PUBLISH"))  // RFC 5545
        calendar.color = "green"  // RFC 7986
        calendar.properties.append(ICalProperty(name: "CALSCALE", value: "GREGORIAN"))  // RFC 5545

        var event = ICalEvent(uid: "compat@example.com", summary: "Compatibility Event")
        event.dateTimeStart = ICalDateTime(date: Date(), timeZone: .current)  // RFC 5545
        event.color = "yellow"  // RFC 7986
        event.priority = 5  // RFC 5545
        event.image = "https://example.com/compat.png"  // RFC 7986

        calendar.addEvent(event)

        let serialized: String = try ICalendarKit.serializeCalendar(calendar)

        // Should contain both RFC 5545 and RFC 7986 properties
        #expect(serialized.contains("METHOD:PUBLISH"))  // RFC 5545
        #expect(serialized.contains("CALSCALE:GREGORIAN"))  // RFC 5545
        #expect(serialized.contains("NAME:Compatibility Test"))  // RFC 7986
        #expect(serialized.contains("COLOR:green"))  // RFC 7986 calendar
        #expect(serialized.contains("COLOR:yellow"))  // RFC 7986 event
        #expect(serialized.contains("PRIORITY:5"))  // RFC 5545
        #expect(serialized.contains("IMAGE:https://example.com/compat.png"))  // RFC 7986
    }
}
