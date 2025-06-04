import Foundation

/// Main iCalendar client providing high-level interface for parsing and creating calendar events
/// Following RFC 5545, RFC 5546, RFC 6868, RFC 7529, and RFC 7986 with Swift 6 sendable conformance
public struct ICalendarClient: Sendable {

    // MARK: - Configuration

    public struct Configuration: Sendable {
        public let defaultProductId: String
        public let defaultVersion: String
        public let validateOnParse: Bool
        public let validateOnSerialize: Bool
        public let enableExtensions: Bool

        public init(
            defaultProductId: String = "-//ICalendar Kit//EN",
            defaultVersion: String = "2.0",
            validateOnParse: Bool = true,
            validateOnSerialize: Bool = true,
            enableExtensions: Bool = true
        ) {
            self.defaultProductId = defaultProductId
            self.defaultVersion = defaultVersion
            self.validateOnParse = validateOnParse
            self.validateOnSerialize = validateOnSerialize
            self.enableExtensions = enableExtensions
        }

        public static let `default` = Configuration()
        public static let strict = Configuration(
            validateOnParse: true,
            validateOnSerialize: true,
            enableExtensions: false
        )
        public static let permissive = Configuration(
            validateOnParse: false,
            validateOnSerialize: false,
            enableExtensions: true
        )
    }

    private let configuration: Configuration

    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    // MARK: - Parsing Operations

    /// Parse iCalendar content from string
    public func parseCalendar(from content: String) async throws -> ICalendar {
        let parser = ICalendarParser()

        if configuration.validateOnParse {
            return try await parser.parseAndValidate(content)
        } else {
            return try await parser.parse(content)
        }
    }

    /// Parse iCalendar content from data
    public func parseCalendar(from data: Data) async throws -> ICalendar {
        let parser = ICalendarParser()

        if configuration.validateOnParse {
            let calendar = try await parser.parse(data)
            try await parser.validate(calendar)
            return calendar
        } else {
            return try await parser.parse(data)
        }
    }

    /// Parse iCalendar file from URL
    public func parseCalendar(from url: URL) async throws -> ICalendar {
        let parser = ICalendarParser()

        if configuration.validateOnParse {
            let calendar = try await parser.parseFile(at: url)
            try await parser.validate(calendar)
            return calendar
        } else {
            return try await parser.parseFile(at: url)
        }
    }

    /// Parse multiple calendars from content
    public func parseCalendars(from content: String) async throws -> [ICalendar] {
        let parser = ICalendarParser()
        let calendars = try await parser.parseMultiple(content)

        if configuration.validateOnParse {
            for calendar in calendars {
                try await parser.validate(calendar)
            }
        }

        return calendars
    }

    // MARK: - Serialization Operations

    /// Serialize calendar to string
    public func serializeCalendar(_ calendar: ICalendar) async throws -> String {
        let serializer = ICalendarSerializer(
            options: ICalendarSerializer.SerializationOptions(
                validateBeforeSerializing: configuration.validateOnSerialize
            )
        )
        return try await serializer.serialize(calendar)
    }

    /// Serialize calendar to data
    public func serializeCalendar(_ calendar: ICalendar) async throws -> Data {
        let serializer = ICalendarSerializer(
            options: ICalendarSerializer.SerializationOptions(
                validateBeforeSerializing: configuration.validateOnSerialize
            )
        )
        return try await serializer.serializeToData(calendar)
    }

    /// Serialize calendar to file
    public func serializeCalendar(_ calendar: ICalendar, to url: URL) async throws {
        let serializer = ICalendarSerializer(
            options: ICalendarSerializer.SerializationOptions(
                validateBeforeSerializing: configuration.validateOnSerialize
            )
        )
        try await serializer.serializeToFile(calendar, url: url)
    }

    /// Serialize multiple calendars
    public func serializeCalendars(_ calendars: [ICalendar]) async throws -> String {
        let serializer = ICalendarSerializer(
            options: ICalendarSerializer.SerializationOptions(
                validateBeforeSerializing: configuration.validateOnSerialize
            )
        )
        return try await serializer.serialize(calendars)
    }

    // MARK: - Calendar Creation

