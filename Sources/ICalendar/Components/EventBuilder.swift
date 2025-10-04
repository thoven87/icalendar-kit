import Foundation

/// User-friendly event builder for those not familiar with iCalendar internals
/// Also serves as a result builder for creating multiple events
@resultBuilder
public struct EventBuilder: Sendable, ICalendarBuildable {
    private var event: ICalEvent

    // MARK: - Result Builder Methods

    public static func buildBlock(_ events: EventBuilder...) -> [EventBuilder] {
        Array(events)
    }

    public static func buildBlock(_ events: [EventBuilder]...) -> [EventBuilder] {
        events.flatMap { $0 }
    }

    public static func buildArray(_ events: [EventBuilder]) -> [EventBuilder] {
        events
    }

    public static func buildOptional(_ event: EventBuilder?) -> [EventBuilder] {
        [event].compactMap { $0 }
    }

    public static func buildEither(first event: EventBuilder) -> EventBuilder {
        event
    }

    public static func buildEither(second event: EventBuilder) -> EventBuilder {
        event
    }

    public static func buildEither(first events: [EventBuilder]) -> [EventBuilder] {
        events
    }

    public static func buildEither(second events: [EventBuilder]) -> [EventBuilder] {
        events
    }

    public static func buildExpression(_ expression: EventBuilder) -> EventBuilder {
        expression
    }

    public static func buildForLoopExpression(_ expression: EventBuilder) -> EventBuilder {
        expression
    }

    public static func buildFinalResult(_ events: [EventBuilder]) -> [ICalEvent] {
        events.map { $0.buildEvent() }
    }

    // MARK: - Single Event Initializers

    public init(summary: String, uid: String = UUID().uuidString) {
        self.event = ICalEvent(uid: uid, summary: summary)
        self.event.dateTimeStamp = ICalDateTime(date: Date())
    }

    // MARK: - User-Friendly Property Setters

    /// Sets the event title/summary
    public func title(_ title: String) -> EventBuilder {
        var builder = self
        builder.event.summary = title
        return builder
    }

    /// Sets the event description
    public func description(_ description: String) -> EventBuilder {
        var builder = self
        builder.event.description = description
        return builder
    }

    /// Sets the event location
    public func location(_ location: String) -> EventBuilder {
        var builder = self
        builder.event.location = location
        return builder
    }

    /// Sets the start time with timezone
    public func starts(at date: Date, timeZone: TimeZone = .current) -> EventBuilder {
        var builder = self
        builder.event.dateTimeStart = ICalDateTime(date: date, timeZone: timeZone)
        return builder
    }

    /// Sets the end time with timezone
    public func ends(at date: Date, timeZone: TimeZone = .current) -> EventBuilder {
        var builder = self
        builder.event.dateTimeEnd = ICalDateTime(date: date, timeZone: timeZone)
        return builder
    }

    /// Sets duration instead of end time
    public func duration(_ duration: TimeInterval) -> EventBuilder {
        var builder = self
        builder.event.duration = ICalDuration(timeInterval: duration)
        builder.event.dateTimeEnd = nil  // Clear end time since duration is mutually exclusive
        return builder
    }

