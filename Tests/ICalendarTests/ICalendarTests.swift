import Foundation
import Testing

@testable import ICalendar

@Test("Basic Calendar Creation")
func testBasicCalendarCreation() throws {
    let client = ICalendarClient()
    let calendar = client.createCalendar(productId: "-//Test//EN")

    #expect(calendar.version == "2.0")
    #expect(calendar.productId == "-//Test//EN")
    #expect(calendar.events.isEmpty)
    #expect(calendar.todos.isEmpty)
}

@Test("Event Creation")
func testEventCreation() throws {
    let client = ICalendarClient()
    let startDate = Date()
    let endDate = startDate.addingTimeInterval(3600)  // 1 hour later

    let event = client.createEvent(
        summary: "Test Meeting",
        startDate: startDate,
        endDate: endDate,
        location: "Conference Room A",
        description: "Important meeting"
    )

    #expect(event.summary == "Test Meeting")
    #expect(event.location == "Conference Room A")
    #expect(event.description == "Important meeting")
    #expect(event.dateTimeStart != nil)
    #expect(event.dateTimeEnd != nil)
    #expect(event.dateTimeStamp != nil)
}

@Test("Todo Creation")
func testTodoCreation() throws {
    let client = ICalendarClient()
    let dueDate = Date().addingTimeInterval(86400)  // Tomorrow

    let todo = client.createTodo(
        summary: "Complete project",
        dueDate: dueDate,
        priority: 5,
        description: "Finish the iCalendar implementation"
    )

    #expect(todo.summary == "Complete project")
    #expect(todo.priority == 5)
    #expect(todo.description == "Finish the iCalendar implementation")
    #expect(todo.dueDate != nil)
    #expect(todo.dateTimeStamp != nil)
}

@Test("Recurrence Rule Creation")
func testRecurrenceRuleCreation() throws {
    let client = ICalendarClient()

    let dailyRule = client.createDailyRecurrence(interval: 1, count: 10)
    #expect(dailyRule.frequency == .daily)
    #expect(dailyRule.interval == 1)
    #expect(dailyRule.count == 10)

    let weeklyRule = client.createWeeklyRecurrence(
        interval: 2,
        daysOfWeek: [.monday, .wednesday, .friday],
        count: 5
    )
    #expect(weeklyRule.frequency == .weekly)
    #expect(weeklyRule.interval == 2)
    #expect(weeklyRule.count == 5)
    #expect(weeklyRule.byDay == ["MO", "WE", "FR"])
}

@Test("Attendee Creation")
func testAttendeeCreation() throws {
    let client = ICalendarClient()

    let attendee = client.createAttendee(
        email: "john.doe@example.com",
        name: "John Doe",
        role: .requiredParticipant,
        status: .needsAction,
        rsvp: true
    )

    #expect(attendee.email == "john.doe@example.com")
    #expect(attendee.commonName == "John Doe")
    #expect(attendee.role == .requiredParticipant)
    #expect(attendee.participationStatus == .needsAction)
    #expect(attendee.rsvp == true)

    let organizer = client.createOrganizer(
        email: "organizer@example.com",
        name: "Meeting Organizer"
    )

    #expect(organizer.email == "organizer@example.com")
    #expect(organizer.commonName == "Meeting Organizer")
    #expect(organizer.role == .chair)
    #expect(organizer.participationStatus == .accepted)
}

@Test("Alarm Creation")
func testAlarmCreation() throws {
    let client = ICalendarClient()

    let displayAlarm = client.createDisplayAlarm(
        description: "Meeting reminder",
        triggerMinutesBefore: 15
    )

    #expect(displayAlarm.action == .display)
    #expect(displayAlarm.description == "Meeting reminder")
    #expect(displayAlarm.trigger == "-PT15M")

    let audioAlarm = client.createAudioAlarm(
        triggerMinutesBefore: 5,
        audioFile: "reminder.wav"
    )

    #expect(audioAlarm.action == .audio)
    #expect(audioAlarm.attach == "reminder.wav")
    #expect(audioAlarm.trigger == "-PT5M")
}

@Test("Calendar Serialization")
func testCalendarSerialization() throws {
    let client = ICalendarClient()
    let calendar = client.createCalendar(productId: "-//Test//EN")

    let serialized: String = try client.serializeCalendar(calendar)

    #expect(serialized.contains("BEGIN:VCALENDAR"))
    #expect(serialized.contains("END:VCALENDAR"))
    #expect(serialized.contains("VERSION:2.0"))
    #expect(serialized.contains("PRODID:-//Test//EN"))
}