    /// Create a new empty calendar
    public func createCalendar(productId: String? = nil) -> ICalendar {
        ICalendar(
            productId: productId ?? configuration.defaultProductId,
            version: configuration.defaultVersion
        )
    }

    /// Create calendar with events
    public func createCalendar(events: [ICalEvent], productId: String? = nil) -> ICalendar {
        var calendar = createCalendar(productId: productId)
        for event in events {
            calendar.addEvent(event)
        }
        return calendar
    }

    /// Create calendar with todos
    public func createCalendar(todos: [ICalTodo], productId: String? = nil) -> ICalendar {
        var calendar = createCalendar(productId: productId)
        for todo in todos {
            calendar.addTodo(todo)
        }
        return calendar
    }

    // MARK: - Event Operations

    /// Create a simple event
    public func createEvent(
        summary: String,
        startDate: Date,
        endDate: Date? = nil,
        duration: ICalDuration? = nil,
        location: String? = nil,
        description: String? = nil,
        uid: String? = nil
    ) -> ICalEvent {
        var event = ICalEvent(uid: uid ?? UUID().uuidString, summary: summary)

        event.dateTimeStamp = ICalDateTime(date: Date())
        event.dateTimeStart = ICalDateTime(date: startDate)

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
    public func createAllDayEvent(
        summary: String,
        date: Date,
        location: String? = nil,
        description: String? = nil,
        uid: String? = nil
    ) -> ICalEvent {
        var event = ICalEvent(uid: uid ?? UUID().uuidString, summary: summary)

        event.dateTimeStamp = ICalDateTime(date: Date())
        event.dateTimeStart = ICalDateTime(date: date, isDateOnly: true)

        if let location = location {
            event.location = location
        }

        if let description = description {
            event.description = description
        }

        return event
    }

    /// Create a recurring event
    public func createRecurringEvent(
        summary: String,
        startDate: Date,
        endDate: Date? = nil,
        recurrenceRule: ICalRecurrenceRule,
        location: String? = nil,
        description: String? = nil,
        uid: String? = nil
    ) -> ICalEvent {
        var event = createEvent(
            summary: summary,
            startDate: startDate,
            endDate: endDate,
            location: location,
            description: description,
            uid: uid
        )

        event.recurrenceRule = recurrenceRule
        return event
    }

    // MARK: - Todo Operations

    /// Create a simple todo
    public func createTodo(
        summary: String,
        dueDate: Date? = nil,
        priority: Int? = nil,
        description: String? = nil,
        uid: String? = nil
    ) -> ICalTodo {
        var todo = ICalTodo(uid: uid ?? UUID().uuidString, summary: summary)

        todo.dateTimeStamp = ICalDateTime(date: Date())

        if let dueDate = dueDate {
            todo.dueDate = ICalDateTime(date: dueDate)
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
    public func createTodo(
        summary: String,
        startDate: Date,
        dueDate: Date? = nil,
        priority: Int? = nil,
        description: String? = nil,
        uid: String? = nil
    ) -> ICalTodo {
        var todo = createTodo(
            summary: summary,
            dueDate: dueDate,
            priority: priority,
            description: description,
            uid: uid
        )

        todo.dateTimeStart = ICalDateTime(date: startDate)
        return todo
    }

    // MARK: - Alarm Operations

    /// Create a display alarm
    public func createDisplayAlarm(
        description: String,
        triggerMinutesBefore: Int
    ) -> ICalAlarm {
        let trigger = "-PT\(triggerMinutesBefore)M"
        var alarm = ICalAlarm(action: .display, trigger: trigger)
        alarm.description = description
        return alarm
    }

    /// Create an audio alarm
    public func createAudioAlarm(
        triggerMinutesBefore: Int,
        audioFile: String? = nil
    ) -> ICalAlarm {
        let trigger = "-PT\(triggerMinutesBefore)M"
        var alarm = ICalAlarm(action: .audio, trigger: trigger)
        if let audioFile = audioFile {
            alarm.attach = audioFile
        }
        return alarm
    }

    /// Create an email alarm
    public func createEmailAlarm(
        summary: String,
        description: String,
        attendees: [ICalAttendee],
        triggerMinutesBefore: Int
    ) -> ICalAlarm {
        let trigger = "-PT\(triggerMinutesBefore)M"
        var alarm = ICalAlarm(action: .email, trigger: trigger)
        alarm.summary = summary
        alarm.description = description
        alarm.attendees = attendees
        return alarm
    }

    // MARK: - Attendee Operations

    /// Create an attendee
    public func createAttendee(
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
    public func createOrganizer(
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

    // MARK: - Recurrence Rule Operations

    /// Create a daily recurrence rule
    public func createDailyRecurrence(
        interval: Int = 1,
        count: Int? = nil,
        until: Date? = nil
    ) -> ICalRecurrenceRule {
        ICalRecurrenceRule(
            frequency: .daily,
            interval: interval,
            count: count,
            until: until.map { ICalDateTime(date: $0) }
        )
    }

    /// Create a weekly recurrence rule
    public func createWeeklyRecurrence(
        interval: Int = 1,
        daysOfWeek: [ICalWeekday] = [],
        count: Int? = nil,
        until: Date? = nil
    ) -> ICalRecurrenceRule {
        let byDay = daysOfWeek.isEmpty ? nil : daysOfWeek.map { $0.rawValue }
        return ICalRecurrenceRule(
            frequency: .weekly,
            interval: interval,
            count: count,
            until: until.map { ICalDateTime(date: $0) },
            byDay: byDay
        )
    }

    /// Create a monthly recurrence rule
    public func createMonthlyRecurrence(
        interval: Int = 1,
        dayOfMonth: Int? = nil,
        weekdayOrdinal: Int? = nil,
        weekday: ICalWeekday? = nil,
        count: Int? = nil,
        until: Date? = nil
    ) -> ICalRecurrenceRule {
        var byMonthDay: [Int]? = nil
        var byDay: [String]? = nil

        if let dayOfMonth = dayOfMonth {
            byMonthDay = [dayOfMonth]
        } else if let ordinal = weekdayOrdinal, let wd = weekday {
            byDay = ["\(ordinal)\(wd.rawValue)"]
        }

        return ICalRecurrenceRule(
            frequency: .monthly,
            interval: interval,
            count: count,
            until: until.map { ICalDateTime(date: $0) },
            byDay: byDay,
            byMonthDay: byMonthDay
        )
    }

    /// Create a yearly recurrence rule
    public func createYearlyRecurrence(
        interval: Int = 1,
        month: Int? = nil,
        dayOfMonth: Int? = nil,
        count: Int? = nil,
        until: Date? = nil
    ) -> ICalRecurrenceRule {
        ICalRecurrenceRule(
            frequency: .yearly,
            interval: interval,
            count: count,
            until: until.map { ICalDateTime(date: $0) },
            byMonthDay: dayOfMonth.map { [$0] },
            byMonth: month.map { [$0] }
        )
    }

    // MARK: - Utility Operations

    /// Validate a calendar
    public func validateCalendar(_ calendar: ICalendar) async throws {
        let parser = ICalendarParser()
        try await parser.validate(calendar)
    }

    /// Get calendar statistics
    public func getCalendarStatistics(_ calendar: ICalendar) async -> CalendarStatistics {
        let serializer = ICalendarSerializer()
        let serializationStats = await serializer.getStatistics(calendar)

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

    /// Find events by date range
    public func findEvents(
        in calendar: ICalendar,
        from startDate: Date,
        to endDate: Date
    ) async -> [ICalEvent] {
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
    public func findTodos(
        in calendar: ICalendar,
        status: ICalTodoStatus
    ) -> [ICalTodo] {
        calendar.todos.filter { $0.status == status }
    }

    /// Find overdue todos
    public func findOverdueTodos(in calendar: ICalendar, asOf date: Date = Date()) -> [ICalTodo] {
        calendar.todos.filter { todo in
            guard let due = todo.dueDate?.date else { return false }
            return due < date && todo.status != .completed && todo.status != .cancelled
        }
    }

    // MARK: - Event Management

    /// Update an existing event in a calendar
    public func updateEvent(
        in calendar: inout ICalendar,
        eventUID: String,
        updateBlock: (inout ICalEvent) -> Void
    ) -> Bool {
        guard let eventIndex = calendar.events.firstIndex(where: { $0.uid == eventUID }) else {
            return false
        }

        var event = calendar.events[eventIndex]
        updateBlock(&event)

        // Update the sequence number to indicate this is a modified event
        let currentSequence = event.sequence ?? 0
        event.sequence = currentSequence + 1

        // Update last modified timestamp
        event.lastModified = ICalDateTime(date: Date.now)

        // Update the event in the calendar
        calendar.components[
            calendar.components.firstIndex { component in
                if let calEvent = component as? ICalEvent {
                    return calEvent.uid == eventUID
                }
                return false
            }!
        ] = event

        return true
    }

    /// Update an existing event and return the updated calendar
    public func updateEvent(
        in calendar: ICalendar,
        eventUID: String,
        updateBlock: (inout ICalEvent) -> Void
    ) -> ICalendar? {
        var mutableCalendar = calendar
        let success = updateEvent(
            in: &mutableCalendar,
            eventUID: eventUID,
            updateBlock: updateBlock
        )
        return success ? mutableCalendar : nil
    }

    /// Delete an event from a calendar
    public func deleteEvent(from calendar: inout ICalendar, eventUID: String) -> Bool {
        let originalCount = calendar.components.count
        calendar.components.removeAll { component in
            if let event = component as? ICalEvent {
                return event.uid == eventUID
            }
            return false
        }
        return calendar.components.count < originalCount
    }

    /// Delete an event and return the updated calendar
    public func deleteEvent(from calendar: ICalendar, eventUID: String) -> ICalendar? {
        var mutableCalendar = calendar
        let success = deleteEvent(from: &mutableCalendar, eventUID: eventUID)
        return success ? mutableCalendar : nil
    }

    /// Find an event by UID
    public func findEvent(in calendar: ICalendar, withUID uid: String) -> ICalEvent? {
        calendar.events.first { $0.uid == uid }
    }

    /// Find events by summary (title)
    public func findEvents(
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

    // MARK: - Alarm Management

    /// Check if an event has any alarms
    public func hasAlarms(_ event: ICalEvent) -> Bool {
        !event.alarms.isEmpty
    }

    /// Check if an event has alarms of a specific type
    public func hasAlarms(_ event: ICalEvent, ofType type: ICalAlarmAction) -> Bool {
        event.alarms.contains { $0.action == type }
    }

    /// Get all alarms for an event
    public func getAlarms(for event: ICalEvent) -> [ICalAlarm] {
        event.alarms
    }

    /// Get alarms of a specific type for an event
    public func getAlarms(for event: ICalEvent, ofType type: ICalAlarmAction) -> [ICalAlarm] {
        event.alarms.filter { $0.action == type }
    }

    /// Add an alarm to an existing event
    public func addAlarm(to event: inout ICalEvent, alarm: ICalAlarm) {
        event.components.append(alarm)
    }

    /// Remove all alarms from an event
    public func removeAllAlarms(from event: inout ICalEvent) {
        event.components.removeAll { $0 is ICalAlarm }
    }

    /// Remove alarms of a specific type from an event
    public func removeAlarms(from event: inout ICalEvent, ofType type: ICalAlarmAction) {
        event.components.removeAll { component in
            if let alarm = component as? ICalAlarm {
                return alarm.action == type
            }
            return false
        }
    }

    /// Find events that have alarms in a calendar
    public func findEventsWithAlarms(in calendar: ICalendar) -> [ICalEvent] {
        calendar.events.filter { hasAlarms($0) }
    }

    /// Find events with alarms of a specific type
    public func findEventsWithAlarms(
        in calendar: ICalendar,
        ofType type: ICalAlarmAction
    )
        -> [ICalEvent]
    {
        calendar.events.filter { hasAlarms($0, ofType: type) }
    }

    /// Check if any events in a calendar have alarms that will trigger within a time period
    public func findEventsWithUpcomingAlarms(
        in calendar: ICalendar,
        within timeInterval: TimeInterval,
        from referenceDate: Date = Date()
    ) -> [(event: ICalEvent, alarm: ICalAlarm, triggerDate: Date)] {
        var upcomingAlarms: [(event: ICalEvent, alarm: ICalAlarm, triggerDate: Date)] = []

        for event in calendar.events {
            guard let eventStart = event.dateTimeStart?.date else { continue }

            for alarm in event.alarms {
                if let triggerDate = calculateAlarmTriggerDate(alarm: alarm, eventStart: eventStart) {
                    let timeDifference = triggerDate.timeIntervalSince(referenceDate)
                    if timeDifference >= 0 && timeDifference <= timeInterval {
                        upcomingAlarms.append(
                            (event: event, alarm: alarm, triggerDate: triggerDate)
                        )
                    }
                }
            }
        }

        return upcomingAlarms.sorted { $0.triggerDate < $1.triggerDate }
    }

    /// Calculate when an alarm will trigger based on the event start time
    private func calculateAlarmTriggerDate(alarm: ICalAlarm, eventStart: Date) -> Date? {
        guard let trigger = alarm.trigger else { return nil }

        // Handle duration-based triggers (e.g., "-PT15M" for 15 minutes before)
        if trigger.hasPrefix("-P") || trigger.hasPrefix("P") {
            if let duration = ICalendarFormatter.parseDuration(trigger) {
                let offset = duration.totalSeconds
                return eventStart.addingTimeInterval(offset)
            }
        }

        // Handle absolute date-time triggers
        if let absoluteDate = ICalendarFormatter.parseDateTime(trigger) {
            return absoluteDate.date
        }

        return nil
    }

    // MARK: - Event Modification Helpers

    /// Reschedule an event to a new date/time
    public func rescheduleEvent(
        in calendar: inout ICalendar,
        eventUID: String,
        newStartDate: Date,
        newEndDate: Date? = nil,
        keepDuration: Bool = true
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            let originalDuration: TimeInterval?

            if keepDuration, let start = event.dateTimeStart?.date,
                let end = event.dateTimeEnd?.date
            {
                originalDuration = end.timeIntervalSince(start)
            } else {
                originalDuration = nil
            }

            event.dateTimeStart = ICalDateTime(date: newStartDate)

            if let newEndDate = newEndDate {
                event.dateTimeEnd = ICalDateTime(date: newEndDate)
            } else if let duration = originalDuration {
                event.dateTimeEnd = ICalDateTime(date: newStartDate.addingTimeInterval(duration))
            }
        }
    }

    /// Change the location of an event
    public func changeEventLocation(
        in calendar: inout ICalendar,
        eventUID: String,
        newLocation: String
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            event.location = newLocation
        }
    }

    /// Update event description
    public func updateEventDescription(
        in calendar: inout ICalendar,
        eventUID: String,
        newDescription: String
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            event.description = newDescription
        }
    }

    /// Update event summary (title)
    public func updateEventSummary(
        in calendar: inout ICalendar,
        eventUID: String,
        newSummary: String
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            event.summary = newSummary
        }
    }

    /// Change event status
    public func changeEventStatus(
        in calendar: inout ICalendar,
        eventUID: String,
        newStatus: ICalEventStatus
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            event.status = newStatus
        }
    }

    /// Add or update attendees for an event
    public func updateEventAttendees(
        in calendar: inout ICalendar,
        eventUID: String,
        attendees: [ICalAttendee]
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            event.attendees = attendees
        }
    }

    /// Add a single attendee to an event
    public func addAttendee(
        to calendar: inout ICalendar,
        eventUID: String,
        attendee: ICalAttendee
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            var currentAttendees = event.attendees
            currentAttendees.append(attendee)
            event.attendees = currentAttendees
        }
    }

    /// Remove an attendee from an event
    public func removeAttendee(
        from calendar: inout ICalendar,
        eventUID: String,
        attendeeEmail: String
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            event.attendees = event.attendees.filter { $0.email != attendeeEmail }
        }
    }
}

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

