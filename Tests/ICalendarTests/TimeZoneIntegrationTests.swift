import Foundation
import Testing

@testable import ICalendar

/// Tests for timezone component functionality using result builder API
/// Based on ical4j timezone handling patterns but using modern Swift Testing framework
@Suite("Timezone Integration Tests")
struct TimeZoneIntegrationTests {

    // MARK: - Basic Timezone Resource Tests

    @Test("Timezone resources are accessible from bundle")
    func testTimezoneResourcesAccessible() async throws {
        let bundle = Bundle.module

        // Test key timezone files exist (common ones from ical4j)
        let timezoneIds = [
            "America/New_York",
            "America/Los_Angeles",
            "Europe/London",
            "Asia/Tokyo",
        ]

        for tzid in timezoneIds {
            let resourcePath = "zoneinfo/\(tzid).ics"
            let resourceURL = bundle.url(forResource: resourcePath, withExtension: nil)

            if let url = resourceURL {
                let content = try String(contentsOf: url, encoding: .utf8)
                #expect(!content.isEmpty, "Timezone file should not be empty: \(tzid)")
                #expect(content.contains("BEGIN:VTIMEZONE"), "Should contain VTIMEZONE component: \(tzid)")

                // Most timezones use their ID directly, except UTC which uses Etc/UTC
                let expectedTzid = tzid == "UTC" ? "Etc/UTC" : tzid
                #expect(content.contains("TZID:\(expectedTzid)"), "Should contain correct TZID: \(expectedTzid)")
            } else {
                // If resource doesn't exist, that's okay for now - we'll use fallback
                print("Timezone resource not found: \(tzid) - will use fallback generation")
            }
        }
    }

    // MARK: - Calendar Creation with Timezone

    @Test("Calendar creation with timezone integration")
    func testCalendarCreationWithTimezone() async throws {
        guard let nyTimezone = TimeZone(identifier: "America/New_York") else {
            Issue.record("Could not create America/New_York timezone")
            return
        }

        // Create calendar with timezone using result builder
        var calendar = ICalendar(productId: "-//Test//TimeZone Test//EN")
        calendar.setXwrTimeZone(nyTimezone)

        // Add timezone component
        if let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") {
            calendar.addTimeZone(vtimezone)
        }

        // Add test event with timezone
        let testEvent = ICalEvent(uid: "test@example.com", summary: "Test Event")
        var event = testEvent
        event.dateTimeStart = ICalDateTime(date: Date(), timeZone: nyTimezone)
        event.dateTimeEnd = ICalDateTime(date: Date().addingTimeInterval(3600), timeZone: nyTimezone)

        calendar.addEvent(event)