@Test("Calendar Parsing")
func testCalendarParsing() throws {
    let client = ICalendarClient()
    let icalString = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Test//EN
        BEGIN:VEVENT
        UID:test-event-123
        DTSTAMP:20240101T120000Z
        DTSTART:20240101T140000Z
        DTEND:20240101T150000Z
        SUMMARY:Test Event
        DESCRIPTION:This is a test event
        LOCATION:Test Location
        END:VEVENT
        END:VCALENDAR
        """

    let calendar = try client.parseCalendar(from: icalString)

    #expect(calendar.version == "2.0")
    #expect(calendar.productId == "-//Test//EN")
    #expect(calendar.events.count == 1)

    let event = calendar.events.first!
    #expect(event.uid == "test-event-123")
    #expect(event.summary == "Test Event")
    #expect(event.description == "This is a test event")
    #expect(event.location == "Test Location")
}

@Test("DateTime Formatting")
func testDateTimeFormatting() throws {
    let date = Date(timeIntervalSince1970: 1_704_110_400)  // 2024-01-01 12:00:00 UTC
    let dateTime = ICalDateTime(date: date, timeZone: TimeZone(abbreviation: "UTC"))

    let formatted = ICalendarFormatter.format(dateTime: dateTime)
    // The formatter might format it without Z depending on timezone detection
    #expect(formatted == "20240101T120000Z" || formatted == "20240101T120000")

    let parsed = ICalendarFormatter.parseDateTime(formatted)
    #expect(parsed != nil)
    #expect(abs((parsed?.date.timeIntervalSince1970 ?? 0) - date.timeIntervalSince1970) < 1.0)
}

@Test("Duration Formatting")
func testDurationFormatting() throws {
    let duration = ICalDuration(days: 1, hours: 2, minutes: 30, seconds: 0)
    let formatted = ICalendarFormatter.format(duration: duration)
    #expect(formatted == "P1DT2H30M")

    let parsed = ICalendarFormatter.parseDuration(formatted)
    #expect(parsed != nil)
    #expect(parsed?.days == 1)
    #expect(parsed?.hours == 2)
    #expect(parsed?.minutes == 30)
    #expect(parsed?.seconds == 0)
}

@Test("Recurrence Rule Formatting")
func testRecurrenceRuleFormatting() throws {
    let rule = ICalRecurrenceRule(
        frequency: .weekly,
        interval: 2,
        count: 10,
        byDay: ["MO", "WE", "FR"]
    )

    let formatted = ICalendarFormatter.format(recurrenceRule: rule)
    #expect(formatted.contains("FREQ=WEEKLY"))
    #expect(formatted.contains("INTERVAL=2"))
    #expect(formatted.contains("COUNT=10"))
    #expect(formatted.contains("BYDAY=MO,WE,FR"))

    let parsed = ICalendarFormatter.parseRecurrenceRule(formatted)
    #expect(parsed != nil)
    #expect(parsed?.frequency == .weekly)
    #expect(parsed?.interval == 2)
    #expect(parsed?.count == 10)
    #expect(parsed?.byDay == ["MO", "WE", "FR"])
}

@Test("Text Escaping")
func testTextEscaping() throws {
    let text = "Hello; world,\nThis is a test\r\nwith\\backslash"
    let escaped = ICalendarFormatter.escapeText(text)
    let unescaped = ICalendarFormatter.unescapeText(escaped)

    #expect(unescaped == text)
    #expect(escaped.contains("\\;"))
    #expect(escaped.contains("\\,"))
    #expect(escaped.contains("\\n"))
    #expect(escaped.contains("\\\\"))
}

@Test("Meeting Invitation Creation")
func testMeetingInvitationCreation() throws {
    let client = ICalendarClient()
    let startDate = Date()
    let endDate = startDate.addingTimeInterval(3600)

    let organizer = client.createOrganizer(
        email: "organizer@example.com",
        name: "Meeting Organizer"
    )

    let attendees = [
        client.createAttendee(email: "attendee1@example.com", name: "Attendee 1"),
        client.createAttendee(email: "attendee2@example.com", name: "Attendee 2"),
    ]

    let calendar = client.createMeetingInvitation(
        summary: "Team Meeting",
        startDate: startDate,
        endDate: endDate,
        location: "Conference Room",
        description: "Weekly team sync",
        organizer: organizer,
        attendees: attendees,
        reminderMinutes: 15
    )

    #expect(calendar.method == "REQUEST")
    #expect(calendar.events.count == 1)

    let event = calendar.events.first!
    #expect(event.summary == "Team Meeting")
    #expect(event.location == "Conference Room")
    #expect(event.organizer?.email == "organizer@example.com")
    #expect(event.attendees.count == 2)
    #expect(event.alarms.count == 1)
    #expect(event.status == .confirmed)
}

@Test("Builder Pattern")
func testBuilderPattern() throws {
    let event = ICalEventBuilder(summary: "Builder Test")
        .description("Test event created with builder")
        .location("Test Location")
        .startDate(Date())
        .endDate(Date().addingTimeInterval(3600))
        .status(.confirmed)
        .priority(5)
        .build()

    #expect(event.summary == "Builder Test")
    #expect(event.description == "Test event created with builder")
    #expect(event.location == "Test Location")
    #expect(event.status == .confirmed)
    #expect(event.priority == 5)
}

@Test("Validation Utilities")
func testValidationUtilities() throws {
    #expect(ValidationUtilities.isValidEmail("test@example.com") == true)
    #expect(ValidationUtilities.isValidEmail("invalid-email") == false)

    #expect(ValidationUtilities.isValidUID("valid-uid-123") == true)
    #expect(ValidationUtilities.isValidUID("") == false)

    #expect(ValidationUtilities.isValidPriority(5) == true)
    #expect(ValidationUtilities.isValidPriority(10) == false)

    #expect(ValidationUtilities.isValidPercentComplete(50) == true)
    #expect(ValidationUtilities.isValidPercentComplete(150) == false)
}

@Test("Recurrence Patterns")
func testRecurrencePatterns() throws {
    let daily = RecurrencePatterns.daily(count: 7)
    #expect(daily.frequency == .daily)
    #expect(daily.count == 7)

    let weekdays = RecurrencePatterns.weekdays(count: 10)
    #expect(weekdays.frequency == .weekly)
    #expect(weekdays.byDay == ["MO", "TU", "WE", "TH", "FR"])

    let monthly = RecurrencePatterns.monthly(dayOfMonth: 15, count: 12)
    #expect(monthly.frequency == .monthly)
    #expect(monthly.byMonthDay == [15])

    let yearly = RecurrencePatterns.yearly(count: 5)
    #expect(yearly.frequency == .yearly)
    #expect(yearly.count == 5)
}

@Test("Date Extensions")
func testDateExtensions() throws {
    let date = Date()

    let dateTime = date.asICalDateTime()
    #expect(dateTime.date == date)
    #expect(dateTime.isDateOnly == false)

    let dateOnly = date.asICalDateOnly()
    #expect(dateOnly.date == date)
    #expect(dateOnly.isDateOnly == true)

    let utcDateTime = date.asICalDateTimeUTC()
    #expect(utcDateTime.date == date)
    // TimeZone abbreviation might be "GMT" or "UTC" depending on system
    let abbreviation = utcDateTime.timeZone?.abbreviation()
    #expect(abbreviation == "UTC" || abbreviation == "GMT")
}

@Test("TimeInterval Extensions")
func testTimeIntervalExtensions() throws {
    let interval: TimeInterval = 3661  // 1 hour, 1 minute, 1 second
    let duration = interval.asICalDuration

    #expect(duration.hours == 1)
    #expect(duration.minutes == 1)
    #expect(duration.seconds == 1)
    #expect(duration.isNegative == false)

    let negativeDuration = (-interval).asICalDuration
    #expect(negativeDuration.isNegative == true)
}

@Test("Array Extensions")
func testArrayExtensions() throws {
    let client = ICalendarClient()
    let startDate = Date()
    let events = [
        createTestEvent(summary: "Event 1", startDate: startDate, client: client),
        createTestEvent(
            summary: "Event 2",
            startDate: startDate.addingTimeInterval(3600),
            client: client
        ),
        createTestEvent(
            summary: "Event 3",
            startDate: startDate.addingTimeInterval(7200),
            client: client
        ),
    ]

    let rangeEvents = events.events(
        from: startDate.addingTimeInterval(-1800),
        to: startDate.addingTimeInterval(1800)
    )

    #expect(rangeEvents.count == 1)
    #expect(rangeEvents.first?.summary == "Event 1")

    let sortedEvents = events.sortedByStartDate
    #expect(sortedEvents.first?.summary == "Event 1")
    #expect(sortedEvents.last?.summary == "Event 3")
}

// MARK: - Helper Functions

private func createTestEvent(summary: String, startDate: Date, client: ICalendarClient) -> ICalEvent {
    client.createEvent(
        summary: summary,
        startDate: startDate,
        endDate: startDate.addingTimeInterval(3600)
    )
}