// MARK: - Convenience Extensions

extension ICalendarClient {

    /// Quick parse from string
    public static func parse(_ content: String) async throws -> ICalendar {
        let client = ICalendarClient()
        return try await client.parseCalendar(from: content)
    }

    /// Quick serialize to string
    public static func serialize(_ calendar: ICalendar) async throws -> String {
        let client = ICalendarClient()
        return try await client.serializeCalendar(calendar)
    }

    /// Create a simple meeting invitation
    /// Create meeting invitation with attendees
    public func createMeetingInvitation(
        summary: String,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        description: String? = nil,
        organizer: ICalAttendee,
        attendees: [ICalAttendee],
        reminderMinutes: Int? = nil
    ) -> ICalendar {
        var calendar = createCalendar()
        calendar.method = "REQUEST"

        var event = createEvent(
            summary: summary,
            startDate: startDate,
            endDate: endDate,
            location: location,
            description: description
        )

        event.organizer = organizer
        event.attendees = attendees
        event.status = .confirmed

        // Add reminder alarm if specified
        if let reminderMinutes = reminderMinutes {
            let alarm = createDisplayAlarm(
                description: "Reminder: \(summary)",
                triggerMinutesBefore: reminderMinutes
            )
            event.addAlarm(alarm)
        }

        calendar.addEvent(event)
        return calendar
    }

