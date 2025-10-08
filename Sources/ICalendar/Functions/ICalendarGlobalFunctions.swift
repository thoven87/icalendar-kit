import Foundation

// MARK: - Calendar Statistics

public struct CalendarStatistics: Sendable {
    public let eventCount: Int
    public let todoCount: Int
    public let journalCount: Int
    public let timeZoneCount: Int
    public let totalAttendees: Int
    public let eventsWithAlarms: Int
    public let recurringEvents: Int
    public let serializationStats: SerializationStatistics

    public var description: String {
        """
        Calendar Statistics:
        - Events: \(eventCount)
        - Todos: \(todoCount)
        - Journals: \(journalCount)
        - Time Zones: \(timeZoneCount)
        - Total Attendees: \(totalAttendees)
        - Events with Alarms: \(eventsWithAlarms)
        - Recurring Events: \(recurringEvents)

        \(serializationStats.description)
        """
    }
}

// SerializationStatistics is defined in ICalendarSerializer.swift

// MARK: - iCalendar Kit Version 2.0 API
// Static namespace to replace the ICalendarClient API with cleaner, namespaced functions

public enum ICalendarKit {

    // MARK: - Parsing Operations

    /// Parse iCalendar content from string
    public static func parseCalendar(from content: String, validateOnParse: Bool = true) throws -> ICalendar {
        let parser = ICalendarParser()

        if validateOnParse {
            return try parser.parseAndValidate(content)
        } else {
            return try parser.parse(content)
        }
    }

    /// Parse iCalendar content from data
    public static func parseCalendar(from data: Data, validateOnParse: Bool = true) throws -> ICalendar {
        let parser = ICalendarParser()

        if validateOnParse {
            let calendar = try parser.parse(data)
            try parser.validate(calendar)
            return calendar
        } else {
            return try parser.parse(data)
        }
    }

    /// Parse iCalendar file from URL
    public static func parseCalendar(from url: URL, validateOnParse: Bool = true) throws -> ICalendar {
        let parser = ICalendarParser()

        if validateOnParse {
            let calendar = try parser.parseFile(at: url)
            try parser.validate(calendar)
            return calendar
        } else {
            return try parser.parseFile(at: url)
        }
    }

    /// Parse multiple calendars from content
    public static func parseCalendars(from content: String, validateOnParse: Bool = true) throws -> [ICalendar] {
        let parser = ICalendarParser()
        let calendars = try parser.parseMultiple(content)

        if validateOnParse {
            for calendar in calendars {
                try parser.validate(calendar)
            }
        }

        return calendars
    }

    // MARK: - Serialization Operations

    /// Serialize calendar to string
    public static func serializeCalendar(_ calendar: ICalendar, validateBeforeSerializing: Bool = true) throws -> String {
        let serializer = ICalendarSerializer(
            options: ICalendarSerializer.SerializationOptions(
                validateBeforeSerializing: validateBeforeSerializing
            )
        )
        return try serializer.serialize(calendar)
    }

    /// Serialize calendar to data
    public static func serializeCalendar(_ calendar: ICalendar, validateBeforeSerializing: Bool = true) throws -> Data {
        let serializer = ICalendarSerializer(
            options: ICalendarSerializer.SerializationOptions(
                validateBeforeSerializing: validateBeforeSerializing
            )
        )
        return try serializer.serializeToData(calendar)
    }

    /// Serialize calendar to file
    public static func serializeCalendar(_ calendar: ICalendar, to url: URL, validateBeforeSerializing: Bool = true) throws {
        let serializer = ICalendarSerializer(
            options: ICalendarSerializer.SerializationOptions(
                validateBeforeSerializing: validateBeforeSerializing
            )
        )
        try serializer.serializeToFile(calendar, url: url)
    }

    /// Serialize multiple calendars
    public static func serializeCalendars(_ calendars: [ICalendar], validateBeforeSerializing: Bool = true) throws -> String {
        let serializer = ICalendarSerializer(
            options: ICalendarSerializer.SerializationOptions(
                validateBeforeSerializing: validateBeforeSerializing
            )
        )
        return try serializer.serialize(calendars)
    }

    // MARK: - Validation Operations

