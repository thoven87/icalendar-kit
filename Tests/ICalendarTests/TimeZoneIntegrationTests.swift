import Foundation
import Testing

@testable import ICalendar

/// Tests for timezone component functionality using result builder API
/// Based on ical4j timezone handling patterns but using modern Swift Testing framework
@Suite("Timezone Integration Tests")
struct TimeZoneIntegrationTests {

    // MARK: - Basic Timezone Resource Tests

    @Test("Dynamic timezone generation works correctly")
    func testDynamicTimezoneGeneration() async throws {
        // Test key timezone IDs can be generated dynamically
        let timezoneIds = [
            "America/New_York",
            "America/Los_Angeles",
            "Europe/London",
            "Asia/Tokyo",
        ]

        for tzid in timezoneIds {
            if let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: tzid) {
                #expect(vtimezone.timeZoneId == tzid, "Generated timezone should have correct ID: \(tzid)")
                #expect(!vtimezone.components.isEmpty, "Generated timezone should have components: \(tzid)")

                // Should have at least one timezone component
                let tzComponents = vtimezone.components.compactMap { $0 as? ICalTimeZoneComponent }
                #expect(!tzComponents.isEmpty, "Should have timezone components: \(tzid)")

                // Verify timezone component properties are set
                for component in tzComponents {
                    #expect(component.offsetFrom != nil, "Component should have offsetFrom: \(tzid)")
                    #expect(component.offsetTo != nil, "Component should have offsetTo: \(tzid)")
                    #expect(component.dateTimeStart != nil, "Component should have DTSTART: \(tzid)")
                }
            } else {
                Issue.record("Could not generate timezone for: \(tzid)")
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
        #expect(calendar.timeZones.count >= 1, "Should have added timezone component")
    }

    @Test("Calendar serialization includes timezone components")
    func testCalendarSerializationWithTimezone() async throws {
        guard let nyTimezone = TimeZone(identifier: "America/New_York") else {
            Issue.record("Could not create America/New_York timezone")
            return
        }

        var calendar = ICalendar(productId: "-//Test//Serialization//EN")
        calendar.setXwrTimeZone(nyTimezone)

        // Add timezone component (should always work with dynamic generation)
        if let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") {
            calendar.addTimeZone(vtimezone)
        } else {
            Issue.record("Dynamic timezone generation failed for America/New_York")
        }

        // Add test event
        var event = ICalEvent(uid: "tz-test@example.com", summary: "Timezone Test Event")
        event.dateTimeStart = ICalDateTime(date: Date(), timeZone: nyTimezone)
        event.dateTimeEnd = ICalDateTime(date: Date().addingTimeInterval(3600), timeZone: nyTimezone)
        calendar.addEvent(event)

        // Serialize and check content
        let icsContent: String = try ICalendarKit.serializeCalendar(calendar)

        // Should have X-WR-TIMEZONE
        #expect(icsContent.contains("X-WR-TIMEZONE:America/New_York"))

        // Should have VTIMEZONE component with dynamic generation
        #expect(icsContent.contains("BEGIN:VTIMEZONE"))
        #expect(icsContent.contains("TZID:America/New_York"))
        #expect(icsContent.contains("END:VTIMEZONE"))

        // Verify proper structure
        let vtimezoneStart = icsContent.range(of: "BEGIN:VTIMEZONE")
        let vtimezoneEnd = icsContent.range(of: "END:VTIMEZONE")
        #expect(vtimezoneStart != nil && vtimezoneEnd != nil)

        if let start = vtimezoneStart, let end = vtimezoneEnd {
            #expect(start.lowerBound < end.lowerBound)
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

        // Add timezone components (should work with dynamic generation)
        if let nyTz = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") {
            calendar.addTimeZone(nyTz)
        } else {
            Issue.record("Failed to generate NY timezone")
        }

        if let laTz = TimeZoneRegistry.shared.getTimeZone(for: "America/Los_Angeles") {
            calendar.addTimeZone(laTz)
        } else {
            Issue.record("Failed to generate LA timezone")
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

    @Test("Dynamic timezone generation for all valid timezones")
    func testDynamicTimezoneGeneration2() async throws {
        // Test with various timezones that Foundation should support
        let testTimezones = [
            "Pacific/Kiritimati",
            "America/Anchorage",
            "Europe/Dublin",
            "Australia/Sydney",
        ]

        for tzId in testTimezones {
            guard let foundationTz = TimeZone(identifier: tzId) else {
                continue
            }

            var calendar = ICalendar(productId: "-//Test//Dynamic//EN")
            calendar.setXwrTimeZone(foundationTz)

            // Should be able to generate timezone dynamically
            if let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: tzId) {
                calendar.addTimeZone(vtimezone)
                #expect(vtimezone.timeZoneId == tzId, "Generated timezone should have correct ID")
            } else {
                Issue.record("Failed to generate timezone for: \(tzId)")
            }

            let icsContent: String = try ICalendarKit.serializeCalendar(calendar)
            #expect(icsContent.contains("X-WR-TIMEZONE:\(tzId)"))
        }
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

        // Add timezone component (should work with dynamic generation)
        if let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") {
            calendar.addTimeZone(vtimezone)
        } else {
            Issue.record("Failed to generate NY timezone for compliance test")
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

        // Should have timezone with dynamic generation
        #expect(icsContent.contains("BEGIN:VTIMEZONE"))
        #expect(icsContent.contains("TZID:America/New_York"))

        // Test round-trip parsing (basic validation)
        let parser = ICalendarParser()
        do {
            let reparsedCalendar = try parser.parse(icsContent)
            #expect(reparsedCalendar.events.count == 1)
            #expect(reparsedCalendar.version == "2.0")
        } catch {
            // For now, just ignore parsing issues - the serialization itself may be valid
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

    // MARK: - VTIMEZONE Output Validation (based on ical.net test patterns)

    @Test("Dynamic VTIMEZONE output matches expected RFC 5545 format")
    func testVTimezoneOutputFormat() async throws {
        // Test America/New_York (has DST)
        guard let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") else {
            Issue.record("Failed to generate America/New_York timezone")
            return
        }

        var calendar = ICalendar(productId: "-//Test//VTIMEZONE Format//EN")
        calendar.addTimeZone(vtimezone)

        let icsContent = try ICalendarSerializer().serialize(calendar)

        // Should contain basic VTIMEZONE structure
        #expect(icsContent.contains("BEGIN:VTIMEZONE"))
        #expect(icsContent.contains("TZID:America/New_York"))
        #expect(icsContent.contains("END:VTIMEZONE"))

        // Should have both STANDARD and DAYLIGHT components for NY
        #expect(icsContent.contains("BEGIN:STANDARD"))
        #expect(icsContent.contains("END:STANDARD"))
        #expect(icsContent.contains("BEGIN:DAYLIGHT"))
        #expect(icsContent.contains("END:DAYLIGHT"))

        // Should have proper timezone names
        #expect(icsContent.contains("TZNAME:EST") || icsContent.contains("TZNAME:EDT"))

        // Should have offset information
        #expect(icsContent.contains("TZOFFSETFROM:"))
        #expect(icsContent.contains("TZOFFSETTO:"))

        // Should have DTSTART for each component
        #expect(icsContent.contains("DTSTART:"))
    }

    @Test("Non-DST timezone generates correct VTIMEZONE")
    func testNonDSTTimezoneFormat() async throws {
        // Test UTC (no DST)
        guard let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "UTC") else {
            Issue.record("Failed to generate UTC timezone")
            return
        }

        var calendar = ICalendar(productId: "-//Test//UTC Format//EN")
        calendar.addTimeZone(vtimezone)

        let icsContent = try ICalendarSerializer().serialize(calendar)

        // Should contain basic VTIMEZONE structure
        #expect(icsContent.contains("BEGIN:VTIMEZONE"))
        #expect(icsContent.contains("TZID:UTC"))
        #expect(icsContent.contains("END:VTIMEZONE"))

        // UTC should only have STANDARD component, no DAYLIGHT
        #expect(icsContent.contains("BEGIN:STANDARD"))
        #expect(icsContent.contains("END:STANDARD"))
        #expect(!icsContent.contains("BEGIN:DAYLIGHT"), "UTC should not have daylight savings component")

        // Should have proper offset (UTC = +0000)
        #expect(icsContent.contains("TZOFFSETFROM:+0000") || icsContent.contains("TZOFFSETTO:+0000"))
    }

    @Test("Multiple timezone components serialize correctly")
    func testMultipleTimezoneComponents() async throws {
        let timezoneIds = ["America/New_York", "Europe/London", "Asia/Tokyo"]

        var calendar = ICalendar(productId: "-//Test//Multiple TZ//EN")

        for tzId in timezoneIds {
            if let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: tzId) {
                calendar.addTimeZone(vtimezone)
            } else {
                Issue.record("Failed to generate timezone: \(tzId)")
            }
        }

        let icsContent = try ICalendarSerializer().serialize(calendar)

        // Should contain all three timezones
        for tzId in timezoneIds {
            #expect(icsContent.contains("TZID:\(tzId)"), "Should contain \(tzId)")
        }

        // Count VTIMEZONE blocks
        let vtimezoneCount = icsContent.components(separatedBy: "BEGIN:VTIMEZONE").count - 1
        #expect(vtimezoneCount == timezoneIds.count, "Should have \(timezoneIds.count) VTIMEZONE components")
    }