    /// Create a task list calendar
    public func createTaskList(
        title: String,
        tasks: [(summary: String, dueDate: Date?, priority: Int?)]
    ) -> ICalendar {
        var calendar = createCalendar()

        for task in tasks {
            let todo = createTodo(
                summary: task.summary,
                dueDate: task.dueDate,
                priority: task.priority
            )
            calendar.addTodo(todo)
        }

        return calendar
    }
}

// MARK: - ICalEvent Extensions for Alarm Management

extension ICalEvent {
    /// Check if this event has any alarms
    public var hasAlarms: Bool {
        !alarms.isEmpty
    }

    /// Check if this event has alarms of a specific type
    public func hasAlarms(ofType type: ICalAlarmAction) -> Bool {
        alarms.contains { $0.action == type }
    }

    /// Get alarms of a specific type
    public func getAlarms(ofType type: ICalAlarmAction) -> [ICalAlarm] {
        alarms.filter { $0.action == type }
    }

    /// Add a reminder alarm (display alarm) with specified minutes before event
    public mutating func addReminder(minutesBefore: Int, description: String? = nil) {
        let trigger = "-PT\(minutesBefore)M"
        let alarmDescription = description ?? "Reminder: \(self.summary ?? "Event")"
        let alarm = ICalAlarm(action: .display, trigger: trigger)
        var mutableAlarm = alarm
        mutableAlarm.description = alarmDescription
        addAlarm(mutableAlarm)
    }

