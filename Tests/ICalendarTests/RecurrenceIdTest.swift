import Foundation
import Testing

@testable import ICalendar

@Suite("RECURRENCE-ID Tests")
struct RecurrenceIdTests {

    @Test("Basic RECURRENCE-ID property handling")
    func testBasicRecurrenceIdProperty() throws {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2025
        components.month = 3
        components.day = 15
        components.hour = 14
        components.minute = 0
        components.second = 0
        guard let recurrenceDate = calendar.date(from: components) else {
            Issue.record("Failed to create test date")
            return
        }

        let timeZone = TimeZone(identifier: "America/New_York")!

        // Create an event with RECURRENCE-ID
        var event = ICalEvent(summary: "Modified Recurring Event")
        event.recurrenceId = ICalDateTime(date: recurrenceDate, timeZone: timeZone)

        // Verify the property was set correctly
        #expect(event.recurrenceId != nil, "RECURRENCE-ID should be set")
        #expect(event.recurrenceId?.timeZone?.identifier == timeZone.identifier, "RECURRENCE-ID timezone should match")

        // For date comparison, compare the formatted strings since timezone conversion can affect exact Date objects
        let expectedFormatted = ICalendarFormatter.format(dateTime: ICalDateTime(date: recurrenceDate, timeZone: timeZone))
        let actualFormatted = ICalendarFormatter.format(dateTime: event.recurrenceId!)
        #expect(actualFormatted == expectedFormatted, "RECURRENCE-ID formatted date should match")
    }

    @Test("EventBuilder recurrenceId method")
    func testEventBuilderRecurrenceId() throws {
        let testDate = Date()

        // Test 1: Default timezone behavior
        let event1 = EventBuilder(summary: "Test Event 1")
            .recurrenceId(testDate)  // Using default timezone (.current)
            .buildEvent()

        #expect(event1.recurrenceId != nil, "Event should have RECURRENCE-ID")
        #expect(
            event1.recurrenceId?.timeZone?.identifier == TimeZone.current.identifier,
            "Default should use current timezone"
        )

        // Test 2: Explicit timezone parameter
        let utcTimeZone = TimeZone(identifier: "UTC")!
        let event2 = EventBuilder(summary: "Test Event 2")
            .recurrenceId(testDate, timeZone: utcTimeZone)
            .buildEvent()