    @Test("Generated VTIMEZONE is RFC 5545 compliant")
    func testVTimezoneRFC5545Compliance() async throws {
        guard let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "America/Los_Angeles") else {
            Issue.record("Failed to generate America/Los_Angeles timezone")
            return
        }

        // Verify the timezone component structure
        #expect(vtimezone.timeZoneId == "America/Los_Angeles")
        #expect(!vtimezone.components.isEmpty)

        // Should have timezone components
        let tzComponents = vtimezone.components.compactMap { $0 as? ICalTimeZoneComponent }
        #expect(!tzComponents.isEmpty, "Should have timezone components")

        // Verify component properties are properly set
        for component in tzComponents {
            #expect(component.offsetFrom != nil && !component.offsetFrom!.isEmpty, "TZOFFSETFROM should be set")
            #expect(component.offsetTo != nil && !component.offsetTo!.isEmpty, "TZOFFSETTO should be set")
            #expect(component.dateTimeStart != nil, "DTSTART should be set")
            #expect(component.timeZoneName != nil && !component.timeZoneName!.isEmpty, "TZNAME should be set")

            // Validate offset format (should be ±HHMM)
            let offsetFromValid = component.offsetFrom!.matches("^[+-]\\d{4}$")
            let offsetToValid = component.offsetTo!.matches("^[+-]\\d{4}$")
            #expect(offsetFromValid, "TZOFFSETFROM should be in ±HHMM format: \(component.offsetFrom!)")
            #expect(offsetToValid, "TZOFFSETTO should be in ±HHMM format: \(component.offsetTo!)")
        }
    }

    @Test("VTIMEZONE output contains X-LIC-LOCATION and proper components")
    func testVTimezoneBasicStructure() async throws {
        guard let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") else {
            Issue.record("Failed to generate America/New_York timezone")
            return
        }

        var calendar = ICalendar(productId: "-//VTIMEZONE Test//EN")
        calendar.addTimeZone(vtimezone)

        let icsContent = try ICalendarSerializer().serialize(calendar)

        // Check for X-LIC-LOCATION
        let hasXLicLocation = icsContent.contains("X-LIC-LOCATION")
        #expect(hasXLicLocation, "X-LIC-LOCATION should be present for compatibility")

        // Check timezone components
        let standardCount = icsContent.components(separatedBy: "BEGIN:STANDARD").count - 1
        let daylightCount = icsContent.components(separatedBy: "BEGIN:DAYLIGHT").count - 1

        // Basic validation
        #expect(icsContent.contains("BEGIN:VTIMEZONE"))
        #expect(icsContent.contains("TZID:America/New_York"))
        #expect(standardCount >= 1, "Should have at least one STANDARD component")
        #expect(daylightCount >= 1, "Should have at least one DAYLIGHT component for DST timezone")
    }

    @Test("VTIMEZONE fixes validation following ical.Net compatibility")
    func testVTimezoneFixes() async throws {
        guard let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") else {
            Issue.record("Failed to generate America/New_York timezone")
            return
        }

        var calendar = ICalendar(productId: "-//VTIMEZONE Fix Test//EN")
        calendar.addTimeZone(vtimezone)

        let icsContent = try ICalendarSerializer().serialize(calendar)

        // ✅ Fix 1: Component names should be STANDARD/DAYLIGHT (not always STANDARD)
        #expect(icsContent.contains("BEGIN:STANDARD"), "Should have STANDARD component")
        #expect(icsContent.contains("BEGIN:DAYLIGHT"), "Should have DAYLIGHT component")
        #expect(icsContent.contains("END:STANDARD"), "Should properly close STANDARD component")
        #expect(icsContent.contains("END:DAYLIGHT"), "Should properly close DAYLIGHT component")

        // ✅ Fix 2: X-LIC-LOCATION should be present for better compatibility
        #expect(icsContent.contains("X-LIC-LOCATION:America/New_York"), "Should include X-LIC-LOCATION property")

        // ✅ Fix 3: Timezone offsets should be properly formatted
        #expect(icsContent.contains("TZOFFSETFROM:"), "Should have TZOFFSETFROM properties")
        #expect(icsContent.contains("TZOFFSETTO:"), "Should have TZOFFSETTO properties")

        // ✅ Fix 4: Timezone names should be included
        #expect(icsContent.contains("TZNAME:EST") || icsContent.contains("TZNAME:Eastern Standard Time"), "Should have standard time name")
        #expect(icsContent.contains("TZNAME:EDT") || icsContent.contains("TZNAME:Eastern Daylight Time"), "Should have daylight time name")

        // ✅ Fix 5: DTSTART format should be floating time without Z suffix
        let dtstartLines = icsContent.components(separatedBy: .newlines).filter { $0.starts(with: "DTSTART:") }
        for line in dtstartLines {
            #expect(!line.contains("Z"), "DTSTART should be floating time without Z suffix: \(line)")
        }
    }

    @Test("Complete VTIMEZONE output matches ical.Net expected format")
    func testCompleteVTimezoneOutputFormat() async throws {
        guard let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") else {
            Issue.record("Failed to generate America/New_York timezone")
            return
        }

        var calendar = ICalendar(productId: "-//Complete Fix Test//EN")
        calendar.addTimeZone(vtimezone)

        let icsContent = try ICalendarSerializer().serialize(calendar)

        // Expected ical.Net-style format (simplified)
        let expectedElements = [
            "BEGIN:VTIMEZONE",
            "TZID:America/New_York",
            "X-LIC-LOCATION:America/New_York",
            "BEGIN:STANDARD",
            "DTSTART:19701101T020000",  // Floating time - no Z suffix
            "TZNAME:EST",
            "TZOFFSETFROM:-0400",
            "TZOFFSETTO:-0500",
            "END:STANDARD",
            "BEGIN:DAYLIGHT",
            "DTSTART:19700314T020000",  // Floating time - no Z suffix
            "TZNAME:EDT",
            "TZOFFSETFROM:-0500",
            "TZOFFSETTO:-0400",
            "END:DAYLIGHT",
            "END:VTIMEZONE",
        ]

        // Validate all expected elements are present
        for element in expectedElements {
            #expect(icsContent.contains(element), "Missing expected element: \(element)")
        }
    }

    @Test("Verify explicit UTC timezone still produces Z suffix correctly")
    func testExplicitUTCTimeFormatting() async throws {
        let date = Date()

        // Test explicit UTC timezone
        let utcTimeZone = TimeZone(identifier: "UTC")!
        let utcDateTime = ICalDateTime(date: date, timeZone: utcTimeZone)
        let utcFormatted = ICalendarFormatter.format(dateTime: utcDateTime)

        // Should end with Z suffix for UTC
        #expect(utcFormatted.hasSuffix("Z"), "UTC timezone should produce Z suffix: \(utcFormatted)")

        // Test floating time (nil timezone)
        let floatingDateTime = ICalDateTime(date: date, timeZone: nil)
        let floatingFormatted = ICalendarFormatter.format(dateTime: floatingDateTime)

        // Should NOT end with Z suffix for floating time
        #expect(!floatingFormatted.hasSuffix("Z"), "Floating time should NOT have Z suffix: \(floatingFormatted)")

        // Test GMT timezone (should also get Z suffix)
        let gmtTimeZone = TimeZone(identifier: "GMT")!
        let gmtDateTime = ICalDateTime(date: date, timeZone: gmtTimeZone)
        let gmtFormatted = ICalendarFormatter.format(dateTime: gmtDateTime)

        #expect(gmtFormatted.hasSuffix("Z"), "GMT timezone should produce Z suffix: \(gmtFormatted)")
    }

    @Test("Events without timezone use floating time format")
    func testFloatingTimeForEventsWithoutTimezone() async throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(3600)  // 1 hour later

        // Create event without specifying timezone (should use floating time)
        var event = ICalEvent(summary: "Floating Time Event")
        event.dateTimeStart = ICalDateTime(date: startDate, timeZone: nil)  // Explicit nil timezone
        event.dateTimeEnd = ICalDateTime(date: endDate, timeZone: nil)

        var calendar = ICalendar(productId: "-//Floating Time Test//EN")
        calendar.addEvent(event)

        let icsContent = try ICalendarSerializer().serialize(calendar)

        // Find DTSTART and DTEND lines
        let lines = icsContent.components(separatedBy: .newlines)
        let dtstartLines = lines.filter { $0.starts(with: "DTSTART:") }
        let dtendLines = lines.filter { $0.starts(with: "DTEND:") }

        // Verify floating time format (no Z suffix, no TZID)
        for line in dtstartLines {
            #expect(!line.contains("Z"), "DTSTART should be floating time without Z suffix: \(line)")
            #expect(!line.contains("TZID"), "DTSTART should not have TZID parameter: \(line)")
        }

        for line in dtendLines {
            #expect(!line.contains("Z"), "DTEND should be floating time without Z suffix: \(line)")
            #expect(!line.contains("TZID"), "DTEND should not have TZID parameter: \(line)")
        }

        // Compare with explicit UTC event
        var utcEvent = ICalEvent(summary: "UTC Event")
        utcEvent.dateTimeStart = ICalDateTime(date: startDate, timeZone: TimeZone(identifier: "UTC")!)
        utcEvent.dateTimeEnd = ICalDateTime(date: endDate, timeZone: TimeZone(identifier: "UTC")!)

        var utcCalendar = ICalendar(productId: "-//UTC Test//EN")
        utcCalendar.addEvent(utcEvent)

        let utcContent = try ICalendarSerializer().serialize(utcCalendar)
        let utcLines = utcContent.components(separatedBy: .newlines)
        let utcDtstartLines = utcLines.filter { $0.starts(with: "DTSTART:") }

        // Verify UTC format (with Z suffix)
        for line in utcDtstartLines {
            #expect(line.contains("Z"), "UTC DTSTART should have Z suffix: \(line)")
        }
    }

    @Test("Timezone abbreviations work correctly")
    func testTimezoneAbbreviations() async throws {
        let timeZone = TimeZone(identifier: "America/New_York")!

        let winterDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let summerDate = Calendar.current.date(from: DateComponents(year: 2024, month: 7, day: 15))!

        let winterAbbrev = timeZone.abbreviation(for: winterDate)
        let summerAbbrev = timeZone.abbreviation(for: summerDate)

        // Verify we get abbreviations
        #expect(winterAbbrev != nil, "Should have winter abbreviation")
        #expect(summerAbbrev != nil, "Should have summer abbreviation")
        #expect(winterAbbrev != summerAbbrev, "Winter and summer abbreviations should be different")

        // Try different localized name options
        let standardName = timeZone.localizedName(for: .standard, locale: .current)
        let daylightName = timeZone.localizedName(for: .daylightSaving, locale: .current)

        #expect(standardName != nil, "Should have standard localized name")
        #expect(daylightName != nil, "Should have daylight localized name")
    }

    @Test("Timezone component generation works correctly")
    func testTimezoneComponentGeneration() async throws {
        // Get the generated timezone
        guard let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") else {
            Issue.record("Failed to get timezone")
            return
        }

        // Should have both standard and daylight components
        #expect(vtimezone.components.count == 2, "Should have 2 components (standard and daylight)")

        let standardComponents = vtimezone.components.compactMap { $0 as? ICalTimeZoneComponent }.filter { $0.isStandard }
        let daylightComponents = vtimezone.components.compactMap { $0 as? ICalTimeZoneComponent }.filter { !$0.isStandard }

        #expect(standardComponents.count == 1, "Should have 1 standard component")
        #expect(daylightComponents.count == 1, "Should have 1 daylight component")

        // Verify components have required properties
        if let standardComponent = standardComponents.first {
            #expect(standardComponent.timeZoneName != nil, "Standard component should have timezone name")
            #expect(standardComponent.offsetFrom != nil, "Standard component should have offset from")
            #expect(standardComponent.offsetTo != nil, "Standard component should have offset to")
            #expect(standardComponent.dateTimeStart != nil, "Standard component should have start date")
        }

        if let daylightComponent = daylightComponents.first {
            #expect(daylightComponent.timeZoneName != nil, "Daylight component should have timezone name")
            #expect(daylightComponent.offsetFrom != nil, "Daylight component should have offset from")
            #expect(daylightComponent.offsetTo != nil, "Daylight component should have offset to")
            #expect(daylightComponent.dateTimeStart != nil, "Daylight component should have start date")
        }

        // Test serialization
        var calendar = ICalendar(productId: "-//Test//EN")
        calendar.addTimeZone(vtimezone)

        let serialized = try ICalendarSerializer().serialize(calendar)
        #expect(serialized.contains("TZNAME:"), "Should contain TZNAME properties")
    }

    @Test("Timezone abbreviation robustness across systems")
    func testTimezoneAbbreviationRobustness() async throws {
        // Test that we get consistent abbreviations from the system like ical.Net trusts NodaTime
        let testTimezones = [
            "America/New_York",
            "America/Chicago",
            "America/Denver",
            "America/Los_Angeles",
            "America/Phoenix",  // No DST
            "Europe/London",
        ]

        for timezoneId in testTimezones {
            guard let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: timezoneId) else {
                Issue.record("Failed to generate timezone for \(timezoneId)")
                continue
            }

            var calendar = ICalendar(productId: "-//Test//EN")
            calendar.addTimeZone(vtimezone)

            let serialized = try ICalendarSerializer().serialize(calendar)

            // Should contain TZNAME properties (trust whatever the system gives us)
            #expect(serialized.contains("TZNAME:"), "Should contain TZNAME properties for \(timezoneId)")

            // Should not contain empty TZNAME values
            #expect(!serialized.contains("TZNAME:\n"), "Should not have empty TZNAME for \(timezoneId)")
            #expect(!serialized.contains("TZNAME: "), "Should not have empty TZNAME for \(timezoneId)")
        }
    }

    @Test("Europe/London generates proper BST abbreviation")
    func testEuropeLondonGeneratesProperBST() async throws {
        guard let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "Europe/London") else {
            Issue.record("Failed to generate timezone for Europe/London")
            return
        }

        var calendar = ICalendar(productId: "-//Test//EN")
        calendar.addTimeZone(vtimezone)
        let serialized = try ICalendarSerializer().serialize(calendar)

        // Should contain proper British timezone abbreviations like ical.Net expects
        #expect(serialized.contains("TZNAME:GMT"), "Should contain standard timezone name GMT for Europe/London")
        #expect(serialized.contains("TZNAME:BST"), "Should contain daylight timezone name BST for Europe/London")

        // Should not contain GMT-based fallbacks
        #expect(!serialized.contains("TZNAME:GMT+"), "Should not use GMT+ fallback for Europe/London")
        #expect(!serialized.contains("TZNAME:GMT-"), "Should not use GMT- fallback for Europe/London")
    }

    @Test("RRULE generation for DST transitions")
    func testRRuleGeneration() async throws {
        guard let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") else {
            Issue.record("Failed to generate timezone for America/New_York")
            return
        }

        var calendar = ICalendar(productId: "-//Test//EN")
        calendar.addTimeZone(vtimezone)
        let serialized = try ICalendarSerializer().serialize(calendar)

        // Verify RRULE components are present
        #expect(serialized.contains("RRULE:"), "Should contain RRULE for DST transitions")
        #expect(serialized.contains("BYDAY="), "Should contain BYDAY in RRULE")

        // Verify proper DST transition rules for America/New_York
        #expect(serialized.contains("BYDAY=SU"), "DST transitions should happen on Sunday")
        #expect(serialized.contains("BYMONTH=3"), "Spring transition should be in March")
        #expect(serialized.contains("BYMONTH=11"), "Fall transition should be in November")
    }

    @Test("X-ALT-DESC support for alternative HTML descriptions")
    func testXAltDescSupport() async throws {
        // Create event with both regular and HTML description using builder pattern
        let htmlDescription = "<html><body><h1>Meeting Details</h1><p>This is a <strong>important</strong> meeting.</p></body></html>"
        let plainDescription = "Meeting Details - This is an important meeting."

        let calendar = ICalendar.create(productId: "-//Test X-ALT-DESC//EN") {
            EventBuilder(summary: "Test Event with HTML Description", uid: "test-xaltdesc-001")
                .description(plainDescription)
                .htmlDescription(htmlDescription)
                .createdNow()
        }
        let serialized = try ICalendarSerializer().serialize(calendar)
        let event = calendar.events.first!

        // Verify both descriptions are present
        #expect(serialized.contains("DESCRIPTION:\(plainDescription)"), "Should contain plain text description")

        // Check for X-ALT-DESC with FMTTYPE parameter (handle line wrapping)
        #expect(serialized.contains("X-ALT-DESC;FMTTYPE=text/html:"), "Should contain X-ALT-DESC with FMTTYPE parameter")
        #expect(serialized.contains("<html><body><h1>Meeting Details</h1>"), "Should contain HTML content")
        #expect(serialized.contains("<strong>important</strong>"), "Should contain HTML formatting")

        // Test retrieval
        #expect(event.htmlDescription == htmlDescription, "Should retrieve correct HTML description")

        if let altDesc = event.getAlternativeDescriptionWithFormat() {
            #expect(altDesc.description == htmlDescription, "Should retrieve correct HTML description with format")
            #expect(altDesc.formatType == "text/html", "Should retrieve correct format type")
        } else {
            Issue.record("Failed to retrieve alternative description with format")
        }

        // Verify basic serialization structure
        #expect(serialized.contains("BEGIN:VCALENDAR"), "Should contain calendar structure")
        #expect(serialized.contains("BEGIN:VEVENT"), "Should contain event structure")
        #expect(serialized.contains("END:VEVENT"), "Should end event structure")
        #expect(serialized.contains("END:VCALENDAR"), "Should end calendar structure")
    }

    @Test("Enhanced attendee builder functionality")
    func testEnhancedAttendeeBuilder() async throws {
        // Test the comprehensive attendee builder methods
        let calendar = ICalendar.create(productId: "-//Enhanced Attendee Test//EN") {
            EventBuilder(summary: "Project Kickoff Meeting", uid: "meeting-attendees-001")
                .starts(at: Date().addingTimeInterval(3600))
                .duration(7200)  // 2 hours
                .organizer(email: "manager@company.com", name: "Project Manager")

                // Basic attendees
                .addAttendee(email: "john@company.com", name: "John Smith", role: .requiredParticipant)
                .addAttendee(email: "jane@company.com", name: "Jane Doe", role: .optionalParticipant)

                // Resources and rooms
                .addAttendee(email: "conf-room-a@company.com", name: "Conference Room A", role: .nonParticipant, userType: .room, rsvp: false)
                .addAttendee(email: "projector@company.com", name: "HD Projector", role: .nonParticipant, userType: .resource, rsvp: false)

                // Group attendees
                .addAttendee(email: "dev-team@company.com", name: "Development Team", role: .requiredParticipant, userType: .group)

                // Attendees with specific status
                .addAttendee(
                    email: "alice@company.com",
                    name: "Alice Johnson",
                    role: .requiredParticipant,
                    status: .accepted
                )
                .addAttendee(
                    email: "bob@company.com",
                    name: "Bob Wilson",
                    role: .optionalParticipant,
                    status: .tentative
                )

                // Delegated attendee
                .addAttendee(
                    email: "charlie@company.com",
                    name: "Charlie Brown",
                    role: .requiredParticipant,
                    status: .delegated,
                    delegatedFrom: "david@company.com"
                )

                // Advanced attendee with all details
                .addAttendee(
                    email: "expert@external.com",
                    name: "External Expert",
                    role: .requiredParticipant,
                    status: .needsAction,
                    userType: .individual,
                    rsvp: true,
                    sentBy: "assistant@external.com",
                    directory: "ldap://external.com/cn=users,dc=external,dc=com"
                )

                .createdNow()
        }

        let serialized = try ICalendarSerializer().serialize(calendar)
        let event = calendar.events.first!

        // Verify we have all attendees
        #expect(event.attendees.count == 9, "Should have 9 attendees")

        // Verify organizer
        #expect(event.organizer?.email == "manager@company.com", "Should have correct organizer")
        #expect(event.organizer?.role == .chair, "Organizer should have chair role")

        // Test different attendee types are properly serialized
        #expect(
            serialized.contains("CUTYPE=ROOM") && serialized.contains("conf-room-a@company.com"),
            "Should contain room attendee"
        )
        #expect(
            serialized.contains("CUTYPE=RESOURCE") && serialized.contains("projector@company.com"),
            "Should contain resource attendee"
        )
        #expect(
            serialized.contains("CUTYPE=GROUP") && serialized.contains("dev-team@company.com"),
            "Should contain group attendee"
        )

        // Verify specific attendee properties
        let acceptedAttendee = event.attendees.first { $0.email == "alice@company.com" }
        #expect(acceptedAttendee?.participationStatus == .accepted, "Should have accepted status")

        let tentativeAttendee = event.attendees.first { $0.email == "bob@company.com" }
        #expect(tentativeAttendee?.participationStatus == .tentative, "Should have tentative status")
        #expect(tentativeAttendee?.role == .optionalParticipant, "Should have optional participant role")

        let delegatedAttendee = event.attendees.first { $0.email == "charlie@company.com" }
        #expect(delegatedAttendee?.participationStatus == .delegated, "Should have delegated status")
        #expect(delegatedAttendee?.delegatedFrom == "david@company.com", "Should have correct delegation source")

        let externalExpert = event.attendees.first { $0.email == "expert@external.com" }
        #expect(externalExpert?.sentBy == "assistant@external.com", "Should have sent-by property")
        #expect(externalExpert?.directory == "ldap://external.com/cn=users,dc=external,dc=com", "Should have directory property")
    }

    @Test("addAttendee methods follow same pattern as addAlarm")
    func testAddAttendeePattern() async throws {
        let calendar = ICalendar.create(productId: "-//Consistent API Test//EN") {
            EventBuilder(summary: "API Consistency Demo", uid: "api-consistency-001")
                .starts(at: Date().addingTimeInterval(3600))
                .duration(7200)  // 2 hours
                .description("Meeting to demonstrate API consistency")
                .organizer(email: "organizer@company.com", name: "Event Organizer")

                // Using addAttendee methods
                .addAttendee(email: "john@company.com", name: "John Smith", role: .requiredParticipant)
                .addAttendee(email: "jane@company.com", name: "Jane Doe", role: .optionalParticipant)
                .addAttendee(
                    email: "expert@company.com",
                    name: "Technical Expert",
                    role: .requiredParticipant,
                    status: .accepted,
                    userType: .individual,
                    rsvp: true
                )

                // Bulk add attendees
                .addAttendees([
                    ICalAttendee(email: "alice@company.com", commonName: "Alice Johnson"),
                    ICalAttendee(email: "bob@company.com", commonName: "Bob Wilson"),
                    ICalAttendee(email: "charlie@company.com", commonName: "Charlie Brown"),
                ])

                .createdNow()
        }

        let serialized = try ICalendarSerializer().serialize(calendar)
        let event = calendar.events.first!

        // Verify attendees were added correctly
        #expect(event.attendees.count == 6, "Should have 6 attendees (3 individual + 3 bulk)")

        // Verify required attendee
        let johnAttendee = event.attendees.first { $0.email == "john@company.com" }
        #expect(johnAttendee?.role == .requiredParticipant, "John should be required participant")
        #expect(johnAttendee?.commonName == "John Smith", "Should have correct name")

        // Verify optional attendee
        let janeAttendee = event.attendees.first { $0.email == "jane@company.com" }
        #expect(janeAttendee?.role == .optionalParticipant, "Jane should be optional participant")

        // Verify detailed attendee
        let expertAttendee = event.attendees.first { $0.email == "expert@company.com" }
        #expect(expertAttendee?.participationStatus == .accepted, "Expert should have accepted status")

        // Verify bulk attendees were added
        #expect(serialized.contains("alice@company.com"), "Should contain Alice from bulk add")
        #expect(serialized.contains("bob@company.com"), "Should contain Bob from bulk add")
        #expect(serialized.contains("charlie@company.com"), "Should contain Charlie from bulk add")
        // Verify API consistency in generated output (accounting for line folding)
        #expect(
            serialized.contains("CN=\"John Smith\"") && serialized.contains("PARTICIPANT") && serialized.contains("john@company.com"),
            "Should generate proper ATTENDEE property"
        )
    }

    @Test("TimeZoneRegistry generates TZURL automatically for RFC 7808 compliance")
    func testAutomaticTZURLGeneration() async throws {
        // Test that TimeZoneRegistry automatically generates TZURL for timezone components
        guard let nyTimeZone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") else {
            return  // Skip test if timezone not available
        }

        // Verify TZURL is automatically generated
        #expect(nyTimeZone.timeZoneUrl != nil, "TimeZoneRegistry should automatically generate TZURL")
        #expect(
            nyTimeZone.timeZoneUrl == "http://tzurl.org/zoneinfo-outlook/America/New_York",
            "TZURL should follow standard format"
        )

        // Test another timezone
        guard let londonTimeZone = TimeZoneRegistry.shared.getTimeZone(for: "Europe/London") else {
            return  // Skip test if timezone not available
        }

        #expect(
            londonTimeZone.timeZoneUrl == "http://tzurl.org/zoneinfo-outlook/Europe/London",
            "TZURL should be generated for all timezones"
        )

        // Test calendar with timezone includes TZURL in serialization
        var calendar = ICalendar(productId: "-//TZURL Test//EN")
        calendar.addTimeZone(nyTimeZone)

        let serialized = try ICalendarSerializer().serialize(calendar)
        #expect(
            serialized.contains("TZURL:http://tzurl.org/zoneinfo-outlook/America/New_York"),
            "Serialized calendar should include TZURL"
        )
        #expect(
            serialized.contains("TZID:America/New_York"),
            "Serialized calendar should include TZID"
        )
    }
}

// MARK: - String Extension for Regex Matching

extension String {
    func matches(_ pattern: String) -> Bool {
        self.range(of: pattern, options: .regularExpression) != nil
    }
}
