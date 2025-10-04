import Foundation
import ICalendar
import Testing

// MARK: - Escaping Validation Test Suite
// Tests that TEXT properties are properly escaped while structured properties are not

@Suite("Text Property Escaping Validation")
struct EscapingValidationTest {

    // MARK: - Test TEXT Property Escaping

    /// Test that TEXT properties properly escape special characters
    @Test("TEXT Properties Should Be Escaped")
    func testTextPropertyEscaping() throws {
        // Create event with special characters in TEXT properties
        let event = EventBuilder(summary: "Test Event; With Semicolon, And Comma")
            .description("This has a newline\nand semicolon; and comma, in text")
            .location("Conference Room; Building A, Floor 2")
            .categories("Meeting", "Important; Urgent")
            .buildEvent()

        var calendar = ICalendar(productId: "-//Test//Escaping Test//EN")
        calendar.addEvent(event)

        let ics = try ICalendarSerializer().serialize(calendar)

        // Verify TEXT properties are properly escaped
        #expect(
            ics.contains("SUMMARY:Test Event\\; With Semicolon\\, And Comma"),
            "SUMMARY should escape semicolon and comma"
        )

        #expect(
            ics.contains("DESCRIPTION:This has a newline\\nand semicolon\\; and comma\\, in text"),
            "DESCRIPTION should escape newline, semicolon, and comma"
        )

        #expect(
            ics.contains("LOCATION:Conference Room\\; Building A\\, Floor 2"),
            "LOCATION should escape semicolon and comma"
        )

        #expect(
            ics.contains("CATEGORIES:Meeting\\,Important\\; Urgent"),
            "CATEGORIES should escape comma and semicolon"
        )
    }

    /// Test that structured properties (like RRULE) are NOT escaped
    @Test("Structured Properties Should Not Be Escaped")
    func testStructuredPropertyNoEscaping() throws {
        let event = EventBuilder(summary: "Weekly Test")
            .starts(at: Date(), timeZone: .current)
            .duration(3600)
            .repeatsWeekly(every: 1, on: [.monday, .tuesday, .wednesday, .thursday, .friday])
            .buildEvent()

        var calendar = ICalendar(productId: "-//Test//Structured//EN")
        calendar.addEvent(event)

        let ics = try ICalendarSerializer().serialize(calendar)

        // Verify RRULE is NOT escaped (should have unescaped semicolons and commas)
        #expect(
            ics.contains("RRULE:FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR;WKST=MO"),
            "RRULE should have unescaped semicolons and commas"
        )

        // Make sure it's not escaped
        #expect(
            !ics.contains("RRULE:FREQ=WEEKLY\\;"),
            "RRULE should not have escaped semicolons"
        )
        #expect(
            !ics.contains("BYDAY=MO\\,TU\\,"),
            "RRULE should not have escaped commas"
        )
    }

    /// Test various TEXT escaping scenarios
    @Test("Comprehensive TEXT Escaping")
    func testComprehensiveTextEscaping() throws {
        let testCases: [(input: String, expected: String, description: String)] = [
            // Backslash escaping
            ("Text with \\ backslash", "Text with \\\\ backslash", "backslash"),

            // Semicolon escaping
            ("Text; with semicolon", "Text\\; with semicolon", "semicolon"),

            // Comma escaping
            ("Text, with comma", "Text\\, with comma", "comma"),

            // Newline escaping
            ("Text\nwith newline", "Text\\nwith newline", "newline (lowercase n)"),
            ("Text\nwith newline", "Text\\nwith newline", "newline (uppercase N)"),

            // Colon should NOT be escaped (per RFC 5545)
            ("Text: with colon", "Text: with colon", "colon (should not be escaped)"),

            // Multiple special characters
            ("Complex; text, with\nmultiple \\ chars", "Complex\\; text\\, with\\nmultiple \\\\ chars", "multiple special characters"),

            // No escaping needed
            ("Normal text without special chars", "Normal text without special chars", "normal text"),
        ]

        for (index, testCase) in testCases.enumerated() {
            let event = EventBuilder(summary: testCase.input)
                .buildEvent()

            var calendar = ICalendar(productId: "-//Test//Escaping\(index)//EN")
            calendar.addEvent(event)

            let ics = try ICalendarSerializer().serialize(calendar)

            #expect(
                ics.contains("SUMMARY:\(testCase.expected)"),
                "Failed escaping test for \(testCase.description): '\(testCase.input)' should become '\(testCase.expected)'"
            )
        }
    }

    /// Test that parameter values are properly escaped
    @Test("Parameter Value Escaping")
    func testParameterValueEscaping() throws {
        // Create event with special characters in parameters
        var event = ICalEvent()
        event.summary = "Test Event"
        event.uid = UUID().uuidString
        event.dateTimeStamp = ICalDateTime(date: Date())

        // Add organizer with special characters in CN parameter
        let organizer = ICalAttendee(
            email: "test@example.com",
            commonName: "John; Doe, Jr.",
            role: .chair
        )
        event.organizer = organizer

        var calendar = ICalendar(productId: "-//Test//Parameters//EN")
        calendar.addEvent(event)

        let ics = try ICalendarSerializer().serialize(calendar)

        // Parameter values should be escaped or quoted
        #expect(
            ics.contains("CN=\"\"John; Doe, Jr.\"\"") || ics.contains("CN=\"John; Doe, Jr.\"") || ics.contains("CN=John\\; Doe\\, Jr."),
            "Parameter values with special characters should be escaped or quoted"
        )
    }

    /// Test mixed content with both TEXT and structured properties
    @Test("Mixed Content Escaping")
    func testMixedContentEscaping() throws {
        let event = EventBuilder(summary: "Meeting; Important, Urgent")
            .description("Weekly sync\nwith team; covers projects, deadlines")
            .location("Room 101; Building A, 2nd Floor")
            .categories("Work", "Meeting; Important")
            .starts(at: Date(), timeZone: .current)
            .duration(3600)
            .repeatsWeekly(every: 1, on: [.monday, .wednesday, .friday])
            .buildEvent()

        var calendar = ICalendar(productId: "-//Test//Mixed//EN")
        calendar.addEvent(event)

        let ics = try ICalendarSerializer().serialize(calendar)

        // TEXT properties should be escaped
        #expect(
            ics.contains("SUMMARY:Meeting\\; Important\\, Urgent"),
            "SUMMARY should be escaped"
        )
        #expect(
            ics.contains("Weekly sync\\nwith team\\; covers projects\\, deadlines"),
            "DESCRIPTION should be escaped"
        )
        #expect(
            ics.contains("LOCATION:Room 101\\; Building A\\, 2nd Floor"),
            "LOCATION should be escaped"
        )

        // RRULE should NOT be escaped
        #expect(
            ics.contains("RRULE:FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR;WKST=MO"),
            "RRULE should not be escaped"
        )

        // Verify no double escaping in RRULE
        #expect(
            !ics.contains("RRULE:FREQ=WEEKLY\\;"),
            "RRULE should not have escaped semicolons"
        )
        #expect(
            !ics.contains("BYDAY=MO\\,WE\\,"),
            "RRULE should not have escaped commas"
        )
    }

    /// Test edge cases for escaping
    @Test("Escaping Edge Cases")
    func testEscapingEdgeCases() throws {
        let edgeCases: [(input: String, description: String)] = [
            ("", "empty string"),
            (";", "single semicolon"),
            (",", "single comma"),
            ("\\", "single backslash"),
            ("\n", "single newline"),
            (";;;", "multiple semicolons"),
            (",,,", "multiple commas"),
            ("\\\\\\", "multiple backslashes"),
            ("\n\n\n", "multiple newlines"),
            (";,\n\\", "all special characters"),
            ("Normal text", "normal text without special characters"),
            ("Text with spaces", "text with spaces (should not be escaped)"),
        ]

        for (index, testCase) in edgeCases.enumerated() {
            let event = EventBuilder(summary: testCase.input)
                .buildEvent()

            var calendar = ICalendar(productId: "-//Test//Edge\(index)//EN")
            calendar.addEvent(event)

            let ics = try ICalendarSerializer().serialize(calendar)

            // Should not crash and should produce valid output
            #expect(
                ics.contains("BEGIN:VCALENDAR"),
                "Should produce valid calendar for \(testCase.description)"
            )
            #expect(
                ics.contains("SUMMARY:"),
                "Should contain SUMMARY line for \(testCase.description)"
            )
        }
    }

    /// Test that our structured property list is comprehensive
    @Test("Structured Property Coverage")
    func testStructuredPropertyCoverage() throws {
        // Test various structured properties to ensure they're not escaped
        var event = ICalEvent()
        event.summary = "Test Event"
        event.uid = UUID().uuidString
        event.dateTimeStamp = ICalDateTime(date: Date())
        event.dateTimeStart = ICalDateTime(date: Date())

        // Add RRULE (recurrence rule)
        event.recurrenceRule = ICalRecurrenceRule(
            frequency: .daily,
            interval: 1,
            byWeekday: [.monday, .tuesday]
        )

        // Add RDATE (recurrence dates) - if supported
        // Add EXDATE (exception dates) - if supported

        var calendar = ICalendar(productId: "-//Test//Structured Coverage//EN")
        calendar.addEvent(event)

        let ics = try ICalendarSerializer().serialize(calendar)

        // RRULE should not be escaped
        #expect(
            ics.contains("RRULE:FREQ=DAILY;INTERVAL=1;BYDAY=MO,TU;WKST=MO"),
            "RRULE should not be escaped"
        )

        // Verify we have unescaped structural characters
        #expect(
            ics.contains("FREQ=DAILY;"),
            "RRULE should contain unescaped semicolon"
        )
        #expect(
            ics.contains("BYDAY=MO,TU"),
            "RRULE should contain unescaped comma"
        )
    }

    /// Performance test for escaping with large content
    @Test("Escaping Performance")
    func testEscapingPerformance() throws {
        // Create large text content with many special characters
        let largeText = String(repeating: "This is a long text; with commas, and newlines\n", count: 1000)

        let event = EventBuilder(summary: "Performance Test")
            .description(largeText)
            .buildEvent()

        var calendar = ICalendar(productId: "-//Test//Performance//EN")
        calendar.addEvent(event)

        // Should complete without timeout
        let startTime = Date()
        let ics = try ICalendarSerializer().serialize(calendar)
        let endTime = Date()

        let duration = endTime.timeIntervalSince(startTime)

        // Should complete in reasonable time (less than 1 second for this size)
        #expect(duration < 1.0, "Escaping should complete in reasonable time")

        // Should still produce valid output
        #expect(ics.contains("BEGIN:VCALENDAR"), "Should produce valid calendar")
        #expect(ics.contains("DESCRIPTION:"), "Should contain escaped description")
    }
}