    /// Sets as all-day event
    public func allDay(on date: Date, timeZone: TimeZone = .current) -> EventBuilder {
        var builder = self
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: date)
        builder.event.dateTimeStart = ICalDateTime(date: startOfDay, timeZone: timeZone, isDateOnly: true)
        builder.event.dateTimeEnd = nil
        return builder
    }

    /// Sets event as confirmed
    public func confirmed() -> EventBuilder {
        var builder = self
        builder.event.status = .confirmed
        return builder
    }

    /// Sets event as tentative
    public func tentative() -> EventBuilder {
        var builder = self
        builder.event.status = .tentative
        return builder
    }

    /// Sets event as cancelled
    public func cancelled() -> EventBuilder {
        var builder = self
        builder.event.status = .cancelled
        return builder
    }

    /// Sets event priority (0-9, where 0 is undefined, 1 is highest priority, 9 is lowest)
    public func priority(_ priority: Int) -> EventBuilder {
        var builder = self
        builder.event.priority = max(0, min(9, priority))
        return builder
    }

    /// Sets event as high priority (priority 1)
    public func highPriority() -> EventBuilder {
        priority(1)
    }

    /// Sets event as normal priority (priority 5)
    public func normalPriority() -> EventBuilder {
        priority(5)
    }

    /// Sets event as low priority (priority 9)
    public func lowPriority() -> EventBuilder {
        priority(9)
    }

    /// Sets event as public
    public func publicEvent() -> EventBuilder {
        var builder = self
        builder.event.classification = .publicAccess
        return builder
    }

    /// Sets event as private
    public func privateEvent() -> EventBuilder {
        var builder = self
        builder.event.classification = .privateAccess
        return builder
    }

    /// Sets event as confidential
    public func confidential() -> EventBuilder {
        var builder = self
        builder.event.classification = .confidential
        return builder
    }

    /// Sets the organizer of the event
    public func organizer(email: String, name: String? = nil) -> EventBuilder {
        var builder = self
        builder.event.organizer = ICalAttendee(
            email: email,
            commonName: name,
            role: .chair
        )
        return builder
    }

    /// Adds an attendee to the event
    public func attendee(email: String, name: String? = nil, required: Bool = true) -> EventBuilder {
        var builder = self
        let attendee = ICalAttendee(
            email: email,
            commonName: name,
            role: required ? .requiredParticipant : .optionalParticipant,
            participationStatus: .needsAction,
            userType: .individual,
            rsvp: true
        )
        builder.event.attendees.append(attendee)
        return builder
    }

    /// Sets event URL
    public func url(_ url: String) -> EventBuilder {
        var builder = self
        builder.event.url = url
        return builder
    }

    /// Sets event URL from URL object
    public func url(_ url: URL) -> EventBuilder {
        self.url(url.absoluteString)
    }

    /// Adds categories to the event
    public func categories(_ categories: String...) -> EventBuilder {
        var builder = self
        builder.event.categories = Array(categories)
        return builder
    }

    /// Makes the event repeat daily
    public func repeats(every days: Int = 1, until endDate: Date? = nil, count: Int? = nil) -> EventBuilder {
        var builder = self
        builder.event.recurrenceRule = ICalRecurrenceRule(
            frequency: .daily,
            until: endDate.map { ICalDateTime(date: $0) },
            count: count,
            interval: days
        )
        return builder
    }

    /// Makes the event repeat weekly
    public func repeatsWeekly(every weeks: Int = 1, on weekdays: [ICalWeekday] = [], until endDate: Date? = nil, count: Int? = nil) -> EventBuilder {
        var builder = self
        builder.event.recurrenceRule = ICalRecurrenceRule(
            frequency: .weekly,
            until: endDate.map { ICalDateTime(date: $0) },
            count: count,
            interval: weeks,
            byWeekday: weekdays
        )
        return builder
    }

    /// Makes the event repeat monthly
    public func repeatsMonthly(every months: Int = 1, until endDate: Date? = nil, count: Int? = nil) -> EventBuilder {
        var builder = self
        builder.event.recurrenceRule = ICalRecurrenceRule(
            frequency: .monthly,
            until: endDate.map { ICalDateTime(date: $0) },
            count: count,
            interval: months
        )
        return builder
    }

    /// Makes the event repeat weekly on weekdays only
    public func repeatsMonthlyWeekdays(every weeks: Int = 1, until endDate: Date? = nil, count: Int? = nil) -> EventBuilder {
        var builder = self
        builder.event.recurrenceRule = ICalRecurrenceRule(
            frequency: .weekly,
            until: endDate.map { ICalDateTime(date: $0) },
            count: count,
            interval: weeks,
            byWeekday: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        return builder
    }

    /// Makes the event repeat monthly on specific weekdays
    public func repeatsMonthly(every months: Int = 1, on weekdays: [ICalWeekday], until endDate: Date? = nil, count: Int? = nil) -> EventBuilder {
        var builder = self
        builder.event.recurrenceRule = ICalRecurrenceRule(
            frequency: .monthly,
            until: endDate.map { ICalDateTime(date: $0) },
            count: count,
            interval: months,
            byWeekday: weekdays
        )
        return builder
    }

    /// Makes the event repeat on first weekday of each month (PROPER monthly weekday implementation)
    public func repeatsFirstWeekdayOfMonth(weekday: ICalWeekday, every months: Int = 1, until endDate: Date? = nil, count: Int? = nil) -> EventBuilder
    {
        var builder = self
        builder.event.recurrenceRule = ICalRecurrenceRule(
            frequency: .monthly,
            until: endDate.map { ICalDateTime(date: $0) },
            count: count,
            interval: months,
            byWeekday: [weekday],
            bySetpos: [1]  // First occurrence of the weekday
        )
        return builder
    }

    /// Makes the event repeat yearly
    public func repeatsYearly(every years: Int = 1, until endDate: Date? = nil, count: Int? = nil) -> EventBuilder {
        var builder = self
        builder.event.recurrenceRule = ICalRecurrenceRule(
            frequency: .yearly,
            until: endDate.map { ICalDateTime(date: $0) },
            count: count,
            interval: years
        )
        return builder
    }

    /// Adds a reminder before the event
    public func reminderBefore(minutes: Int) -> EventBuilder {
        addAlarm(action: .display, minutesBefore: minutes, description: event.summary ?? "Reminder")
    }

    /// Adds exception dates (dates when recurring event should not occur)
    public func except(on dates: Date..., timeZone: TimeZone = .current) -> EventBuilder {
        var builder = self
        let exceptionDates = dates.map { ICalDateTime(date: $0, timeZone: timeZone) }
        builder.event.exceptionDates.append(contentsOf: exceptionDates)
        return builder
    }

    /// Creates timestamp properties
    public func createdNow() -> EventBuilder {
        var builder = self
        builder.event.created = ICalDateTime(date: Date())
        return builder
    }

    /// Creates an alarm with duration trigger (type-safe)
    public func addAlarm(action: ICalAlarmAction, minutesBefore: Int, description: String? = nil, attachments: [ICalAttachment] = []) -> EventBuilder
    {
        var builder = self
        let trigger = "-PT\(minutesBefore)M"
        var alarm = ICalAlarm(action: action, trigger: trigger)
        alarm.description = description
        if !attachments.isEmpty {
            alarm.attachments.append(contentsOf: attachments)
        }
        builder.event.addAlarm(alarm)
        return builder
    }

    /// Creates an alarm with duration trigger using ICalDuration (most type-safe)
    public func addAlarm(
        action: ICalAlarmAction,
        duration: ICalDuration,
        description: String? = nil,
        attachments: [ICalAttachment] = []
    ) -> EventBuilder {
        var builder = self
        let trigger = "-\(duration.description)"
        var alarm = ICalAlarm(action: action, trigger: trigger)
        alarm.description = description
        if !attachments.isEmpty {
            alarm.attachments.append(contentsOf: attachments)
        }
        builder.event.addAlarm(alarm)
        return builder
    }

    /// Creates an alarm with absolute datetime trigger (e.g., trigger at exactly 9:00 AM current time zone)
    public func addAlarm(
        action: ICalAlarmAction,
        at date: Date,
        timeZone: TimeZone = .current,
        description: String? = nil,
        attachments: [ICalAttachment] = []
    ) -> EventBuilder {
        var builder = self
        let dateTime = ICalDateTime(date: date, timeZone: timeZone)
        let trigger = ICalendarFormatter.format(dateTime: dateTime)
        var alarm = ICalAlarm(action: action, trigger: trigger)
        alarm.description = description
        if !attachments.isEmpty {
            alarm.attachments.append(contentsOf: attachments)
        }
        builder.event.addAlarm(alarm)
        return builder
    }

    /// Creates an alarm that triggers at the event start time (useful for 9 AM alarms on 9 AM events)
    public func addAlarmAtEventStart(action: ICalAlarmAction = .display, description: String? = nil) -> EventBuilder {
        var builder = self
        // Trigger at event start time (0 minutes before)
        var alarm = ICalAlarm(action: action, trigger: "PT0M")
        alarm.description = description ?? event.summary ?? "Event starting now"
        builder.event.addAlarm(alarm)
        return builder
    }

    /// Sets created timestamp
    public func created(at date: Date) -> EventBuilder {
        var builder = self
        builder.event.created = ICalDateTime(date: date)
        return builder
    }

    /// Updates last modified timestamp to now
    public func lastModifiedNow() -> EventBuilder {
        var builder = self
        builder.event.lastModified = ICalDateTime(date: Date())
        return builder
    }

    // MARK: - Advanced Setters

    /// Sets custom properties for power users
    public func customProperty(name: String, value: String, parameters: [String: String] = [:]) -> EventBuilder {
        var builder = self
        builder.event.properties.append(ICalProperty(name: name, value: value, parameters: parameters))
        return builder
    }

    /// Applies a custom modification
    public func modify(_ modification: (inout ICalEvent) -> Void) -> EventBuilder {
        var builder = self
        modification(&builder.event)
        return builder
    }

    // MARK: - Build

    /// Builds the final ICalEvent (for direct use and testing)
    public func buildEvent() -> ICalEvent {
        var finalEvent = event
        finalEvent.applyCompliance()  // Ensure RFC compliance
        return finalEvent
    }

    /// ICalendarBuildable conformance - builds for use in ICalendar result builder
    public func build() -> BuildResult {
        .single(buildEvent())
    }
}