    /// Remove all alarms from this event
    public mutating func removeAllAlarms() {
        components.removeAll { $0 is ICalAlarm }
    }

    /// Remove alarms of a specific type
    public mutating func removeAlarms(ofType type: ICalAlarmAction) {
        components.removeAll { component in
            if let alarm = component as? ICalAlarm {
                return alarm.action == type
            }
            return false
        }
    }

    /// Check if this is an all-day event
    public var isAllDay: Bool {
        dateTimeStart?.isDateOnly == true
    }

    /// Check if this is a recurring event
    public var isRecurring: Bool {
        recurrenceRule != nil
    }

    /// Get the duration of this event
    public var eventDuration: TimeInterval? {
        if let duration = duration {
            return duration.totalSeconds
        } else if let start = dateTimeStart?.date, let end = dateTimeEnd?.date {
            return end.timeIntervalSince(start)
        }
        return nil
    }

    /// Check if this event is currently happening
    public func isHappeningNow(at date: Date = Date()) -> Bool {
        guard let start = dateTimeStart?.date else { return false }

        if let end = dateTimeEnd?.date {
            return date >= start && date <= end
        } else if let duration = eventDuration {
            let end = start.addingTimeInterval(duration)
            return date >= start && date <= end
        } else {
            // For events without end time or duration, check if it's the same day
            return Calendar.current.isDate(date, inSameDayAs: start)
        }
    }

