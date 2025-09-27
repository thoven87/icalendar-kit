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
        public let strictRFCCompliance: Bool
        public let defaultTimeZone: TimeZone

        public init(
            defaultProductId: String = "-//ICalendar Kit//EN",
            defaultVersion: String = "2.0",
            validateOnParse: Bool = true,
            validateOnSerialize: Bool = true,
            enableExtensions: Bool = true,
            strictRFCCompliance: Bool = false,
            defaultTimeZone: TimeZone = .gmt
        ) {
            self.defaultProductId = defaultProductId
            self.defaultVersion = defaultVersion
            self.validateOnParse = validateOnParse
            self.validateOnSerialize = validateOnSerialize
            self.enableExtensions = enableExtensions
            self.strictRFCCompliance = strictRFCCompliance
            self.defaultTimeZone = defaultTimeZone
        }

        public static let `default` = Configuration()

        public static let strict = Configuration(
            validateOnParse: true,
            validateOnSerialize: true,
            enableExtensions: false,
            strictRFCCompliance: true
        )

        public static let permissive = Configuration(
            validateOnParse: false,
            validateOnSerialize: false,
            enableExtensions: true,
            strictRFCCompliance: false
        )
    }

    public let configuration: Configuration

    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    // MARK: - Parsing Operations

    /// Parse iCalendar content from string
    public func parseCalendar(from content: String) throws -> ICalendar {
        let parser = ICalendarParser()

        if configuration.validateOnParse {
            return try parser.parseAndValidate(content)
        } else {
            return try parser.parse(content)
        }
    }

    /// Parse iCalendar content from data
    public func parseCalendar(from data: Data) throws -> ICalendar {
        let parser = ICalendarParser()

        if configuration.validateOnParse {
            let calendar = try parser.parse(data)
            try parser.validate(calendar)
            return calendar
        } else {
            return try parser.parse(data)
        }
    }

    /// Parse iCalendar file from URL
    public func parseCalendar(from url: URL) throws -> ICalendar {
        let parser = ICalendarParser()

        if configuration.validateOnParse {
            let calendar = try parser.parseFile(at: url)
            try parser.validate(calendar)
            return calendar
        } else {
            return try parser.parseFile(at: url)
        }
    }

    /// Parse multiple calendars from content
    public func parseCalendars(from content: String) throws -> [ICalendar] {
        let parser = ICalendarParser()
        let calendars = try parser.parseMultiple(content)

        if configuration.validateOnParse {
            for calendar in calendars {
                try parser.validate(calendar)
            }
        }

        return calendars
    }

    // MARK: - Serialization Operations

    /// Serialize calendar to string
    public func serializeCalendar(_ calendar: ICalendar) throws -> String {
        let serializer = ICalendarSerializer(
            options: ICalendarSerializer.SerializationOptions(
                validateBeforeSerializing: configuration.validateOnSerialize
            )
        )
        return try serializer.serialize(calendar)
    }

    /// Serialize calendar to data
    public func serializeCalendar(_ calendar: ICalendar) throws -> Data {
        let serializer = ICalendarSerializer(
            options: ICalendarSerializer.SerializationOptions(
                validateBeforeSerializing: configuration.validateOnSerialize
            )
        )
        return try serializer.serializeToData(calendar)
    }

    /// Serialize calendar to file
    public func serializeCalendar(_ calendar: ICalendar, to url: URL) throws {
        let serializer = ICalendarSerializer(
            options: ICalendarSerializer.SerializationOptions(
                validateBeforeSerializing: configuration.validateOnSerialize
            )
        )
        try serializer.serializeToFile(calendar, url: url)
    }

    /// Serialize multiple calendars
    public func serializeCalendars(_ calendars: [ICalendar]) throws -> String {
        let serializer = ICalendarSerializer(
            options: ICalendarSerializer.SerializationOptions(
                validateBeforeSerializing: configuration.validateOnSerialize
            )
        )
        return try serializer.serialize(calendars)
    }

    // MARK: - Calendar Creation

    /// Create a new empty calendar with default context
    public func createCalendar(productId: String? = nil, context: ICalendarContext = .default) -> ICalendar {
        var calendar = ICalendar(
            productId: productId ?? configuration.defaultProductId,
            version: configuration.defaultVersion
        )

        // Apply context settings
        calendar.calendarScale = context.calendarScale.rawValue
        if context.defaultTimeZone.identifier != "GMT" {
            calendar.xwrTimeZone = context.defaultTimeZone.identifier
        }

        return calendar
    }

    /// Create calendar with events
    public func createCalendar(events: [ICalEvent], productId: String? = nil, context: ICalendarContext = .default) -> ICalendar {
        var calendar = createCalendar(productId: productId, context: context)
        for event in events {
            calendar.addEvent(event)
        }
        return calendar
    }

    /// Create calendar with todos
    public func createCalendar(todos: [ICalTodo], productId: String? = nil, context: ICalendarContext = .default) -> ICalendar {
        var calendar = createCalendar(productId: productId, context: context)
        for todo in todos {
            calendar.addTodo(todo)
        }
        return calendar
    }

    /// Create calendar with metadata and RFC 7986 properties
    public func createCalendar(
        name: String? = nil,
        description: String? = nil,
        color: String? = nil,
        displayName: String? = nil,
        timeZone: TimeZone? = nil,
        refreshInterval: ICalDuration? = nil,
        source: String? = nil,
        productId: String? = nil,
        context: ICalendarContext = .default
    ) -> ICalendar {
        // timeZone parameter is used directly below when provided
        var calendar = createCalendar(productId: productId, context: context)

        if let name = name {
            calendar.name = name
        }
        if let description = description {
            calendar.calendarDescription = description
        }
        if let color = color {
            calendar.color = color
        }
        if let displayName = displayName {
            calendar.displayName = displayName
        }
        // Always set X-WR-TIMEZONE when explicitly provided
        if let providedTimeZone = timeZone {
            // Convert GMT to UTC for better user experience
            calendar.xwrTimeZone = providedTimeZone.identifier == "GMT" ? "UTC" : providedTimeZone.identifier
        }
        if let refreshInterval = refreshInterval {
            calendar.refreshInterval = refreshInterval
        }
        if let source = source {
            calendar.source = source
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
    public func createAllDayEvent(
        summary: String,
        date: Date,
        location: String? = nil,
        description: String? = nil,
        uid: String? = nil,
        timeZone: TimeZone = .gmt
    ) -> ICalEvent {
        var event = ICalEvent(uid: uid ?? UUID().uuidString, summary: summary)

        event.dateTimeStamp = ICalDateTime(date: Date(), timeZone: timeZone)
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
    public func createRecurringEvent(
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

    // MARK: - Todo Operations

    /// Create a simple todo
    public func createTodo(
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
    public func createTodo(
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
        until: Date? = nil,
        timeZone: TimeZone = .gmt
    ) -> ICalRecurrenceRule {
        let byDay = daysOfWeek.isEmpty ? nil : daysOfWeek.map { $0.rawValue }
        return ICalRecurrenceRule(
            frequency: .weekly,
            interval: interval,
            count: count,
            until: until.map { ICalDateTime(date: $0, timeZone: timeZone) },
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
        until: Date? = nil,
        timeZone: TimeZone = .gmt
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
            until: until.map { ICalDateTime(date: $0, timeZone: timeZone) },
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
        until: Date? = nil,
        timeZone: TimeZone = .gmt
    ) -> ICalRecurrenceRule {
        ICalRecurrenceRule(
            frequency: .yearly,
            interval: interval,
            count: count,
            until: until.map { ICalDateTime(date: $0, timeZone: timeZone) },
            byMonthDay: dayOfMonth.map { [$0] },
            byMonth: month.map { [$0] }
        )
    }

    /// Create a generic recurrence rule with optional RSCALE support
    public func createRecurrence(
        frequency: ICalRecurrenceFrequency,
        interval: Int = 1,
        rscale: ICalRecurrenceScale? = nil,
        count: Int? = nil,
        until: Date? = nil,
        timeZone: TimeZone = .gmt
    ) -> ICalRecurrenceRule {
        ICalRecurrenceRule(
            frequency: frequency,
            interval: interval,
            count: count,
            until: until.map { ICalDateTime(date: $0, timeZone: timeZone) },
            rscale: rscale
        )
    }

    // MARK: - DateTime Operations

    /// Parse a datetime string with timezone support
    public func parseDateTime(_ value: String, timeZone: TimeZone = .gmt) -> ICalDateTime? {
        ICalendarFormatter.parseDateTime(value, timeZone: timeZone)
    }

    /// Format a datetime object to iCalendar string format
    public func formatDateTime(_ dateTime: ICalDateTime) -> String {
        ICalendarFormatter.format(dateTime: dateTime)
    }

    // MARK: - Utility Operations

    /// Validate a calendar
    public func validateCalendar(_ calendar: ICalendar) throws {
        let parser = ICalendarParser()
        try parser.validate(calendar)
    }

    /// Get calendar statistics
    public func getCalendarStatistics(_ calendar: ICalendar) -> CalendarStatistics {
        let serializer = ICalendarSerializer()
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

    /// Find events by date range
    public func findEvents(
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
        updateBlock: (inout ICalEvent) -> Void,
        timeZone: TimeZone = .gmt
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
        event.lastModified = ICalDateTime(date: Date.now, timeZone: timeZone)

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
        from referenceDate: Date = Date(),
        timeZone: TimeZone = .gmt
    ) -> [(event: ICalEvent, alarm: ICalAlarm, triggerDate: Date)] {
        var upcomingAlarms: [(event: ICalEvent, alarm: ICalAlarm, triggerDate: Date)] = []

        for event in calendar.events {
            guard let eventStart = event.dateTimeStart?.date else { continue }

            for alarm in event.alarms {
                if let triggerDate = calculateAlarmTriggerDate(alarm: alarm, eventStart: eventStart, timeZone: timeZone) {
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
    private func calculateAlarmTriggerDate(alarm: ICalAlarm, eventStart: Date, timeZone: TimeZone = .gmt) -> Date? {
        guard let trigger = alarm.trigger else { return nil }

        // Handle duration-based triggers (e.g., "-PT15M" for 15 minutes before)
        if trigger.hasPrefix("-P") || trigger.hasPrefix("P") {
            if let duration = ICalendarFormatter.parseDuration(trigger) {
                let offset = duration.totalSeconds
                return eventStart.addingTimeInterval(offset)
            }
        }

        // Handle absolute date-time triggers
        if let absoluteDate = ICalendarFormatter.parseDateTime(trigger, timeZone: timeZone) {
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
        keepDuration: Bool = true,
        timeZone: TimeZone = .gmt
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

            event.dateTimeStart = ICalDateTime(date: newStartDate, timeZone: timeZone)

            if let newEndDate = newEndDate {
                event.dateTimeEnd = ICalDateTime(date: newEndDate, timeZone: timeZone)
            } else if let duration = originalDuration {
                event.dateTimeEnd = ICalDateTime(date: newStartDate.addingTimeInterval(duration), timeZone: timeZone)
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

    // MARK: - RFC 7986 Extension Property Operations

    /// Update event color
    public func updateEventColor(
        in calendar: inout ICalendar,
        eventUID: String,
        newColor: String?
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            event.color = newColor
        }
    }

    /// Add image to event
    public func addEventImage(
        in calendar: inout ICalendar,
        eventUID: String,
        imageURI: String
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            var currentImages = event.images
            currentImages.append(imageURI)
            event.images = currentImages
        }
    }

    /// Update event geographic coordinates
    public func updateEventLocation(
        in calendar: inout ICalendar,
        eventUID: String,
        latitude: Double,
        longitude: Double,
        location: String? = nil
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            event.geo = ICalGeoCoordinate(latitude: latitude, longitude: longitude)
            if let location = location {
                event.location = location
            }
        }
    }

    /// Add conference information to event
    public func addEventConference(
        in calendar: inout ICalendar,
        eventUID: String,
        conferenceURI: String
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            var currentConferences = event.conferences
            currentConferences.append(conferenceURI)
            event.conferences = currentConferences
        }
    }

    /// Create geographic coordinates
    public func createGeoCoordinate(latitude: Double, longitude: Double) -> ICalGeoCoordinate {
        ICalGeoCoordinate(latitude: latitude, longitude: longitude)
    }

    /// Create refresh interval from components
    public func createRefreshInterval(
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

    // MARK: - IMAGE Property Utilities

    /// Create a binary image property from data
    public func createBinaryImage(_ data: Data, mediaType: String? = nil) -> ICalProperty {
        ICalendarFormatter.createBinaryImageProperty(data, mediaType: mediaType)
    }

    /// Create a URI image property from URL
    public func createURIImage(_ uri: String, mediaType: String? = nil) -> ICalProperty {
        ICalendarFormatter.createURIImageProperty(uri, mediaType: mediaType)
    }

    /// Add binary image to calendar
    public func addBinaryImageToCalendar(
        in calendar: inout ICalendar,
        imageData: Data,
        mediaType: String? = nil
    ) {
        let imageProperty = createBinaryImage(imageData, mediaType: mediaType)
        calendar.properties.append(imageProperty)
    }

    /// Add URI image to calendar
    public func addURIImageToCalendar(
        in calendar: inout ICalendar,
        imageURI: String,
        mediaType: String? = nil
    ) {
        let imageProperty = createURIImage(imageURI, mediaType: mediaType)
        calendar.properties.append(imageProperty)
    }

    /// Add binary image to event
    public func addBinaryImageToEvent(
        in calendar: inout ICalendar,
        eventUID: String,
        imageData: Data,
        mediaType: String? = nil
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            let imageProperty = createBinaryImage(imageData, mediaType: mediaType)
            event.properties.append(imageProperty)
        }
    }

    /// Add URI image to event
    public func addURIImageToEvent(
        in calendar: inout ICalendar,
        eventUID: String,
        imageURI: String,
        mediaType: String? = nil
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            let imageProperty = createURIImage(imageURI, mediaType: mediaType)
            event.properties.append(imageProperty)
        }
    }

    // MARK: - Timezone Utilities

    /// Generate TZURL for timezone identifier (RFC 7808)
    public func generateTZURL(for timezoneId: String) -> String {
        ICalTimeZoneURLGenerator.generateTZURL(for: timezoneId)
    }

    /// Generate TZURL for Foundation TimeZone (RFC 7808)
    public func generateTZURL(for timeZone: TimeZone) -> String {
        ICalTimeZoneURLGenerator.generateTZURL(for: timeZone.identifier)
    }

    /// Generate alternative TZURL for timezone identifier (RFC 7808)
    public func generateAlternativeTZURL(for timezoneId: String) -> String {
        ICalTimeZoneURLGenerator.generateAlternativeTZURL(for: timezoneId)
    }

    /// Generate alternative TZURL for Foundation TimeZone (RFC 7808)
    public func generateAlternativeTZURL(for timeZone: TimeZone) -> String {
        ICalTimeZoneURLGenerator.generateAlternativeTZURL(for: timeZone.identifier)
    }

    // MARK: - Attachment Management

    /// Create URI attachment
    public func createURIAttachment(_ uri: String, mediaType: String? = nil) -> ICalAttachment {
        ICalAttachment(uri: uri, mediaType: mediaType)
    }

    /// Create binary attachment from data
    public func createBinaryAttachment(_ data: Data, mediaType: String? = nil) -> ICalAttachment {
        ICalAttachment(binaryData: data, mediaType: mediaType)
    }

    /// Add attachment to event
    public func addAttachmentToEvent(
        in calendar: inout ICalendar,
        eventUID: String,
        attachment: ICalAttachment
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            var currentAttachments = event.attachments
            currentAttachments.append(attachment)
            event.attachments = currentAttachments
        }
    }

    /// Add URI attachment to event
    public func addURIAttachmentToEvent(
        in calendar: inout ICalendar,
        eventUID: String,
        uri: String,
        mediaType: String? = nil
    ) -> Bool {
        let attachment = createURIAttachment(uri, mediaType: mediaType)
        return addAttachmentToEvent(in: &calendar, eventUID: eventUID, attachment: attachment)
    }

    /// Add binary attachment to event
    public func addBinaryAttachmentToEvent(
        in calendar: inout ICalendar,
        eventUID: String,
        data: Data,
        mediaType: String? = nil
    ) -> Bool {
        let attachment = createBinaryAttachment(data, mediaType: mediaType)
        return addAttachmentToEvent(in: &calendar, eventUID: eventUID, attachment: attachment)
    }

    // MARK: - RFC 5546 Enhanced iTIP Workflow Methods

    /// Accept a meeting invitation (RFC 5546)
    ///
    /// Creates a REPLY message with PARTSTAT=ACCEPTED for the specified attendee.
    /// Automatically increments the SEQUENCE number and updates LAST-MODIFIED.
    ///
    /// - Parameters:
    ///   - calendar: The calendar containing the invitation
    ///   - eventUID: The UID of the event to accept
    ///   - attendeeEmail: Email of the attendee accepting the invitation
    /// - Returns: A new calendar with a REPLY method and updated participation status
    public func acceptInvitation(
        _ calendar: ICalendar,
        eventUID: String,
        attendeeEmail: String
    ) -> ICalendar? {
        updateAttendeeResponse(calendar, eventUID: eventUID, attendeeEmail: attendeeEmail, response: .accepted)
    }

    /// Decline a meeting invitation (RFC 5546)
    ///
    /// Creates a REPLY message with PARTSTAT=DECLINED for the specified attendee.
    ///
    /// - Parameters:
    ///   - calendar: The calendar containing the invitation
    ///   - eventUID: The UID of the event to decline
    ///   - attendeeEmail: Email of the attendee declining the invitation
    /// - Returns: A new calendar with a REPLY method and updated participation status
    public func declineInvitation(
        _ calendar: ICalendar,
        eventUID: String,
        attendeeEmail: String
    ) -> ICalendar? {
        updateAttendeeResponse(calendar, eventUID: eventUID, attendeeEmail: attendeeEmail, response: .declined)
    }

    /// Propose a new meeting time (RFC 5546 COUNTER)
    ///
    /// Creates a COUNTER message with suggested alternative meeting times.
    ///
    /// - Parameters:
    ///   - calendar: The original calendar with the invitation
    ///   - eventUID: The UID of the event to counter-propose
    ///   - attendeeEmail: Email of the attendee making the counter-proposal
    ///   - newStartDate: Proposed new start date
    ///   - newEndDate: Proposed new end date (optional if duration should remain the same)
    ///   - comment: Optional comment explaining the counter-proposal
    /// - Returns: A new calendar with COUNTER method and proposed changes
    public func proposeNewTime(
        _ calendar: ICalendar,
        eventUID: String,
        attendeeEmail: String,
        newStartDate: Date,
        newEndDate: Date? = nil,
        comment: String? = nil
    ) -> ICalendar? {
        guard let event = findEvent(in: calendar, withUID: eventUID) else { return nil }

        var counterCalendar = createCalendar(productId: configuration.defaultProductId)
        counterCalendar.method = "COUNTER"

        var counterEvent = event
        counterEvent.dateTimeStart = ICalDateTime(date: newStartDate)

        if let newEnd = newEndDate {
            counterEvent.dateTimeEnd = ICalDateTime(date: newEnd)
        } else if let originalEnd = event.dateTimeEnd {
            // Keep same duration
            let duration = originalEnd.date.timeIntervalSince(event.dateTimeStart?.date ?? newStartDate)
            counterEvent.dateTimeEnd = ICalDateTime(date: newStartDate.addingTimeInterval(duration))
        }

        // Increment sequence
        let currentSequence = counterEvent.sequence ?? 0
        counterEvent.sequence = currentSequence + 1
        counterEvent.lastModified = ICalDateTime(date: Date())

        // Add comment if provided
        if let comment = comment {
            counterEvent.setPropertyValue("COMMENT", value: comment)
        }

        counterCalendar.addEvent(counterEvent)
        return counterCalendar
    }

    /// Accept a counter-proposal (RFC 5546 DECLINECOUNTER)
    ///
    /// Creates a DECLINECOUNTER message rejecting the proposed alternative.
    ///
    /// - Parameters:
    ///   - calendar: The calendar with the counter-proposal
    ///   - eventUID: The UID of the event
    ///   - organizerEmail: Email of the organizer declining the counter
    ///   - reason: Optional reason for declining the counter-proposal
    /// - Returns: A new calendar with DECLINECOUNTER method
    public func declineCounterProposal(
        _ calendar: ICalendar,
        eventUID: String,
        organizerEmail: String,
        reason: String? = nil
    ) -> ICalendar? {
        guard let event = findEvent(in: calendar, withUID: eventUID) else { return nil }

        var declineCalendar = createCalendar(productId: configuration.defaultProductId)
        declineCalendar.method = "DECLINECOUNTER"

        var declineEvent = event

        if let reason = reason {
            declineEvent.setPropertyValue("COMMENT", value: reason)
        }

        declineCalendar.addEvent(declineEvent)
        return declineCalendar
    }

    /// Request a fresh copy of the calendar object (RFC 5546 REFRESH)
    ///
    /// Creates a REFRESH message requesting an updated copy from the organizer.
    ///
    /// - Parameters:
    ///   - eventUID: The UID of the event to refresh
    ///   - attendeeEmail: Email of the attendee requesting refresh
    /// - Returns: A new calendar with REFRESH method
    public func requestRefresh(
        eventUID: String,
        attendeeEmail: String
    ) -> ICalendar {
        var refreshCalendar = createCalendar(productId: configuration.defaultProductId)
        refreshCalendar.method = "REFRESH"

        // Create minimal event with just UID and attendee info
        var refreshEvent = ICalEvent(uid: eventUID, summary: "")
        refreshEvent.attendees = [ICalAttendee(email: attendeeEmail)]
        refreshEvent.dateTimeStamp = ICalDateTime(date: Date())

        refreshCalendar.addEvent(refreshEvent)
        return refreshCalendar
    }

    /// Validate iTIP message structure (RFC 5546)
    ///
    /// Validates that an iTIP calendar follows proper structure rules.
    ///
    /// - Parameter calendar: The calendar to validate
    /// - Throws: `ICalendarError` if validation fails
    public func validateiTIPMessage(_ calendar: ICalendar) throws {
        guard let method = calendar.method else {
            throw ICalendarError.missingRequiredProperty("METHOD required for iTIP messages")
        }

        switch method.uppercased() {
        case "REQUEST":
            try validateRequestMessage(calendar)
        case "REPLY":
            try validateReplyMessage(calendar)
        case "COUNTER":
            try validateCounterMessage(calendar)
        case "DECLINECOUNTER":
            try validateDeclineCounterMessage(calendar)
        case "CANCEL":
            try validateCancelMessage(calendar)
        case "REFRESH":
            try validateRefreshMessage(calendar)
        case "PUBLISH":
            try validatePublishMessage(calendar)
        default:
            throw ICalendarError.invalidPropertyValue(property: "METHOD", value: method)
        }
    }

    private func updateAttendeeResponse(
        _ calendar: ICalendar,
        eventUID: String,
        attendeeEmail: String,
        response: ICalParticipationStatus
    ) -> ICalendar? {
        guard let event = findEvent(in: calendar, withUID: eventUID) else { return nil }

        var replyCalendar = createCalendar(productId: configuration.defaultProductId)
        replyCalendar.method = "REPLY"

        var replyEvent = event

        // Update attendee status
        var updatedAttendees: [ICalAttendee] = []
        for attendee in replyEvent.attendees {
            if attendee.email == attendeeEmail {
                let updatedAttendee = ICalAttendee(
                    email: attendee.email,
                    commonName: attendee.commonName,
                    role: attendee.role,
                    participationStatus: response,
                    userType: attendee.userType,
                    rsvp: attendee.rsvp,
                    delegatedFrom: attendee.delegatedFrom,
                    delegatedTo: attendee.delegatedTo,
                    sentBy: attendee.sentBy,
                    directory: attendee.directory,
                    member: attendee.member
                )
                updatedAttendees.append(updatedAttendee)
            } else {
                updatedAttendees.append(attendee)
            }
        }
        replyEvent.attendees = updatedAttendees

        // Update sequence and timestamp
        let currentSequence = replyEvent.sequence ?? 0
        replyEvent.sequence = currentSequence + 1
        replyEvent.lastModified = ICalDateTime(date: Date())

        replyCalendar.addEvent(replyEvent)
        return replyCalendar
    }

    private func validateRequestMessage(_ calendar: ICalendar) throws {
        for event in calendar.events {
            guard event.organizer != nil else {
                throw ICalendarError.missingRequiredProperty("ORGANIZER required in REQUEST")
            }
            guard !event.uid.isEmpty else {
                throw ICalendarError.missingRequiredProperty("UID required in REQUEST")
            }
            guard event.dateTimeStamp != nil else {
                throw ICalendarError.missingRequiredProperty("DTSTAMP required in REQUEST")
            }
        }
    }

    private func validateReplyMessage(_ calendar: ICalendar) throws {
        for event in calendar.events {
            guard !event.attendees.isEmpty else {
                throw ICalendarError.missingRequiredProperty("ATTENDEE required in REPLY")
            }
            guard !event.uid.isEmpty else {
                throw ICalendarError.missingRequiredProperty("UID required in REPLY")
            }
        }
    }

    private func validateCounterMessage(_ calendar: ICalendar) throws {
        for event in calendar.events {
            guard !event.attendees.isEmpty else {
                throw ICalendarError.missingRequiredProperty("ATTENDEE required in COUNTER")
            }
            guard event.dateTimeStart != nil else {
                throw ICalendarError.missingRequiredProperty("DTSTART required in COUNTER")
            }
        }
    }

    private func validateDeclineCounterMessage(_ calendar: ICalendar) throws {
        for event in calendar.events {
            guard event.organizer != nil else {
                throw ICalendarError.missingRequiredProperty("ORGANIZER required in DECLINECOUNTER")
            }
        }
    }

    private func validateCancelMessage(_ calendar: ICalendar) throws {
        for event in calendar.events {
            guard event.organizer != nil else {
                throw ICalendarError.missingRequiredProperty("ORGANIZER required in CANCEL")
            }
        }
    }

    private func validateRefreshMessage(_ calendar: ICalendar) throws {
        for event in calendar.events {
            guard !event.attendees.isEmpty else {
                throw ICalendarError.missingRequiredProperty("ATTENDEE required in REFRESH")
            }
        }
    }

    private func validatePublishMessage(_ calendar: ICalendar) throws {
        // PUBLISH messages should not have ATTENDEE properties in events
        for event in calendar.events {
            if !event.attendees.isEmpty {
                throw ICalendarError.invalidPropertyValue(
                    property: "ATTENDEE",
                    value: "ATTENDEE not allowed in PUBLISH method"
                )
            }
        }
    }

    // MARK: - RFC 6047 iMIP Email Transport Support

    /// Create email transport information for iMIP (RFC 6047)
    ///
    /// Creates email headers and MIME structure for transporting iTIP messages via email.
    ///
    /// - Parameters:
    ///   - calendar: The iTIP calendar to transport
    ///   - from: Sender email address
    ///   - to: Recipient email addresses
    ///   - subject: Email subject line (optional, will be generated if not provided)
    /// - Returns: Email transport information
    public func createEmailTransport(
        for calendar: ICalendar,
        from: String,
        to: [String],
        subject: String? = nil,
        domain: String = "icalendar-kit"
    ) -> ICalEmailTransport {
        let generatedSubject = subject ?? generateEmailSubject(for: calendar)

        return ICalEmailTransport(
            from: from,
            to: to,
            subject: generatedSubject,
            messageId: "<\(UUID().uuidString)@\(domain)>"
        )
    }

    private func generateEmailSubject(for calendar: ICalendar) -> String {
        guard let method = calendar.method?.uppercased(),
            let event = calendar.events.first
        else {
            return "Calendar Update"
        }

        let summary = event.summary ?? "Event"

        switch method {
        case "REQUEST":
            return "Invitation: \(summary)"
        case "REPLY":
            return "Response: \(summary)"
        case "CANCEL":
            return "Cancelled: \(summary)"
        case "COUNTER":
            return "Counter Proposal: \(summary)"
        case "DECLINECOUNTER":
            return "Declined Counter: \(summary)"
        case "REFRESH":
            return "Refresh Request: \(summary)"
        case "PUBLISH":
            return "Published: \(summary)"
        default:
            return "Calendar Update: \(summary)"
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

// MARK: - Configuration-Aware Date/Time Helpers

/// Create ICalDateTime with configuration-aware precision
public func createDateTime(
    from date: Date,
    timeZone: TimeZone? = nil,
    isDateOnly: Bool = false
) -> ICalDateTime {
    // Round to seconds for iCalendar compatibility (RFC 5545)
    let roundedDate = Date(timeIntervalSince1970: date.timeIntervalSince1970.rounded())
    return ICalDateTime(date: roundedDate, timeZone: timeZone, isDateOnly: isDateOnly)
}

// MARK: - RFC 7529 Non-Gregorian Recurrence Support

extension ICalendarClient {
    /// Create a recurrence rule with non-Gregorian calendar support (RFC 7529)
    ///
    /// - Parameters:
    ///   - frequency: The recurrence frequency
    ///   - interval: Interval between recurrences
    ///   - rscale: Calendar scale for non-Gregorian calendars
    ///   - count: Number of recurrences (optional)
    ///   - until: End date for recurrence (optional)
    /// - Returns: A recurrence rule with RSCALE support
    public func createNonGregorianRecurrence(
        frequency: ICalRecurrenceFrequency,
        interval: Int = 1,
        rscale: ICalRecurrenceScale,
        count: Int? = nil,
        until: Date? = nil
    ) -> ICalRecurrenceRule {
        ICalRecurrenceRule(
            frequency: frequency,
            interval: interval,
            count: count,
            until: until.map { createDateTime(from: $0, timeZone: rscale.foundationCalendar.timeZone) },
            rscale: rscale
        )
    }

    /// Create Hebrew calendar recurrence rule
    public func createHebrewRecurrence(
        frequency: ICalRecurrenceFrequency,
        interval: Int = 1,
        count: Int? = nil,
        until: Date? = nil
    ) -> ICalRecurrenceRule {
        createNonGregorianRecurrence(
            frequency: frequency,
            interval: interval,
            rscale: .hebrew,
            count: count,
            until: until
        )
    }

    /// Create Islamic calendar recurrence rule
    public func createIslamicRecurrence(
        frequency: ICalRecurrenceFrequency,
        interval: Int = 1,
        count: Int? = nil,
        until: Date? = nil
    ) -> ICalRecurrenceRule {
        createNonGregorianRecurrence(
            frequency: frequency,
            interval: interval,
            rscale: .islamic,
            count: count,
            until: until
        )
    }

    // MARK: - RFC 9074 Advanced Alarm Support

    /// Create proximity-based alarm (RFC 9074)
    ///
    /// Creates a location-based alarm that triggers when entering or leaving a specific area.
    ///
    /// - Parameters:
    ///   - latitude: Latitude coordinate
    ///   - longitude: Longitude coordinate
    ///   - radius: Radius in meters
    ///   - entering: True for entering trigger, false for leaving
    ///   - description: Optional alarm description
    /// - Returns: A proximity alarm
    public func createProximityAlarm(
        latitude: Double,
        longitude: Double,
        radius: Double,
        entering: Bool = true,
        description: String? = nil
    ) -> ICalAlarm {
        let trigger = ICalProximityTrigger(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            entering: entering
        )
        return ICalAlarm(proximityTrigger: trigger, description: description)
    }

    /// Acknowledge an alarm (RFC 9074)
    ///
    /// - Parameters:
    ///   - alarm: The alarm to acknowledge
    ///   - acknowledgedBy: Email of person acknowledging (optional)
    ///   - acknowledgedAt: Time of acknowledgment (defaults to now)
    /// - Returns: Updated alarm with acknowledgment information
    public func acknowledgeAlarm(
        _ alarm: ICalAlarm,
        acknowledgedBy: String? = nil,
        acknowledgedAt: Date = Date()
    ) -> ICalAlarm {
        var acknowledgedAlarm = alarm
        acknowledgedAlarm.acknowledgment = ICalAlarmAcknowledgment(
            acknowledgedAt: ICalDateTime(date: acknowledgedAt),
            acknowledgedBy: acknowledgedBy
        )
        return acknowledgedAlarm
    }

    // MARK: - RFC 9073 Event Publishing Extensions

    /// Create a venue component (RFC 9073)
    ///
    /// - Parameters:
    ///   - name: Venue name
    ///   - address: Street address
    ///   - latitude: Latitude coordinate (optional)
    ///   - longitude: Longitude coordinate (optional)
    ///   - capacity: Venue capacity (optional)
    ///   - url: Venue website (optional)
    /// - Returns: A venue component
    public func createVenue(
        name: String,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        capacity: Int? = nil,
        url: String? = nil
    ) -> ICalVenue {
        var venue = ICalVenue(name: name)
        venue.address = address
        venue.capacity = capacity
        venue.url = url

        if let lat = latitude, let lon = longitude {
            venue.geo = ICalGeoCoordinate(latitude: lat, longitude: lon)
        }

        return venue
    }

    /// Create enhanced location component (RFC 9073)
    ///
    /// - Parameters:
    ///   - name: Location name
    ///   - address: Street address (optional)
    ///   - geo: Geographic coordinates (optional)
    ///   - url: Location URL (optional)
    /// - Returns: An enhanced location component
    public func createEnhancedLocation(
        name: String,
        address: String? = nil,
        geo: ICalGeoCoordinate? = nil,
        url: String? = nil
    ) -> ICalLocation {
        var location = ICalLocation(name: name)
        location.address = address
        location.geo = geo
        location.url = url
        return location
    }

    /// Create resource component (RFC 9073)
    ///
    /// - Parameters:
    ///   - name: Resource name
    ///   - resourceType: Type of resource (Equipment, Room, Person, etc.)
    ///   - capacity: Resource capacity (optional)
    ///   - features: List of features (optional)
    ///   - contact: Contact information (optional)
    ///   - bookingUrl: URL for booking (optional)
    /// - Returns: A resource component
    public func createResource(
        name: String,
        resourceType: String,
        capacity: Int? = nil,
        features: [String]? = nil,
        contact: String? = nil,
        bookingUrl: String? = nil
    ) -> ICalResourceComponent {
        var resource = ICalResourceComponent(name: name, resourceType: resourceType)
        resource.capacity = capacity
        resource.features = features ?? []
        resource.contact = contact
        resource.bookingUrl = bookingUrl
        return resource
    }

    /// Add structured data to an event (RFC 9073)
    ///
    /// - Parameters:
    ///   - calendar: Calendar to modify
    ///   - eventUID: Event UID
    ///   - data: Structured data as JSON, XML, etc.
    ///   - type: Data type
    ///   - schema: Schema identifier (optional)
    /// - Returns: Success status
    public func addStructuredDataToEvent(
        in calendar: inout ICalendar,
        eventUID: String,
        data: String,
        type: ICalStructuredDataType,
        schema: String? = nil
    ) -> Bool {
        updateEvent(in: &calendar, eventUID: eventUID) { event in
            event.structuredData = ICalStructuredData(type: type, data: data, schema: schema)
        }
    }

    // MARK: - RFC 7953 Availability Support

    /// Create availability component (RFC 7953)
    ///
    /// - Parameters:
    ///   - start: Start time of availability period
    ///   - end: End time of availability period (optional)
    ///   - duration: Duration of availability (optional)
    ///   - summary: Summary description (optional)
    /// - Returns: An availability component
    public func createAvailability(
        start: Date,
        end: Date? = nil,
        duration: ICalDuration? = nil,
        summary: String? = nil
    ) -> ICalAvailabilityComponent {
        var availability = ICalAvailabilityComponent()
        availability.dateTimeStart = createDateTime(from: start, timeZone: configuration.defaultTimeZone)
        availability.dateTimeEnd = end.map { createDateTime(from: $0, timeZone: configuration.defaultTimeZone) }
        availability.duration = duration
        availability.summary = summary
        return availability
    }

    /// Create free time slot (RFC 7953)
    ///
    /// - Parameters:
    ///   - start: Start time
    ///   - end: End time
    ///   - summary: Summary (optional)
    ///   - location: Location (optional)
    /// - Returns: An available component
    public func createFreeTimeSlot(
        start: Date,
        end: Date,
        summary: String? = nil,
        location: String? = nil
    ) -> ICalAvailableComponent {
        var available = ICalAvailableComponent()
        available.dateTimeStart = createDateTime(from: start, timeZone: configuration.defaultTimeZone)
        available.dateTimeEnd = createDateTime(from: end, timeZone: configuration.defaultTimeZone)
        available.summary = summary
        available.location = location
        return available
    }

    /// Add free/busy information to calendar (RFC 7953)
    ///
    /// - Parameters:
    ///   - calendar: Calendar to modify
    ///   - busyPeriods: Array of busy time periods
    ///   - freePeriods: Array of free time periods
    public func addAvailabilityInfo(
        to calendar: inout ICalendar,
        busyPeriods: [(start: Date, end: Date)] = [],
        freePeriods: [(start: Date, end: Date)] = []
    ) {
        var availability = ICalAvailabilityComponent()

        // Add busy periods as BUSY components
        for period in busyPeriods {
            var busy = ICalBusyComponent()
            busy.dateTimeStart = createDateTime(from: period.start, timeZone: configuration.defaultTimeZone)
            busy.dateTimeEnd = createDateTime(from: period.end, timeZone: configuration.defaultTimeZone)
            busy.busyType = .busy
            availability.components.append(busy)
        }

        // Add free periods as AVAILABLE components
        for period in freePeriods {
            let free = createFreeTimeSlot(start: period.start, end: period.end)
            availability.components.append(free)
        }

        calendar.addAvailability(availability)
    }

    // MARK: - Date/Time Utilities

    /// Create ICalDateTime with proper precision handling
    /// iCalendar only supports second precision, so this ensures consistency
    public func createDateTime(
        from date: Date,
        timeZone: TimeZone? = nil,
        isDateOnly: Bool = false
    ) -> ICalDateTime {
        // Round to seconds for iCalendar compatibility
        let roundedDate = Date(timeIntervalSince1970: date.timeIntervalSince1970.rounded())
        let effectiveTimeZone = timeZone ?? configuration.defaultTimeZone
        return ICalDateTime(date: roundedDate, timeZone: effectiveTimeZone, isDateOnly: isDateOnly)
    }

    /// Compare two ICalDateTime values with proper precision
    public func areDateTimesEqual(_ dt1: ICalDateTime?, _ dt2: ICalDateTime?, tolerance: TimeInterval = 1.0) -> Bool {
        guard let dt1 = dt1, let dt2 = dt2 else {
            return dt1 == nil && dt2 == nil
        }
        return abs(dt1.date.timeIntervalSince1970 - dt2.date.timeIntervalSince1970) <= tolerance
    }
}

// MARK: - Convenience Extensions

extension ICalendarClient {

    /// Quick parse from string
    public static func parse(_ content: String) throws -> ICalendar {
        let client = ICalendarClient()
        return try client.parseCalendar(from: content)
    }

    /// Quick serialize to string
    public static func serialize(_ calendar: ICalendar) throws -> String {
        let client = ICalendarClient()
        return try client.serializeCalendar(calendar)
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
        reminderMinutes: Int? = nil,
        timeZone: TimeZone = .gmt,
        uid: String = UUID().uuidString
    ) -> ICalendar {
        var calendar = createCalendar(productId: configuration.defaultProductId)
        calendar.method = "REQUEST"

        var event = createEvent(
            summary: summary,
            startDate: startDate,
            endDate: endDate,
            location: location,
            description: description,
            uid: uid,
            timeZone: timeZone
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
        tasks: [(summary: String, dueDate: Date?, priority: Int?)],
        timeZone: TimeZone = .gmt
    ) -> ICalendar {
        var calendar = createCalendar(productId: configuration.defaultProductId)

        for task in tasks {
            let todo = createTodo(
                summary: task.summary,
                dueDate: task.dueDate,
                priority: task.priority,
                timeZone: timeZone
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

    /// Get the duration of this event in seconds
    public var eventDuration: TimeInterval? {
        guard let start = dateTimeStart?.date else { return nil }

        if let end = dateTimeEnd?.date {
            return end.timeIntervalSince(start)
        } else if let duration = duration {
            return duration.totalSeconds
        }
        return nil
    }

    /// Check if this event is happening now
    public func isHappeningNow(at date: Date = Date(), timeZone: TimeZone = .gmt) -> Bool {
        guard let startDateTime = dateTimeStart else { return false }
        let start = startDateTime.date

        // Handle all-day events differently
        if startDateTime.isDateOnly {
            let calendar = Calendar.current
            return calendar.isDate(date, inSameDayAs: start)
        }

        if let end = dateTimeEnd?.date {
            return date >= start && date <= end
        } else if let eventDuration = eventDuration {
            let end = start.addingTimeInterval(eventDuration)
            return date >= start && date <= end
        }
        return false
    }

    /// Check if this event occurs on a specific date
    public func occursOn(date: Date, timeZone: TimeZone = .gmt) -> Bool {
        guard let start = dateTimeStart?.date else { return false }

        let context = ICalendarContext(from: self)
        let calendar = context.workingCalendar(timeZone: timeZone)

        if isAllDay {
            return calendar.isDate(start, inSameDayAs: date)
        } else {
            // For timed events, check if the event spans across the given date
            if let end = dateTimeEnd?.date {
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                return start < dayEnd && end > dayStart
            } else {
                return calendar.isDate(start, inSameDayAs: date)
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

    /// Get all-day events
    public var allDayEvents: [ICalEvent] {
        events.filter { event in
            event.dateTimeStart?.isDateOnly == true
        }
    }

    /// Get recurring events
    public var recurringEvents: [ICalEvent] {
        events.filter { $0.recurrenceRule != nil }
    }

    /// Get events with alarms
    public var eventsWithAlarms: [ICalEvent] {
        events.filter { !$0.alarms.isEmpty }
    }

    /// Get events by status
    public func events(withStatus status: ICalEventStatus) -> [ICalEvent] {
        events.filter { $0.status == status }
    }

    /// Get confirmed events
    public var confirmedEvents: [ICalEvent] {
        events.filter { $0.status == .confirmed }
    }

    /// Get tentative events
    public var tentativeEvents: [ICalEvent] {
        events.filter { $0.status == .tentative }
    }

    /// Get cancelled events
    public var cancelledEvents: [ICalEvent] {
        events.filter { $0.status == .cancelled }
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
        updateBlock: (inout ICalEvent) -> Void,
        timeZone: TimeZone = .gmt
    ) -> Bool {
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
            event.lastModified = ICalDateTime(date: Date(), timeZone: timeZone)

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