// MARK: - Convenience Extensions

extension EventBuilder {
    /// Common meeting builder
    public static func meeting(
        title: String,
        startTime: Date,
        duration: TimeInterval,
        location: String? = nil,
        organizer: (email: String, name: String?)? = nil
    ) -> EventBuilder {
        var builder = EventBuilder(summary: title)
            .starts(at: startTime)
            .duration(duration)
            .confirmed()
            .createdNow()

        if let location = location {
            builder = builder.location(location)
        }

        if let organizer = organizer {
            builder = builder.organizer(email: organizer.email, name: organizer.name)
        }

        return builder
    }

    /// Common appointment builder
    public static func appointment(
        title: String,
        startTime: Date,
        endTime: Date,
        location: String? = nil
    ) -> EventBuilder {
        var builder = EventBuilder(summary: title)
            .starts(at: startTime)
            .ends(at: endTime)
            .confirmed()
            .privateEvent()
            .createdNow()

        if let location = location {
            builder = builder.location(location)
        }

        return builder
    }

    /// Birthday event builder
    public static func birthday(
        name: String,
        date: Date
    ) -> EventBuilder {
        EventBuilder(summary: "\(name)'s Birthday")
            .allDay(on: date)
            .repeatsYearly()
            .categories("Birthday", "Personal")
            .confirmed()
            .createdNow()
    }