    /// Check if this event occurs on a specific date
    public func occursOn(date: Date) -> Bool {
        guard let start = dateTimeStart?.date else { return false }

        if isAllDay {
            return Calendar.current.isDate(start, inSameDayAs: date)
        } else {
            if let end = dateTimeEnd?.date {
                return date >= Calendar.current.startOfDay(for: start)
                    && date <= Calendar.current.startOfDay(for: end).addingTimeInterval(86400)
            } else {
                return Calendar.current.isDate(start, inSameDayAs: date)
            }
        }
    }
}

// MARK: - ICalendar Extensions for Event Management

extension ICalendar {
    /// Get events happening on a specific date
    public func events(on date: Date) -> [ICalEvent] {
        events.filter { $0.occursOn(date: date) }
    }

    /// Get events happening today
    public var todaysEvents: [ICalEvent] {
        events(on: Date())
    }

    /// Get all-day events
    public var allDayEvents: [ICalEvent] {
        events.filter { $0.isAllDay }
    }

    /// Get recurring events
    public var recurringEvents: [ICalEvent] {
        events.filter { $0.isRecurring }
    }

    /// Get events with alarms
    public var eventsWithAlarms: [ICalEvent] {
        events.filter { $0.hasAlarms }
    }

    /// Get events by status
    public func events(withStatus status: ICalEventStatus) -> [ICalEvent] {
        events.filter { $0.status == status }
    }