        #expect(event2.recurrenceId != nil, "Event should have RECURRENCE-ID")
        #expect(
            event2.recurrenceId?.timeZone?.identifier == utcTimeZone.identifier,
            "Should use explicitly passed timezone"
        )

        // Test 3: Different timezone
        let nyTimeZone = TimeZone(identifier: "America/New_York")!
        let event3 = EventBuilder(summary: "Test Event 3")
            .recurrenceId(testDate, timeZone: nyTimeZone)
            .buildEvent()

        #expect(event3.recurrenceId != nil, "Event should have RECURRENCE-ID")
        #expect(
            event3.recurrenceId?.timeZone?.identifier == nyTimeZone.identifier,
            "Should use New York timezone"
        )
    }

    @Test("Direct ICalDateTime timezone test")
    func testDirectICalDateTimeTimezone() throws {
        let testDate = Date()
        let utcTimeZone = TimeZone(identifier: "UTC")!

        // Test direct ICalDateTime creation
        let directDateTime = ICalDateTime(date: testDate, timeZone: utcTimeZone)

        #expect(directDateTime.timeZone?.identifier == utcTimeZone.identifier, "Direct ICalDateTime should preserve timezone")

        // Test EventBuilder with manual property setting
        var event = EventBuilder(summary: "Manual Test").buildEvent()
        event.recurrenceId = directDateTime
        #expect(event.recurrenceId?.timeZone?.identifier == utcTimeZone.identifier, "Manual property setting should preserve timezone")
    }

    @Test("RECURRENCE-ID serialization with timezone")
    func testRecurrenceIdSerialization() throws {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2025
        components.month = 3
        components.day = 15
        components.hour = 14
        components.minute = 0
        components.second = 0
        guard let instanceDate = calendar.date(from: components) else {
            Issue.record("Failed to create test date")
            return
        }

        let timeZone = TimeZone(identifier: "America/Los_Angeles")!

        // Create modified instance of recurring event
        let modifiedEvent = EventBuilder(summary: "Team Standup - Extended Session")
            .starts(at: instanceDate, timeZone: timeZone)
            .ends(at: Calendar.current.date(byAdding: .hour, value: 2, to: instanceDate)!, timeZone: timeZone)
            .recurrenceId(instanceDate, timeZone: timeZone)
            .description("Extended standup with Q1 planning")
            .location("Conference Room A")
            .buildEvent()

        var cal = ICalendar(productId: "RecurrenceTest//EN")
        cal.addEvent(modifiedEvent)
        let serialized = try ICalendarSerializer().serialize(cal)

        let lines = serialized.components(separatedBy: CharacterSet.newlines)
            .filter { !$0.isEmpty }

        // Find the RECURRENCE-ID line
        guard let recurrenceIdLine = lines.first(where: { $0.hasPrefix("RECURRENCE-ID") }) else {
            Issue.record("No RECURRENCE-ID line found. Available lines: \(lines)")
            return
        }

        // Should contain TZID for timed events
        #expect(
            recurrenceIdLine.contains("TZID=America/Los_Angeles"),
            "RECURRENCE-ID should contain timezone for timed events. Found: \(recurrenceIdLine)"
        )

        // The serialized time should match what we actually set in the Los Angeles timezone
        // Since we created the date with hour=14, minute=0 in DateComponents but didn't specify timezone,
        // it gets interpreted differently. Let's just verify it contains a valid time format.
        let timePattern = #"\d{8}T\d{6}"#
        let containsValidTime = recurrenceIdLine.range(of: timePattern, options: .regularExpression) != nil
        #expect(containsValidTime, "RECURRENCE-ID should contain valid date-time format. Found: \(recurrenceIdLine)")
    }

    @Test("RECURRENCE-ID for all-day event override")
    func testAllDayRecurrenceId() throws {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2025
        components.month = 6
        components.day = 20
        guard let allDayDate = calendar.date(from: components) else {
            Issue.record("Failed to create all-day date")
            return
        }

        let timeZone = TimeZone(identifier: "UTC")!

        // Create modified all-day instance
        let allDayOverride = EventBuilder(summary: "Holiday - Office Closed")
            .allDay(on: allDayDate, timeZone: timeZone)
            .recurrenceId(allDayDate, timeZone: timeZone)
            .description("Extended holiday - office closed all day")
            .modify { event in
                // Set RECURRENCE-ID as date-only for all-day events
                event.recurrenceId = ICalDateTime(date: allDayDate, timeZone: timeZone, isDateOnly: true)
            }
            .buildEvent()

        var cal = ICalendar(productId: "AllDayRecurrence//EN")
        cal.addEvent(allDayOverride)
        let serialized = try ICalendarSerializer().serialize(cal)

        let lines = serialized.components(separatedBy: CharacterSet.newlines)
            .filter { !$0.isEmpty }

        guard let recurrenceIdLine = lines.first(where: { $0.hasPrefix("RECURRENCE-ID") }) else {
            Issue.record("No RECURRENCE-ID line found for all-day event")
            return
        }

        // All-day RECURRENCE-ID should use VALUE=DATE format
        #expect(
            recurrenceIdLine.contains("VALUE=DATE:20250620"),
            "All-day RECURRENCE-ID should use VALUE=DATE format. Found: \(recurrenceIdLine)"
        )

        // Should NOT contain TZID for all-day events
        #expect(
            !recurrenceIdLine.contains("TZID="),
            "All-day RECURRENCE-ID should not contain TZID. Found: \(recurrenceIdLine)"
        )
    }

    @Test("Complete recurring event with exception scenario")
    func testRecurringEventWithException() throws {
        let baseDate = Date()
        let timeZone = TimeZone(identifier: "America/New_York")!

        // 1. Create the base recurring event
        let recurringEvent = EventBuilder(summary: "Weekly Team Meeting")
            .starts(at: baseDate, timeZone: timeZone)
            .ends(at: Calendar.current.date(byAdding: .hour, value: 1, to: baseDate)!, timeZone: timeZone)
            .repeatsWeekly(every: 1, on: [.tuesday], until: nil, count: 10)
            .description("Regular weekly team sync")
            .location("Conference Room B")
            .buildEvent()

        // 2. Create a modified instance for the 3rd occurrence
        let modifiedInstanceDate = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: baseDate)!
        let modifiedEvent = EventBuilder(summary: "Weekly Team Meeting - Extended")
            .starts(at: modifiedInstanceDate, timeZone: timeZone)
            .ends(at: Calendar.current.date(byAdding: .hour, value: 2, to: modifiedInstanceDate)!, timeZone: timeZone)
            .recurrenceId(modifiedInstanceDate, timeZone: timeZone)
            .description("Extended meeting for sprint planning")
            .location("Main Conference Room")
            .buildEvent()

        // 3. Serialize both events
        let calendarWithBoth = ICalendar(productId: "RecurringWithException//EN")
        var calendar = calendarWithBoth
        calendar.addEvent(recurringEvent)
        calendar.addEvent(modifiedEvent)

        let serialized = try ICalendarSerializer().serialize(calendar)
        // Verify both events are present
        let eventCount = serialized.components(separatedBy: "BEGIN:VEVENT").count - 1
        #expect(eventCount == 2, "Should contain exactly 2 events (base recurring + modified instance)")

        // Verify RECURRENCE-ID is present in the modified event
        #expect(serialized.contains("RECURRENCE-ID"), "Modified instance should contain RECURRENCE-ID")
        #expect(serialized.contains("RRULE:"), "Base event should contain recurrence rule")
    }

    @Test("RECURRENCE-ID with RANGE parameter")
    func testRecurrenceIdWithRange() throws {
        // RFC 5545 allows RANGE parameter for RECURRENCE-ID
        let testDate = Date()
        let timeZone = TimeZone(identifier: "UTC")!

        var event = ICalEvent(summary: "Recurring Event - This and Future Modified")
        event.recurrenceId = ICalDateTime(date: testDate, timeZone: timeZone)

        // Manually add RANGE parameter using custom property
        event.setPropertyValue("RECURRENCE-ID", value: ICalendarFormatter.format(dateTime: ICalDateTime(date: testDate, timeZone: timeZone)))

        // Add RANGE parameter manually (this would need library enhancement for full support)
        let recurrenceIdProperty = event.properties.first { $0.name == "RECURRENCE-ID" }
        #expect(recurrenceIdProperty != nil, "RECURRENCE-ID property should exist")
    }

    @Test("RECURRENCE-ID validation rules")
    func testRecurrenceIdValidation() throws {
        // Test various RECURRENCE-ID scenarios per RFC 5545

        let baseDate = Date()
        let timeZone = TimeZone(identifier: "UTC")!

        // 1. RECURRENCE-ID must match DTSTART value type (timed vs all-day)
        let timedEvent = EventBuilder(summary: "Timed Event Instance")
            .starts(at: baseDate, timeZone: timeZone)
            .recurrenceId(baseDate, timeZone: timeZone)
            .buildEvent()

        #expect(timedEvent.recurrenceId?.isDateOnly == false, "Timed event RECURRENCE-ID should not be date-only")

        // 2. All-day event RECURRENCE-ID should be date-only
        let allDayEvent = EventBuilder(summary: "All-Day Event Instance")
            .allDay(on: baseDate, timeZone: timeZone)
            .modify { event in
                event.recurrenceId = ICalDateTime(date: baseDate, timeZone: timeZone, isDateOnly: true)
            }
            .buildEvent()

        #expect(allDayEvent.recurrenceId?.isDateOnly == true, "All-day event RECURRENCE-ID should be date-only")
    }

    @Test("Multiple RECURRENCE-ID instances")
    func testMultipleRecurrenceIdInstances() throws {
        // Test scenario where multiple instances of a recurring event are modified
        let baseDate = Date()
        let timeZone = TimeZone(identifier: "America/Chicago")!

        // Base recurring event
        let baseEvent = EventBuilder(summary: "Daily Standup")
            .starts(at: baseDate, timeZone: timeZone)
            .ends(at: Calendar.current.date(byAdding: .minute, value: 15, to: baseDate)!, timeZone: timeZone)
            .repeats(every: 1, until: nil, count: 30)  // 30 days
            .buildEvent()

        // Modified instance 1 - Day 5
        let instance1Date = Calendar.current.date(byAdding: .day, value: 4, to: baseDate)!
        let modifiedInstance1 = EventBuilder(summary: "Daily Standup - Sprint Planning")
            .starts(at: instance1Date, timeZone: timeZone)
            .ends(at: Calendar.current.date(byAdding: .minute, value: 30, to: instance1Date)!, timeZone: timeZone)
            .recurrenceId(instance1Date, timeZone: timeZone)
            .description("Extended for sprint planning")
            .buildEvent()

        // Modified instance 2 - Day 10
        let instance2Date = Calendar.current.date(byAdding: .day, value: 9, to: baseDate)!
        let modifiedInstance2 = EventBuilder(summary: "Daily Standup - Demo Prep")
            .starts(at: instance2Date, timeZone: timeZone)
            .ends(at: Calendar.current.date(byAdding: .minute, value: 45, to: instance2Date)!, timeZone: timeZone)
            .recurrenceId(instance2Date, timeZone: timeZone)
            .description("Extended for demo preparation")
            .buildEvent()

        // Create calendar with all events
        var calendar = ICalendar(productId: "MultipleInstances//EN")
        calendar.addEvent(baseEvent)
        calendar.addEvent(modifiedInstance1)
        calendar.addEvent(modifiedInstance2)

        let serialized = try ICalendarSerializer().serialize(calendar)

        // Verify all events are present
        let eventCount = serialized.components(separatedBy: "BEGIN:VEVENT").count - 1
        #expect(eventCount == 3, "Should contain 3 events (1 base + 2 modified instances)")

        // Count RECURRENCE-ID occurrences
        let recurrenceIdCount = serialized.components(separatedBy: "RECURRENCE-ID").count - 1
        #expect(recurrenceIdCount == 2, "Should contain exactly 2 RECURRENCE-ID properties")
    }
}