    /// Holiday event builder
    public static func holiday(
        name: String,
        date: Date
    ) -> EventBuilder {
        EventBuilder(summary: name)
            .allDay(on: date)
            .publicEvent()
            .categories("Holiday")
            .confirmed()
            .createdNow()
    }

    /// Reminder event builder
    public static func reminder(
        title: String,
        date: Date,
        duration: TimeInterval = 0
    ) -> EventBuilder {
        var builder = EventBuilder(summary: title)
            .starts(at: date)
            .privateEvent()
            .categories("Reminder")
            .confirmed()
            .createdNow()

        if duration > 0 {
            builder = builder.duration(duration)
        }

        return builder
    }
}

// MARK: - ICalendar Extension for User-Friendly API

extension ICalendar {
    /// Creates a calendar with user-friendly event builders using result builder syntax
    public static func create(
        productId: String = "iCalendar-Kit//iCalendar-Kit//EN",
        name: String? = nil,
        description: String? = nil,
        @EventBuilder events: () -> [ICalEvent]
    ) -> ICalendar {
        var calendar = ICalendar(productId: productId)

        if let name = name {
            calendar.name = name
        }

        if let description = description {
            calendar.calendarDescription = description
        }

        let calendarEvents = events()
        for event in calendarEvents {
            calendar.addEvent(event)
        }

        calendar.applyCompliance()
        return calendar
    }

    /// Creates a calendar with a single event
    public static func withEvent(
        productId: String = "iCalendar-Kit//iCalendar-Kit//EN",
        event: EventBuilder
    ) -> ICalendar {
        var calendar = ICalendar(productId: productId)
        calendar.addEvent(event.buildEvent())
        calendar.applyCompliance()
        return calendar
    }

    /// Creates a calendar with multiple events from an array
    public static func withEvents(
        _ events: [EventBuilder],
        productId: String = "iCalendar-Kit//iCalendar-Kit//EN"
    ) -> ICalendar {
        var calendar = ICalendar(productId: productId)
        for eventBuilder in events {
            calendar.addEvent(eventBuilder.buildEvent())
        }
        calendar.applyCompliance()
        return calendar
    }
}

// MARK: - Weekday Extensions for User-Friendliness

extension ICalWeekday {
    public static let mon = ICalWeekday.monday
    public static let tue = ICalWeekday.tuesday
    public static let wed = ICalWeekday.wednesday
    public static let thu = ICalWeekday.thursday
    public static let fri = ICalWeekday.friday
    public static let sat = ICalWeekday.saturday
    public static let sun = ICalWeekday.sunday

    public static let weekdays: [ICalWeekday] = [.mon, .tue, .wed, .thu, .fri]
    public static let weekends: [ICalWeekday] = [.sat, .sun]
}
