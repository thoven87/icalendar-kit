import Foundation
import ICalendar
import Testing

// MARK: - Recurring Event Test Suite
@Suite("Recurring Event Tests")
struct RecurringEventTests {

    static let estTimeZone = TimeZone(identifier: "America/New_York")!

    // MARK: - Test Cases Based on ical4j Examples

    /// Test 1: Weekly recurring on weekdays (our main use case)
    /// Expected: FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;WKST=MO
    @Test("Weekly Weekdays Recurring")
    func testWeeklyWeekdays() throws {
        // Create event starting on first Monday of 2024
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.estTimeZone

        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 9))!
        // January 1, 2024 is a Monday - perfect start date

        let event = EventBuilder(summary: "Weekly Weekday Test")
            .starts(at: startDate, timeZone: Self.estTimeZone)
            .duration(8 * 3600)
            .repeatsWeekly(every: 1, on: [.monday, .tuesday, .wednesday, .thursday, .friday])
            .buildEvent()

        // Validate the generated RRULE
        let rrule = try #require(event.recurrenceRule, "No recurrence rule generated")

        // Validate recurrence rule properties directly
        #expect(rrule.frequency == .weekly, "Expected weekly frequency")
        #expect(rrule.byWeekday.contains(.monday), "Should contain Monday")
        #expect(rrule.byWeekday.contains(.tuesday), "Should contain Tuesday")
        #expect(rrule.byWeekday.contains(.wednesday), "Should contain Wednesday")
        #expect(rrule.byWeekday.contains(.thursday), "Should contain Thursday")
        #expect(rrule.byWeekday.contains(.friday), "Should contain Friday")
        #expect(!rrule.byWeekday.contains(.saturday), "Should not contain Saturday")
        #expect(!rrule.byWeekday.contains(.sunday), "Should not contain Sunday")

        // Test that we can serialize the calendar
        var icalendar = ICalendar(productId: "-//Test//Test//EN")
        if let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") {
            icalendar.addTimeZone(vtimezone)
        }
        icalendar.addEvent(event)

        let icsString: String = try ICalendarKit.serializeCalendar(icalendar)
        #expect(icsString.contains("FREQ=WEEKLY"), "Generated ICS should contain FREQ=WEEKLY")
        #expect(icsString.contains("BYDAY=MO,TU,WE,TH,FR"), "Generated ICS should contain weekdays")
    }

    /// Test 2: Monthly on first Monday (proper monthly pattern)
    /// Expected: FREQ=MONTHLY;BYDAY=MO;BYSETPOS=1;WKST=MO
    @Test("Monthly First Monday")
    func testMonthlyFirstMonday() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.estTimeZone

        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 9))!

        // Create monthly recurring rule with BYSETPOS
        let recurrenceRule = ICalRecurrenceRule(
            frequency: .monthly,
            interval: 1,
            byWeekday: [.monday],
            bySetpos: [1]  // First occurrence
        )

        var event = ICalEvent()
        event.summary = "Monthly First Monday Test"
        event.dateTimeStart = ICalDateTime(date: startDate, timeZone: Self.estTimeZone)
        event.duration = ICalDuration(hours: 8)
        event.recurrenceRule = recurrenceRule
        event.dateTimeStamp = ICalDateTime(date: Date())
        event.uid = UUID().uuidString

        // Validate recurrence rule properties
        #expect(recurrenceRule.frequency == .monthly, "Expected monthly frequency")
        #expect(recurrenceRule.byWeekday == [.monday], "Expected Monday only")
        #expect(recurrenceRule.bySetpos == [1], "Expected first position")

        // Test serialization
        var icalendar = ICalendar(productId: "-//Test//Test//EN")
        icalendar.addEvent(event)

        let icsString: String = try ICalendarKit.serializeCalendar(icalendar)
        #expect(icsString.contains("FREQ=MONTHLY"), "Generated ICS should contain FREQ=MONTHLY")
        #expect(icsString.contains("BYDAY=MO"), "Generated ICS should contain BYDAY=MO")
    }

    /// Test 3: Yearly recurring (based on ical4j example)
    /// Expected: FREQ=YEARLY;BYMONTH=4;BYDAY=SU;BYSETPOS=3
    /// "Third Sunday of April"
    @Test("Yearly Third Sunday of April")
    func testYearlyThirdSundayApril() throws {
        // Create recurrence rule matching ical4j example
        let recurrenceRule = ICalRecurrenceRule(
            frequency: .yearly,
            byWeekday: [.sunday],  // Sunday
            byMonth: [4],  // April
            bySetpos: [3]  // Third occurrence
        )

        // Validate recurrence rule properties directly
        #expect(recurrenceRule.frequency == .yearly, "Expected yearly frequency")
        #expect(recurrenceRule.byMonth == [4], "Expected April (month 4)")
        #expect(recurrenceRule.byWeekday == [.sunday], "Expected Sunday")
        #expect(recurrenceRule.bySetpos == [3], "Expected third position")
    }

    /// Test 4: Monthly last Sunday (negative SETPOS)
    /// Expected: FREQ=MONTHLY;INTERVAL=3;BYDAY=SU;BYSETPOS=-1
    /// "Last Sunday of every 3 months"
    @Test("Monthly Last Sunday")
    func testMonthlyLastSunday() throws {
        let recurrenceRule = ICalRecurrenceRule(
            frequency: .monthly,
            interval: 3,  // Every 3 months
            byWeekday: [.sunday],  // Sunday
            bySetpos: [-1]  // Last occurrence
        )

        // Validate recurrence rule properties
        #expect(recurrenceRule.frequency == .monthly, "Expected monthly frequency")
        #expect(recurrenceRule.interval == 3, "Expected interval of 3")
        #expect(recurrenceRule.byWeekday == [.sunday], "Expected Sunday")
        #expect(recurrenceRule.bySetpos == [-1], "Expected last position (-1)")
    }

    /// Test 5: Daily with COUNT limit
    /// Expected: FREQ=DAILY;COUNT=10
    @Test("Daily with Count")
    func testDailyWithCount() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.estTimeZone

        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 9))!

        let event = EventBuilder(summary: "Daily Count Test")
            .starts(at: startDate, timeZone: Self.estTimeZone)
            .duration(3600)
            .repeats(every: 1, count: 10)  // 10 occurrences
            .buildEvent()

        let rrule = try #require(event.recurrenceRule, "No recurrence rule generated")

        // Validate recurrence rule properties
        #expect(rrule.frequency == .daily, "Expected daily frequency")
        #expect(rrule.count == 10, "Expected count of 10")
        #expect(rrule.interval == 1, "Expected interval of 1")
    }

    /// Test 6: Weekly with UNTIL date
    @Test("Weekly with Until Date")
    func testWeeklyWithUntil() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.estTimeZone

        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 9))!
        let endDate = calendar.date(from: DateComponents(year: 2024, month: 6, day: 30))!

        let event = EventBuilder(summary: "Weekly Until Test")
            .starts(at: startDate, timeZone: Self.estTimeZone)
            .duration(3600)
            .repeatsWeekly(every: 1, on: [.monday], until: endDate)
            .buildEvent()

        let rrule = try #require(event.recurrenceRule, "No recurrence rule generated")

        // Validate recurrence rule properties
        #expect(rrule.frequency == .weekly, "Expected weekly frequency")
        #expect(rrule.byWeekday == [.monday], "Expected Monday only")
        #expect(rrule.until != nil, "Expected until date to be set")
        #expect(rrule.count == nil, "Expected count to be nil when until is used")
    }

    // MARK: - Calendar Generation Test

    /// Test the complete calendar generation with recurring events
    @Test("Complete Calendar Generation")
    func testCompleteCalendarGeneration() throws {
        var calendar = ICalendar(productId: "-//Test//Test//EN")
        calendar.name = "Test Calendar"

        // Add VTIMEZONE component
        if let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") {
            calendar.addTimeZone(vtimezone)
        }

        // Add a weekly recurring event
        let startDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 9))!

        let recurringEvent = EventBuilder(summary: "Test Recurring Event")
            .starts(at: startDate, timeZone: Self.estTimeZone)
            .duration(8 * 3600)
            .repeatsWeekly(every: 1, on: [.monday, .tuesday, .wednesday, .thursday, .friday])
            .organizer(email: "test@example.com", name: "Test Organizer")
            .description("Test recurring event for validation")
            .categories("Test")
            .confirmed()
            .createdNow()
            .addAlarm(action: .display, minutesBefore: 15, description: "Test recurring event reminder")
            .buildEvent()

        calendar.addEvent(recurringEvent)

        let icsString: String = try ICalendarKit.serializeCalendar(calendar)

        // Validate the generated ICS contains expected elements
        let expectedElements = [
            "BEGIN:VCALENDAR",
            "BEGIN:VTIMEZONE",
            "TZID:America/New_York",
            "BEGIN:VEVENT",
            "DTSTART;TZID=America/New_York:20240101T090000",
            "RRULE:FREQ=WEEKLY",
            "BYDAY=MO,TU,WE,TH,FR",
            "DURATION:PT8H",
            "BEGIN:VALARM",
            "TRIGGER:-PT15M",
            "END:VEVENT",
            "END:VCALENDAR",
        ]

        for element in expectedElements {
            #expect(icsString.contains(element), "Missing element: \(element)")
        }

        #expect(icsString.count > 0, "Generated ICS should not be empty")
    }

    // MARK: - Occurrence Calculation Test

    /// Test occurrence calculation similar to ical4j's calculateRecurrenceSet
    private func testOccurrenceCalculation(event: ICalEvent, startDate: Date) throws {
        let _ = try #require(event.recurrenceRule, "No recurrence rule to test")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.estTimeZone

        // Calculate first week's expected occurrences
        // Starting Monday Jan 1, 2024, we should get Mon, Tue, Wed, Thu, Fri
        let _ = [
            calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!,  // Mon
            calendar.date(from: DateComponents(year: 2024, month: 1, day: 2))!,  // Tue
            calendar.date(from: DateComponents(year: 2024, month: 1, day: 3))!,  // Wed
            calendar.date(from: DateComponents(year: 2024, month: 1, day: 4))!,  // Thu
            calendar.date(from: DateComponents(year: 2024, month: 1, day: 5))!,  // Fri
        ]

        // In a real implementation, we would calculate occurrences here
        // For now, we just validate the pattern makes sense
        let firstWeekday = calendar.component(.weekday, from: startDate)
        #expect(firstWeekday == 2, "Start date should be Monday for weekday pattern, but got weekday \(firstWeekday)")
    }

    // MARK: - Real-World Validation Helper

    /// Generate a test calendar file for manual verification
    @Test("Generate Test Calendar File")
    func testGenerateTestCalendarFile() throws {
        var calendar = ICalendar(productId: "-//RecurringTest//Test v1.0//EN")
        calendar.name = "Recurring Event Test Calendar"
        calendar.calendarDescription = "Test calendar to validate recurring event logic"

        // Add timezone
        if let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: "America/New_York") {
            calendar.addTimeZone(vtimezone)
        }

        // Test 1: Weekly weekdays (main use case)
        let startDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 9))!

        let weeklyEvent = EventBuilder(summary: "Weekly Weekday Test Event")
            .starts(at: startDate, timeZone: Self.estTimeZone)
            .duration(8 * 3600)
            .repeatsWeekly(every: 1, on: [.monday, .tuesday, .wednesday, .thursday, .friday])
            .description("Should appear Monday-Friday every week at 9 AM EST")
            .categories("Test", "Weekly")
            .confirmed()
            .createdNow()
            .addAlarm(action: .display, minutesBefore: 15, description: "Weekly test event reminder")
            .buildEvent()

        calendar.addEvent(weeklyEvent)

        // Test 2: Monthly first Monday
        let monthlyRule = ICalRecurrenceRule(
            frequency: .monthly,
            interval: 1,
            byWeekday: [.monday],
            bySetpos: [1]
        )

        var monthlyEvent = ICalEvent()
        monthlyEvent.summary = "Monthly First Monday Test"
        monthlyEvent.description = "Should appear on first Monday of each month at 10 AM EST"
        monthlyEvent.dateTimeStart = ICalDateTime(
            date: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 10))!,
            timeZone: Self.estTimeZone
        )
        monthlyEvent.duration = ICalDuration(hours: 2)
        monthlyEvent.recurrenceRule = monthlyRule
        monthlyEvent.uid = UUID().uuidString
        monthlyEvent.dateTimeStamp = ICalDateTime(date: Date())
        monthlyEvent.categories = ["Test", "Monthly"]
        monthlyEvent.status = .confirmed

        // Add alarm
        var alarm = ICalAlarm(action: .display, trigger: "-PT30M")
        alarm.description = "Monthly reminder in 30 minutes"
        monthlyEvent.addAlarm(alarm)

        calendar.addEvent(monthlyEvent)

        let icsContent: String = try ICalendarKit.serializeCalendar(calendar)
        #expect(icsContent.contains("BEGIN:VCALENDAR"), "Generated calendar should contain VCALENDAR")
        #expect(icsContent.contains("RRULE:FREQ=WEEKLY"), "Generated calendar should contain weekly rule")
        #expect(icsContent.contains("RRULE:FREQ=MONTHLY"), "Generated calendar should contain monthly rule")
        #expect(icsContent.contains("BYDAY=MO,TU,WE,TH,FR"), "Generated calendar should contain weekdays")
    }
}