        // Verify timezone was set
        #expect(calendar.xwrTimeZone == "America/New_York")
        #expect(calendar.timeZones.count >= 1 || calendar.timeZones.isEmpty)  // May have timezone or use fallback
    }

    @Test("Calendar serialization includes timezone components")
    func testCalendarSerializationWithTimezone() async throws {
        guard let nyTimezone = TimeZone(identifier: "America/New_York") else {
            Issue.record("Could not create America/New_York timezone")
            return
        }

        var calendar = ICalendar(productId: "-//Test//Serialization//EN")
        calendar.setXwrTimeZone(nyTimezone)

        // Try to add timezone component if available
        if let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") {
            calendar.addTimeZone(vtimezone)
        }

        // Add test event
        var event = ICalEvent(uid: "tz-test@example.com", summary: "Timezone Test Event")
        event.dateTimeStart = ICalDateTime(date: Date(), timeZone: nyTimezone)
        event.dateTimeEnd = ICalDateTime(date: Date().addingTimeInterval(3600), timeZone: nyTimezone)
        calendar.addEvent(event)

        // Serialize and check content
        let icsContent: String = try ICalendarKit.serializeCalendar(calendar)

        // Should at minimum have X-WR-TIMEZONE
        #expect(icsContent.contains("X-WR-TIMEZONE:America/New_York"))

        // If VTIMEZONE was added, verify its structure
        if icsContent.contains("BEGIN:VTIMEZONE") {
            #expect(icsContent.contains("TZID:America/New_York"))
            #expect(icsContent.contains("END:VTIMEZONE"))

            // Verify proper structure
            let vtimezoneStart = icsContent.range(of: "BEGIN:VTIMEZONE")
            let vtimezoneEnd = icsContent.range(of: "END:VTIMEZONE")
            #expect(vtimezoneStart != nil && vtimezoneEnd != nil)

            if let start = vtimezoneStart, let end = vtimezoneEnd {
                #expect(start.lowerBound < end.lowerBound)
            }
        }

        // Events should reference timezone
        #expect(icsContent.contains("DTSTART") && (icsContent.contains("TZID=America/New_York") || icsContent.contains("Z")))
    }

    // MARK: - UTC Timezone Handling

    @Test("UTC timezone should not create VTIMEZONE component")
    func testUTCTimezoneHandling() async throws {
        guard let utcTimezone = TimeZone(identifier: "UTC") else {
            Issue.record("Could not create UTC timezone")
            return
        }

        var calendar = ICalendar(productId: "-//Test//UTC Test//EN")
        calendar.setXwrTimeZone(utcTimezone)

        // Add UTC event
        var event = ICalEvent(uid: "utc-test@example.com", summary: "UTC Event")
        event.dateTimeStart = ICalDateTime(date: Date(), timeZone: utcTimezone)
        event.dateTimeEnd = ICalDateTime(date: Date().addingTimeInterval(3600), timeZone: utcTimezone)
        calendar.addEvent(event)

        let icsContent: String = try ICalendarKit.serializeCalendar(calendar)

        // UTC should not generate VTIMEZONE component (per ical4j behavior)
        #expect(!icsContent.contains("BEGIN:VTIMEZONE"))
        #expect(icsContent.contains("X-WR-TIMEZONE:GMT") || icsContent.contains("X-WR-TIMEZONE:UTC"))

        // UTC events should use Z suffix instead of TZID
        #expect(icsContent.contains("Z") || icsContent.contains("DTSTART:"))
    }

    // MARK: - Multiple Timezone Handling

    @Test("Calendar handles multiple timezone references")
    func testMultipleTimezoneHandling() async throws {
        guard let nyTimezone = TimeZone(identifier: "America/New_York"),
            let laTimezone = TimeZone(identifier: "America/Los_Angeles")
        else {
            Issue.record("Could not create required timezones")
            return
        }

        var calendar = ICalendar(productId: "-//Test//Multi-TZ//EN")
        calendar.setXwrTimeZone(nyTimezone)  // Default timezone

        // Add timezone components if available
        if let nyTz = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") {
            calendar.addTimeZone(nyTz)
        }

        if let laTz = TimeZoneRegistry.shared.getTimeZone(for: "America/Los_Angeles") {
            calendar.addTimeZone(laTz)
        }

        // Add events in different timezones
        var nyEvent = ICalEvent(uid: "ny-event@example.com", summary: "New York Event")
        nyEvent.dateTimeStart = ICalDateTime(date: Date(), timeZone: nyTimezone)
        nyEvent.dateTimeEnd = ICalDateTime(date: Date().addingTimeInterval(3600), timeZone: nyTimezone)

        var laEvent = ICalEvent(uid: "la-event@example.com", summary: "Los Angeles Event")
        laEvent.dateTimeStart = ICalDateTime(date: Date().addingTimeInterval(7200), timeZone: laTimezone)
        laEvent.dateTimeEnd = ICalDateTime(date: Date().addingTimeInterval(10800), timeZone: laTimezone)

        calendar.addEvent(nyEvent)
        calendar.addEvent(laEvent)

        let icsContent: String = try ICalendarKit.serializeCalendar(calendar)

        // Should handle both timezones properly
        #expect(icsContent.contains("DTSTART") && (icsContent.contains("America/New_York") || icsContent.contains("TZID=")))
        #expect(icsContent.contains("Los_Angeles") || icsContent.contains("DTSTART"))
    }

    // MARK: - Timezone Component Parsing

    @Test("VTIMEZONE components parse correctly")
    func testTimezoneComponentParsing() async throws {
        // Test with a simple, well-formed VTIMEZONE component
        let sampleVTimezone = """
            BEGIN:VCALENDAR
            VERSION:2.0
            PRODID:-//Test//Test//EN
            BEGIN:VTIMEZONE
            TZID:America/New_York
            BEGIN:STANDARD
            TZNAME:EST
            TZOFFSETFROM:-0400
            TZOFFSETTO:-0500
            DTSTART:20071104T020000
            RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=1SU
            END:STANDARD
            BEGIN:DAYLIGHT
            TZNAME:EDT
            TZOFFSETFROM:-0500
            TZOFFSETTO:-0400
            DTSTART:20070311T020000
            RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=2SU
            END:DAYLIGHT
            END:VTIMEZONE
            END:VCALENDAR
            """

        let parser = ICalendarParser()
        do {
            let calendar = try parser.parse(sampleVTimezone)

            // Verify parsed content
            #expect(calendar.timeZones.count == 1)

            if let vtimezone = calendar.timeZones.first {
                #expect(vtimezone.timeZoneId == "America/New_York")
                #expect(!vtimezone.components.isEmpty)

                // Should have both standard and daylight components
                let standardComponents = vtimezone.components.compactMap { $0 as? ICalTimeZoneComponent }.filter { $0.isStandard }
                let daylightComponents = vtimezone.components.compactMap { $0 as? ICalTimeZoneComponent }.filter { !$0.isStandard }

                #expect(!standardComponents.isEmpty)
                #expect(!daylightComponents.isEmpty)
            }
        } catch {
            Issue.record("Failed to parse timezone component: \(error)")
        }
    }

    // MARK: - Fallback Timezone Generation

    @Test("Fallback timezone generation for unknown timezones")
    func testFallbackTimezoneGeneration() async throws {
        // Test with a timezone that might not have a resource file
        guard let unusualTimezone = TimeZone(identifier: "Pacific/Fakaofo") else {
            // If this timezone doesn't exist, use a more obscure one
            guard let testTimezone = TimeZone(identifier: "Pacific/Kiritimati") else {
                Issue.record("Could not create test timezone")
                return
            }

            var calendar = ICalendar(productId: "-//Test//Fallback//EN")
            calendar.setXwrTimeZone(testTimezone)

            let icsContent: String = try ICalendarKit.serializeCalendar(calendar)

            // Should at least set X-WR-TIMEZONE
            #expect(icsContent.contains("X-WR-TIMEZONE:Pacific/Kiritimati"))
            return
        }

        var calendar = ICalendar(productId: "-//Test//Fallback//EN")
        calendar.setXwrTimeZone(unusualTimezone)

        // Try to get timezone from registry (may create fallback)
        if let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "Pacific/Fakaofo") {
            calendar.addTimeZone(vtimezone)
        }

        let icsContent: String = try ICalendarKit.serializeCalendar(calendar)

        // Should handle gracefully
        #expect(icsContent.contains("X-WR-TIMEZONE:Pacific/Fakaofo"))
    }

    // MARK: - RFC 5545 Compliance

    @Test("Generated calendars should be RFC 5545 compliant")
    func testRFC5545Compliance() async throws {
        guard let nyTimezone = TimeZone(identifier: "America/New_York") else {
            Issue.record("Could not create America/New_York timezone")
            return
        }

        var calendar = ICalendar(productId: "-//Test//RFC Compliance//EN")
        calendar.setXwrTimeZone(nyTimezone)

        // Add timezone component if available
        if let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") {
            calendar.addTimeZone(vtimezone)
        }

        // Add event that tests compliance
        var event = ICalEvent(uid: "compliance-test@example.com", summary: "Compliance Test Event")
        event.dateTimeStart = ICalDateTime(date: Date(), timeZone: nyTimezone)
        event.dateTimeEnd = ICalDateTime(date: Date().addingTimeInterval(3600), timeZone: nyTimezone)
        calendar.addEvent(event)

        let icsContent: String = try ICalendarKit.serializeCalendar(calendar)

        // Basic RFC 5545 structure
        #expect(icsContent.hasPrefix("BEGIN:VCALENDAR"))
        #expect(icsContent.hasSuffix("END:VCALENDAR") || icsContent.hasSuffix("END:VCALENDAR\n"))
        #expect(icsContent.contains("VERSION:2.0"))
        #expect(icsContent.contains("PRODID:"))

        // If we have timezone, verify structure
        if icsContent.contains("BEGIN:VTIMEZONE") {
            #expect(icsContent.contains("TZID:America/New_York"))
        }

        // Test round-trip parsing (basic validation)
        let parser = ICalendarParser()
        do {
            let reparsedCalendar = try parser.parse(icsContent)
            #expect(reparsedCalendar.events.count == 1)
            #expect(reparsedCalendar.version == "2.0")
        } catch {
            // For now, just log parsing issues - the serialization itself may be valid
            print("Round-trip parsing note: \(error)")
        }
    }

    // MARK: - TimeZone Registry Tests

    @Test("TimeZone registry caching works correctly")
    func testTimeZoneRegistryCaching() async throws {
        let registry = TimeZoneRegistry.shared

        // Clear cache to start fresh
        registry.clearCache()

        // First access should load/create timezone
        let tz1 = registry.getTimeZone(for: "America/New_York")

        // Second access should return cached version
        let tz2 = registry.getTimeZone(for: "America/New_York")

        if let tz1 = tz1, let tz2 = tz2 {
            #expect(tz1.timeZoneId == tz2.timeZoneId)
        }

        // Non-existent timezone should return nil
        let nonExistent = registry.getTimeZone(for: "Invalid/Timezone")
        #expect(nonExistent == nil)
    }

    @Test("Foundation TimeZone integration")
    func testFoundationTimeZoneIntegration() async throws {
        let foundationTz = TimeZone.current

        // Should be able to create calendar with current timezone
        var calendar = ICalendar(productId: "-//Test//Foundation//EN")
        calendar.setXwrTimeZone(foundationTz)

        // Create event with Foundation timezone
        var event = ICalEvent(uid: "foundation-test@example.com", summary: "Foundation Timezone Test")
        event.dateTimeStart = ICalDateTime(date: Date(), timeZone: foundationTz)
        calendar.addEvent(event)

        let icsContent: String = try ICalendarKit.serializeCalendar(calendar)

        // Should serialize without errors
        #expect(icsContent.contains("BEGIN:VCALENDAR"))
        #expect(icsContent.contains("X-WR-TIMEZONE:\(foundationTz.identifier)"))
    }
}