    /// Get confirmed events
    public var confirmedEvents: [ICalEvent] {
        events(withStatus: .confirmed)
    }

    /// Get tentative events
    public var tentativeEvents: [ICalEvent] {
        events(withStatus: .tentative)
    }

    /// Get cancelled events
    public var cancelledEvents: [ICalEvent] {
        events(withStatus: .cancelled)
    }

    /// Find events by organizer email
    public func events(organizedBy email: String) -> [ICalEvent] {
        events.filter { $0.organizer?.email.lowercased() == email.lowercased() }
    }

    /// Find events where a specific attendee is invited
    public func events(withAttendee email: String) -> [ICalEvent] {
        events.filter { event in
            event.attendees.contains { $0.email.lowercased() == email.lowercased() }
        }
    }

    /// Get events in a specific location
    public func events(at location: String, caseSensitive: Bool = false) -> [ICalEvent] {
        events.filter { event in
            guard let eventLocation = event.location else { return false }
            if caseSensitive {
                return eventLocation.contains(location)
            } else {
                return eventLocation.lowercased().contains(location.lowercased())
            }
        }
    }

    /// Get events with a specific priority
    public func events(withPriority priority: Int) -> [ICalEvent] {
        events.filter { $0.priority == priority }
    }

    /// Get high priority events (priority 1-3)
    public var highPriorityEvents: [ICalEvent] {
        events.filter {
            if let priority = $0.priority {
                return priority >= 1 && priority <= 3
            }
            return false
        }
    }

    /// Update an event by UID using a closure
    public mutating func updateEvent(
        withUID uid: String,
        updateBlock: (inout ICalEvent) -> Void
    )
        -> Bool
    {
        guard
            let index = components.firstIndex(where: { component in
                if let event = component as? ICalEvent {
                    return event.uid == uid
                }
                return false
            })
        else {
            return false
        }

        if var event = components[index] as? ICalEvent {
            updateBlock(&event)

            // Update sequence number and last modified
            let currentSequence = event.sequence ?? 0
            event.sequence = currentSequence + 1
            event.lastModified = ICalDateTime(date: Date())

            components[index] = event
            return true
        }

        return false
    }

    /// Remove an event by UID
    public mutating func removeEvent(withUID uid: String) -> Bool {
        let originalCount = components.count
        components.removeAll { component in
            if let event = component as? ICalEvent {
                return event.uid == uid
            }
            return false
        }
        return components.count < originalCount
    }

    /// Add multiple events at once
    public mutating func addEvents(_ events: [ICalEvent]) {
        for event in events {
            addEvent(event)
        }
    }

    /// Get calendar statistics including alarm information
    public var extendedStatistics: (events: Int, withAlarms: Int, recurring: Int, allDay: Int, confirmed: Int) {
        (
            events: events.count,
            withAlarms: eventsWithAlarms.count,
            recurring: recurringEvents.count,
            allDay: allDayEvents.count,
            confirmed: confirmedEvents.count
        )
    }
}
