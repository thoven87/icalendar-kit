import Foundation
import Testing

@testable import ICalendar

@Suite("All-Day Event Tests")
struct AllDayEventTests {

    @Test("All-day event serialization uses correct VALUE=DATE format")
    func testAllDayEventSerializationIssue() throws {
        // Create a date for July 15, 2025 in UTC
        let timeZone = TimeZone(identifier: "UTC")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 7
        dateComponents.day = 15
        guard let testDate = calendar.date(from: dateComponents) else {
            Issue.record("Failed to create test date")
            return
        }

        // Test 1: Current EventBuilder.allDay()
        let allDayCalendar = ICalendar.withEvent(
            productId: "TEST//EN",
            event: EventBuilder(summary: "Test All-Day Event").allDay(on: testDate, timeZone: timeZone)
        )

        let serialized = try ICalendarSerializer().serialize(allDayCalendar)

        // Handle both Unix (\n) and Windows (\r\n) line endings for cross-platform compatibility
        let lines = serialized.components(separatedBy: CharacterSet.newlines)
            .filter { !$0.isEmpty }
        guard let dtstartLine = lines.first(where: { $0.hasPrefix("DTSTART") }) else {
            Issue.record("No DTSTART line found in serialized output. Available lines: \(lines)")
            return
        }

        // Test 1: Should use VALUE=DATE format (date should be same regardless of timezone for all-day events)
        #expect(
            dtstartLine.contains("VALUE=DATE:") && dtstartLine.contains("20250715"),
            "All-day events should use VALUE=DATE format with correct date. Found: \(dtstartLine)"
        )

        // Test 2: Should NOT contain TZID
        #expect(
            !dtstartLine.contains("TZID="),
            "All-day events should not contain TZID parameter. Found: \(dtstartLine)"
        )

        // Test 3: Check for proper date format
        #expect(
            dtstartLine.contains("20250715"),
            "Date format should be YYYYMMDD (20250715). Found: \(dtstartLine)"
        )
    }

    @Test("ICalDateTime properties for date-only events")
    func testICalDateTimeProperties() {
        let testDate = Date()
        let timeZone = TimeZone(identifier: "America/New_York")!

        // Test date-only ICalDateTime properties
        let allDayDateTime = ICalDateTime(date: testDate, timeZone: timeZone, isDateOnly: true)

        #expect(allDayDateTime.isDateOnly, "Date-only ICalDateTime should have isDateOnly=true")
        #expect(allDayDateTime.precision == .date, "Date-only ICalDateTime should have .date precision")
        #expect(allDayDateTime.timeZone?.identifier == timeZone.identifier, "TimeZone should be preserved")

        // Test the formatted output
        let formatted = ICalendarFormatter.format(dateTime: allDayDateTime)

        // The formatter correctly outputs date-only format (YYYYMMDD)
        #expect(formatted.count == 8, "Date-only format should be 8 characters (YYYYMMDD)")
        #expect(!formatted.contains("T"), "Date-only format should not contain time separator")
        #expect(!formatted.contains("Z"), "Date-only format should not contain UTC marker")
    }

    @Test("Timed event regression test - ensure timed events still work")
    func testTimedEventComparison() throws {
        let calendar = Calendar(identifier: .gregorian)
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 7
        dateComponents.day = 15
        dateComponents.hour = 10
        dateComponents.minute = 0
        guard let testDate = calendar.date(from: dateComponents) else {
            Issue.record("Failed to create test date")
            return
        }

        let timeZone = TimeZone(identifier: "UTC")!

        // Create a timed event for comparison
        let timedCalendar = ICalendar.withEvent(
            productId: "TEST//EN",
            event: EventBuilder(summary: "Test Timed Event")
                .starts(at: testDate, timeZone: timeZone)
                .ends(at: calendar.date(byAdding: .hour, value: 1, to: testDate)!, timeZone: timeZone)
        )

        let serialized = try ICalendarSerializer().serialize(timedCalendar)

        // Handle both Unix (\n) and Windows (\r\n) line endings for cross-platform compatibility
        let lines = serialized.components(separatedBy: CharacterSet.newlines)
            .filter { !$0.isEmpty }
        guard let dtstartLine = lines.first(where: { $0.hasPrefix("DTSTART") }) else {
            Issue.record("No DTSTART line found in timed event. Available lines: \(lines)")
            return
        }

        // Timed events SHOULD have TZID parameter (or Z suffix for UTC)
        #expect(dtstartLine.contains("TZID=") || dtstartLine.contains("Z"), "Timed events should contain TZID parameter or Z suffix for UTC")
        #expect(!dtstartLine.contains("VALUE=DATE"), "Timed events should not contain VALUE=DATE")
    }

    @Test("Manual date-time property setting behavior")
    func testManualDateTimePropertySetting() {
        // Test the core issue: setDateTimeProperty method behavior
        let testDate = Date()
        let timeZone = TimeZone(identifier: "UTC")!

        // Create a date-only ICalDateTime
        let dateOnlyDateTime = ICalDateTime(date: testDate, timeZone: timeZone, isDateOnly: true)

        // Create an event and set the dateTimeStart property
        var event = ICalEvent(summary: "Manual Test")
        event.dateTimeStart = dateOnlyDateTime

        // Find the DTSTART property that was created
        guard let dtstartProperty = event.properties.first(where: { $0.name == "DTSTART" }) else {
            Issue.record("No DTSTART property found")
            return
        }

        #expect(
            !dtstartProperty.parameters.keys.contains("TZID"),
            "Date-only events should not have TZID parameter. Parameters: \(dtstartProperty.parameters)"
        )

        #expect(
            dtstartProperty.parameters.keys.contains("VALUE") && dtstartProperty.parameters["VALUE"] == "DATE",
            "Date-only events should have VALUE=DATE parameter. Parameters: \(dtstartProperty.parameters)"
        )
    }
}