    /// Validate a calendar
    public static func validateCalendar(_ calendar: ICalendar) throws {
        let parser = ICalendarParser()
        try parser.validate(calendar)
    }

    /// Get calendar statistics
    public static func getCalendarStatistics(_ calendar: ICalendar) -> CalendarStatistics {
        let serializer = ICalendarSerializer()

        // Get actual serialization stats
        let serializationStats = serializer.getStatistics(calendar)

        let totalAttendees = calendar.events.reduce(0) { $0 + $1.attendees.count }
        let eventsWithAlarms = calendar.events.filter { !$0.alarms.isEmpty }.count
        let recurringEvents = calendar.events.filter { $0.recurrenceRule != nil }.count

        return CalendarStatistics(
            eventCount: calendar.events.count,
            todoCount: calendar.todos.count,
            journalCount: calendar.journals.count,
            timeZoneCount: calendar.timeZones.count,
            totalAttendees: totalAttendees,
            eventsWithAlarms: eventsWithAlarms,
            recurringEvents: recurringEvents,
            serializationStats: serializationStats
        )
    }

    // MARK: - Search Operations

    /// Find events by date range
    public static func findEvents(
        in calendar: ICalendar,
        from startDate: Date,
        to endDate: Date
    ) -> [ICalEvent] {
        calendar.events.filter { event in
            guard let eventStart = event.dateTimeStart?.date else { return false }

            if let eventEnd = event.dateTimeEnd?.date {
                return eventStart <= endDate && eventEnd >= startDate
            } else if let duration = event.duration {
                let eventEnd = eventStart.addingTimeInterval(duration.totalSeconds)
                return eventStart <= endDate && eventEnd >= startDate
            } else {
                return eventStart >= startDate && eventStart <= endDate
            }
        }
    }

    /// Find todos by status
    public static func findTodos(
        in calendar: ICalendar,
        status: ICalTodoStatus
    ) -> [ICalTodo] {
        calendar.todos.filter { $0.status == status }
    }

    /// Find overdue todos
    public static func findOverdueTodos(in calendar: ICalendar, asOf date: Date = Date()) -> [ICalTodo] {
        calendar.todos.filter { todo in
            guard let due = todo.dueDate?.date else { return false }
            return due < date && todo.status != .completed && todo.status != .cancelled
        }
    }

    /// Find an event by UID
    public static func findEvent(in calendar: ICalendar, withUID uid: String) -> ICalEvent? {
        calendar.events.first { $0.uid == uid }
    }

    /// Find events by summary (title)
    public static func findEvents(
        in calendar: ICalendar,
        withSummary summary: String,
        caseSensitive: Bool = false
    ) -> [ICalEvent] {
        calendar.events.filter { event in
            guard let eventSummary = event.summary else { return false }
            if caseSensitive {
                return eventSummary.contains(summary)
            } else {
                return eventSummary.lowercased().contains(summary.lowercased())
            }
        }
    }
}

// MARK: - Factory Methods Namespace

public enum ICalendarFactory {

    // MARK: - Event Creation

    /// Create a simple event
    public static func createEvent(
        summary: String,
        startDate: Date,
        endDate: Date? = nil,
        duration: ICalDuration? = nil,
        location: String? = nil,
        description: String? = nil,
        uid: String? = nil,
        timeZone: TimeZone = .gmt
    ) -> ICalEvent {
        var event = ICalEvent(uid: uid ?? UUID().uuidString, summary: summary)

        event.dateTimeStamp = ICalDateTime(date: Date(), timeZone: timeZone)
        event.dateTimeStart = ICalDateTime(date: startDate, timeZone: timeZone)

        if let endDate = endDate {
            event.dateTimeEnd = ICalDateTime(date: endDate)
        } else if let duration = duration {
            event.duration = duration
        }

        if let location = location {
            event.location = location
        }

        if let description = description {
            event.description = description
        }

        return event
    }

    /// Create an all-day event
    public static func createAllDayEvent(
        summary: String,
        date: Date,
        location: String? = nil,
        description: String? = nil,
        uid: String? = nil
    ) -> ICalEvent {
        var event = ICalEvent(uid: uid ?? UUID().uuidString, summary: summary)

        event.dateTimeStamp = ICalDateTime(date: Date(), timeZone: .gmt)
        event.dateTimeStart = ICalDateTime(date: date, timeZone: nil, isDateOnly: true)

        if let location = location {
            event.location = location
        }

        if let description = description {
            event.description = description
        }

        return event
    }

