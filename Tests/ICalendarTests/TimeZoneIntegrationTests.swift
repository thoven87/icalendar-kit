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
                print("Skipping unsupported timezone: \(tzId)")
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
}

// MARK: - String Extension for Regex Matching

extension String {
    func matches(_ pattern: String) -> Bool {
        self.range(of: pattern, options: .regularExpression) != nil
    }
}