    /// Create a recurring event
    public static func createRecurringEvent(
        summary: String,
        startDate: Date,
        endDate: Date? = nil,
        recurrenceRule: ICalRecurrenceRule,
        location: String? = nil,
        description: String? = nil,
        uid: String? = nil,
        timeZone: TimeZone = .gmt
    ) -> ICalEvent {
        var event = createEvent(
            summary: summary,
            startDate: startDate,
            endDate: endDate,
            location: location,
            description: description,
            uid: uid,
            timeZone: timeZone
        )

        event.recurrenceRule = recurrenceRule
        return event
    }

    // MARK: - Todo Creation

    /// Create a simple todo
    public static func createTodo(
        summary: String,
        dueDate: Date? = nil,
        priority: Int? = nil,
        description: String? = nil,
        uid: String? = nil,
        timeZone: TimeZone = .gmt
    ) -> ICalTodo {
        var todo = ICalTodo(uid: uid ?? UUID().uuidString, summary: summary)

        todo.dateTimeStamp = ICalDateTime(date: Date(), timeZone: timeZone)

        if let dueDate = dueDate {
            todo.dueDate = ICalDateTime(date: dueDate, timeZone: timeZone)
        }

        if let priority = priority {
            todo.priority = priority
        }

        if let description = description {
            todo.description = description
        }

        return todo
    }

    /// Create a todo with start date
    public static func createTodo(
        summary: String,
        startDate: Date,
        dueDate: Date? = nil,
        priority: Int? = nil,
        description: String? = nil,
        uid: String? = nil,
        timeZone: TimeZone = .gmt
    ) -> ICalTodo {
        var todo = createTodo(
            summary: summary,
            dueDate: dueDate,
            priority: priority,
            description: description,
            uid: uid,
            timeZone: timeZone
        )

        todo.dateTimeStart = ICalDateTime(date: startDate, timeZone: timeZone)
        return todo
    }

    // MARK: - Alarm Creation

    /// Create a display alarm
    public static func createDisplayAlarm(
        description: String,
        triggerMinutesBefore: Int
    ) -> ICalAlarm {
        let trigger = "-PT\(triggerMinutesBefore)M"
        return ICalAlarm(displayAlarm: trigger, description: description)
    }

    /// Create an audio alarm
    public static func createAudioAlarm(
        triggerMinutesBefore: Int,
        audioFile: String? = nil
    ) -> ICalAlarm {
        let trigger = "-PT\(triggerMinutesBefore)M"
        var alarm = ICalAlarm(audioAlarm: trigger)
        if let audioFile = audioFile {
            alarm.attach = audioFile
        }
        return alarm
    }

    /// Create an email alarm
    public static func createEmailAlarm(
        summary: String,
        description: String,
        attendees: [ICalAttendee],
        triggerMinutesBefore: Int
    ) -> ICalAlarm {
        let trigger = "-PT\(triggerMinutesBefore)M"
        let primaryAttendee = attendees.first ?? ICalAttendee(email: "noreply@example.com", commonName: "Event Notification")
        var alarm = ICalAlarm(emailAlarm: trigger, description: description, summary: summary, attendee: primaryAttendee)
        // Add any additional attendees
        if attendees.count > 1 {
            alarm.attendees = attendees
        }
        return alarm
    }

    // MARK: - Attendee Creation

    /// Create an attendee
    public static func createAttendee(
        email: String,
        name: String? = nil,
        role: ICalRole = .requiredParticipant,
        status: ICalParticipationStatus = .needsAction,
        rsvp: Bool = false
    ) -> ICalAttendee {
        ICalAttendee(
            email: email,
            commonName: name,
            role: role,
            participationStatus: status,
            rsvp: rsvp
        )
    }

    /// Create an organizer
    public static func createOrganizer(
        email: String,
        name: String? = nil
    ) -> ICalAttendee {
        ICalAttendee(
            email: email,
            commonName: name,
            role: .chair,
            participationStatus: .accepted
        )
    }

    // MARK: - Recurrence Rule Creation

    /// Create a daily recurrence rule
    public static func createDailyRecurrence(
        interval: Int = 1,
        count: Int? = nil,
        until: Date? = nil
    ) -> ICalRecurrenceRule {
        ICalRecurrenceRule(
            frequency: .daily,
            until: until.map { ICalDateTime(date: $0) },
            count: count,
            interval: interval
        )
    }

    /// Create a weekly recurrence rule
    public static func createWeeklyRecurrence(
        interval: Int = 1,
        daysOfWeek: [ICalWeekday] = [],
        count: Int? = nil,
        until: Date? = nil,
        timeZone: TimeZone = .gmt
    ) -> ICalRecurrenceRule {
        ICalRecurrenceRule(
            frequency: .weekly,
            until: until.map { ICalDateTime(date: $0, timeZone: timeZone) },
            count: count,
            interval: interval,
            byWeekday: daysOfWeek
        )
    }

    /// Create a monthly recurrence rule
    public static func createMonthlyRecurrence(
        interval: Int = 1,
        dayOfMonth: Int? = nil,
        weekdayOrdinal: Int? = nil,
        weekday: ICalWeekday? = nil,
        count: Int? = nil,
        until: Date? = nil,
        timeZone: TimeZone = .gmt
    ) -> ICalRecurrenceRule {
        if let dayOfMonth = dayOfMonth {
            // Monthly on specific day (e.g., 15th of every month)
            return ICalRecurrenceRule(
                frequency: .monthly,
                until: until.map { ICalDateTime(date: $0, timeZone: timeZone) },
                count: count,
                interval: interval,
                byMonthday: [dayOfMonth]
            )
        } else if let weekday = weekday, let ordinal = weekdayOrdinal {
            // Monthly on ordinal weekday (e.g., first Monday, last Friday)
            return ICalRecurrenceRule(
                frequency: .monthly,
                until: until.map { ICalDateTime(date: $0, timeZone: timeZone) },
                count: count,
                interval: interval,
                byWeekday: [weekday],
                bySetpos: [ordinal]
            )
        } else {
            // Default monthly recurrence
            return ICalRecurrenceRule(
                frequency: .monthly,
                until: until.map { ICalDateTime(date: $0, timeZone: timeZone) },
                count: count,
                interval: interval
            )
        }
    }

    /// Create a yearly recurrence rule
    public static func createYearlyRecurrence(
        interval: Int = 1,
        month: Int? = nil,
        dayOfMonth: Int? = nil,
        count: Int? = nil,
        until: Date? = nil,
        timeZone: TimeZone = .gmt
    ) -> ICalRecurrenceRule {
        ICalRecurrenceRule(
            frequency: .yearly,
            until: until.map { ICalDateTime(date: $0, timeZone: timeZone) },
            count: count,
            interval: interval,
            byMonthday: dayOfMonth.map { [$0] } ?? [],
            byMonth: month.map { [$0] } ?? []
        )
    }

    // MARK: - Utility Creation

    /// Create refresh interval from components
    public static func createDuration(
        weeks: Int = 0,
        days: Int = 0,
        hours: Int = 0,
        minutes: Int = 0,
        seconds: Int = 0
    ) -> ICalDuration {
        ICalDuration(
            weeks: weeks,
            days: days,
            hours: hours,
            minutes: minutes,
            seconds: seconds
        )
    }

    /// Create geographic coordinates
    public static func createGeoCoordinate(latitude: Double, longitude: Double) -> ICalGeoCoordinate {
        ICalGeoCoordinate(latitude: latitude, longitude: longitude)
    }
}

// MARK: - DateTime Utilities Namespace

public enum ICalendarDateTime {

    /// Parse a datetime string with timezone support
    public static func parse(_ value: String, timeZone: TimeZone = .gmt) -> ICalDateTime? {
        ICalendarFormatter.parseDateTime(value, timeZone: timeZone)
    }

    /// Format a datetime object to iCalendar string format
    public static func format(_ dateTime: ICalDateTime) -> String {
        ICalendarFormatter.format(dateTime: dateTime)
    }
}
