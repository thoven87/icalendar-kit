import Foundation

// MARK: - Date Extensions

extension Date {
    /// Create an ICalDateTime from this date
    public func asICalDateTime(timeZone: TimeZone = .gmt, isDateOnly: Bool = false) -> ICalDateTime {
        ICalDateTime(date: self, timeZone: timeZone, isDateOnly: isDateOnly)
    }

    /// Create an all-day ICalDateTime from this date
    public func asICalDateOnly(timeZone: TimeZone = .gmt) -> ICalDateTime {
        ICalDateTime(date: self, timeZone: nil, isDateOnly: true)
    }

    /// Create a UTC ICalDateTime from this date
    public func asICalDateTimeUTC() -> ICalDateTime {
        ICalDateTime(date: self, timeZone: TimeZone(abbreviation: "UTC"), isDateOnly: false)
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// Convert to ICalDuration
    public var asICalDuration: ICalDuration {
        let totalSeconds = Int(abs(self))
        let isNegative = self < 0

        let days = totalSeconds / (24 * 3600)
        let hours = (totalSeconds % (24 * 3600)) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return ICalDuration(
            days: days,
            hours: hours,
            minutes: minutes,
            seconds: seconds,
            isNegative: isNegative
        )
    }
}

// MARK: - String Extensions

extension String {
    /// Parse as ICalDateTime
    public var asICalDateTime: ICalDateTime? {
        ICalendarFormatter.parseDateTime(self)
    }

    /// Parse as ICalDuration
    public var asICalDuration: ICalDuration? {
        ICalendarFormatter.parseDuration(self)
    }

    /// Parse as ICalRecurrenceRule
    public var asICalRecurrenceRule: ICalRecurrenceRule? {
        ICalendarFormatter.parseRecurrenceRule(self)
    }

    /// Escape for iCalendar text property
    public var escapedForICalendar: String {
        ICalendarFormatter.escapeText(self)
    }

    /// Unescape from iCalendar text property
    public var unescapedFromICalendar: String {
        ICalendarFormatter.unescapeText(self)
    }
}

// MARK: - Array Extensions

extension Array where Element == ICalEvent {
    /// Filter events by date range
    public func events(from startDate: Date, to endDate: Date) -> [ICalEvent] {
        self.filter { event in
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

    /// Filter events by status
    public func events(with status: ICalEventStatus) -> [ICalEvent] {
        self.filter { $0.status == status }
    }

    /// Filter recurring events
    public var recurringEvents: [ICalEvent] {
        self.filter { $0.recurrenceRule != nil }
    }

    /// Filter all-day events
    public var allDayEvents: [ICalEvent] {
        self.filter { $0.dateTimeStart?.isDateOnly == true }
    }

    /// Sort events by start date
    public var sortedByStartDate: [ICalEvent] {
        self.sorted { lhs, rhs in
            guard let lhsStart = lhs.dateTimeStart?.date,
                let rhsStart = rhs.dateTimeStart?.date
            else {
                return false
            }
            return lhsStart < rhsStart
        }
    }
}

extension Array where Element == ICalTodo {
    /// Filter todos by status
    public func todos(with status: ICalTodoStatus) -> [ICalTodo] {
        self.filter { $0.status == status }
    }

    /// Filter overdue todos
    public func overdueTodos(asOf date: Date = Date()) -> [ICalTodo] {
        self.filter { todo in
            guard let due = todo.dueDate?.date else { return false }
            return due < date && todo.status != .completed && todo.status != .cancelled
        }
    }

    /// Filter completed todos
    public var completedTodos: [ICalTodo] {
        self.filter { $0.status == .completed }
    }

    /// Sort todos by due date
    public var sortedByDueDate: [ICalTodo] {
        self.sorted { lhs, rhs in
            guard let lhsDue = lhs.dueDate?.date,
                let rhsDue = rhs.dueDate?.date
            else {
                return false
            }
            return lhsDue < rhsDue
        }
    }

    /// Sort todos by priority
    public var sortedByPriority: [ICalTodo] {
        self.sorted { lhs, rhs in
            let lhsPriority = lhs.priority ?? 0
            let rhsPriority = rhs.priority ?? 0
            return lhsPriority > rhsPriority  // Higher priority first
        }
    }
}

// MARK: - Calendar Builder

/// Fluent interface for building calendars
// Old-style ICalendarBuilder removed in favor of result builder pattern in Foundation/ICalendarBuilder.swift

// MARK: - Event Builder

/// Fluent interface for building events
public struct ICalEventBuilder: Sendable {
    private var event: ICalEvent

    public init(summary: String, uid: String? = nil) {
        self.event = ICalEvent(uid: uid ?? UUID().uuidString, summary: summary)
        self.event.dateTimeStamp = ICalDateTime(date: Date())
    }

    public func description(_ description: String) -> ICalEventBuilder {
        var builder = self
        builder.event.description = description
        return builder
    }

    public func location(_ location: String) -> ICalEventBuilder {
        var builder = self
        builder.event.location = location
        return builder
    }

    public func startDate(_ date: Date, timeZone: TimeZone? = nil) -> ICalEventBuilder {
        var builder = self
        builder.event.dateTimeStart = ICalDateTime(date: date, timeZone: timeZone)
        return builder
    }

    public func endDate(_ date: Date, timeZone: TimeZone? = nil) -> ICalEventBuilder {
        var builder = self
        builder.event.dateTimeEnd = ICalDateTime(date: date, timeZone: timeZone)
        return builder
    }

    public func duration(_ duration: ICalDuration) -> ICalEventBuilder {
        var builder = self
        builder.event.duration = duration
        return builder
    }

    public func allDay(_ date: Date) -> ICalEventBuilder {
        var builder = self
        builder.event.dateTimeStart = ICalDateTime(date: date, isDateOnly: true)
        return builder
    }

    public func status(_ status: ICalEventStatus) -> ICalEventBuilder {
        var builder = self
        builder.event.status = status
        return builder
    }

    public func transparency(_ transparency: ICalTransparency) -> ICalEventBuilder {
        var builder = self
        builder.event.transparency = transparency
        return builder
    }

    public func classification(_ classification: ICalClassification) -> ICalEventBuilder {
        var builder = self
        builder.event.classification = classification
        return builder
    }

    public func priority(_ priority: Int) -> ICalEventBuilder {
        var builder = self
        builder.event.priority = priority
        return builder
    }

    public func organizer(_ organizer: ICalAttendee) -> ICalEventBuilder {
        var builder = self
        builder.event.organizer = organizer
        return builder
    }

    public func attendee(_ attendee: ICalAttendee) -> ICalEventBuilder {
        var builder = self
        builder.event.attendees.append(attendee)
        return builder
    }

    public func attendees(_ attendees: [ICalAttendee]) -> ICalEventBuilder {
        var builder = self
        builder.event.attendees = attendees
        return builder
    }

    public func recurrence(_ rule: ICalRecurrenceRule) -> ICalEventBuilder {
        var builder = self
        builder.event.recurrenceRule = rule
        return builder
    }

    public func alarm(_ alarm: ICalAlarm) -> ICalEventBuilder {
        var builder = self
        builder.event.addAlarm(alarm)
        return builder
    }

    public func categories(_ categories: [String]) -> ICalEventBuilder {
        var builder = self
        builder.event.categories = categories
        return builder
    }

    public func url(_ url: String) -> ICalEventBuilder {
        var builder = self
        builder.event.url = url
        return builder
    }

    public func build() -> ICalEvent {
        event
    }
}

// MARK: - Todo Builder

/// Fluent interface for building todos
public struct ICalTodoBuilder: Sendable {
    private var todo: ICalTodo

    public init(summary: String, uid: String? = nil, timeZone: TimeZone = .gmt) {
        self.todo = ICalTodo(uid: uid ?? UUID().uuidString, summary: summary)
        self.todo.dateTimeStamp = ICalDateTime(date: Date(), timeZone: timeZone)
    }

    public func description(_ description: String) -> ICalTodoBuilder {
        var builder = self
        builder.todo.description = description
        return builder
    }

    public func startDate(_ date: Date, timeZone: TimeZone = .gmt) -> ICalTodoBuilder {
        var builder = self
        builder.todo.dateTimeStart = ICalDateTime(date: date, timeZone: timeZone)
        return builder
    }

    public func dueDate(_ date: Date, timeZone: TimeZone = .gmt) -> ICalTodoBuilder {
        var builder = self
        builder.todo.dueDate = ICalDateTime(date: date, timeZone: timeZone)
        return builder
    }

    public func duration(_ duration: ICalDuration) -> ICalTodoBuilder {
        var builder = self
        builder.todo.duration = duration
        return builder
    }

    public func status(_ status: ICalTodoStatus) -> ICalTodoBuilder {
        var builder = self
        builder.todo.status = status
        return builder
    }

    public func priority(_ priority: Int) -> ICalTodoBuilder {
        var builder = self
        builder.todo.priority = priority
        return builder
    }

    public func percentComplete(_ percent: Int) -> ICalTodoBuilder {
        var builder = self
        builder.todo.percentComplete = percent
        return builder
    }

    public func organizer(_ organizer: ICalAttendee) -> ICalTodoBuilder {
        var builder = self
        builder.todo.organizer = organizer
        return builder
    }

    public func attendee(_ attendee: ICalAttendee) -> ICalTodoBuilder {
        var builder = self
        builder.todo.attendees.append(attendee)
        return builder
    }

    public func categories(_ categories: [String]) -> ICalTodoBuilder {
        var builder = self
        builder.todo.categories = categories
        return builder
    }

    public func alarm(_ alarm: ICalAlarm) -> ICalTodoBuilder {
        var builder = self
        builder.todo.addAlarm(alarm)
        return builder
    }

    public func build() -> ICalTodo {
        todo
    }
}

// MARK: - Quick Creation Functions

public func iCalendar(productId: String = "-//ICalendar Kit//EN", @ICalendarComponentBuilder builder: () -> [any ICalendarComponent]) -> ICalendar {
    var calendar = ICalendar(productId: productId)
    let components = builder()
    for component in components {
        calendar.components.append(component)
    }
    return calendar
}

public func event(summary: String, uid: String? = nil, @ICalEventPropertyBuilder builder: (ICalEventBuilder) -> ICalEventBuilder) -> ICalEvent {
    let eventBuilder = ICalEventBuilder(summary: summary, uid: uid)
    return builder(eventBuilder).build()
}

public func todo(summary: String, uid: String? = nil, @ICalTodoPropertyBuilder builder: (ICalTodoBuilder) -> ICalTodoBuilder) -> ICalTodo {
    let todoBuilder = ICalTodoBuilder(summary: summary, uid: uid)
    return builder(todoBuilder).build()
}

public func attendee(email: String, name: String? = nil) -> ICalAttendee {
    ICalAttendee(email: email, commonName: name)
}

public func organizer(email: String, name: String? = nil) -> ICalAttendee {
    ICalAttendee(
        email: email,
        commonName: name,
        role: .chair,
        participationStatus: .accepted
    )
}

// MARK: - Result Builders

@resultBuilder
public struct ICalendarComponentBuilder {
    public static func buildBlock(_ components: (any ICalendarComponent)...) -> [any ICalendarComponent] {
        Array(components)
    }

    public static func buildArray(_ components: [any ICalendarComponent]) -> [any ICalendarComponent] {
        components
    }

    public static func buildOptional(_ component: (any ICalendarComponent)?) -> [any ICalendarComponent] {
        component.map { [$0] } ?? []
    }

    public static func buildEither(first component: any ICalendarComponent) -> [any ICalendarComponent] {
        [component]
    }

    public static func buildEither(second component: any ICalendarComponent) -> [any ICalendarComponent] {
        [component]
    }
}

@resultBuilder
public struct ICalEventPropertyBuilder {
    public static func buildBlock(_ builder: ICalEventBuilder) -> ICalEventBuilder {
        builder
    }
}

@resultBuilder
public struct ICalTodoPropertyBuilder {
    public static func buildBlock(_ builder: ICalTodoBuilder) -> ICalTodoBuilder {
        builder
    }
}

// MARK: - Common Recurrence Patterns

public struct RecurrencePatterns {
    /// Daily recurrence
    public static func daily(count: Int? = nil, until: Date? = nil) -> ICalRecurrenceRule {
        ICalRecurrenceRule(
            frequency: .daily,
            until: until?.asICalDateTime(),
            count: count
        )
    }

    /// Weekly recurrence on specific days
    public static func weekly(on days: [ICalWeekday], count: Int? = nil, until: Date? = nil) -> ICalRecurrenceRule {
        ICalRecurrenceRule(
            frequency: .weekly,
            until: until?.asICalDateTime(),
            count: count,
            byWeekday: days
        )
    }

    /// Weekdays only (Monday-Friday)
    public static func weekdays(count: Int? = nil, until: Date? = nil) -> ICalRecurrenceRule {
        weekly(on: [.monday, .tuesday, .wednesday, .thursday, .friday], count: count, until: until)
    }

    /// Monthly recurrence on specific day of month
    public static func monthlyByDay(_ day: Int, count: Int? = nil, until: Date? = nil) -> ICalRecurrenceRule {
        ICalRecurrenceRule(
            frequency: .monthly,
            until: until?.asICalDateTime(),
            count: count,
            byMonthday: [day]
        )
    }

    /// Monthly recurrence on specific weekday occurrence (e.g., first Monday)
    public static func monthlyByWeekday(_ weekday: ICalWeekday, occurrence: Int, count: Int? = nil, until: Date? = nil) -> ICalRecurrenceRule {
        ICalRecurrenceRule(
            frequency: .monthly,
            until: until?.asICalDateTime(),
            count: count,
            byWeekday: [weekday]
        )
    }

    /// Yearly recurrence
    public static func yearly(count: Int? = nil, until: Date? = nil) -> ICalRecurrenceRule {
        ICalRecurrenceRule(
            frequency: .yearly,
            until: until?.asICalDateTime(),
            count: count
        )
    }
}

// MARK: - Time Zone Utilities

public struct TimeZoneUtilities {
    /// Create a basic time zone component
    public static func createBasicTimeZone(
        id: String,
        standardOffset: String,
        daylightOffset: String? = nil,
        standardName: String? = nil,
        daylightName: String? = nil
    ) -> ICalTimeZone {
        var timeZone = ICalTimeZone(timeZoneId: id)

        // Add standard time component
        var standardComponent = ICalTimeZoneComponent(isStandard: true)
        standardComponent.offsetTo = standardOffset
        standardComponent.offsetFrom = standardOffset
        if let name = standardName {
            standardComponent.timeZoneName = name
        }
        timeZone.components.append(standardComponent)

        // Add daylight time component if provided
        if let daylightOffset = daylightOffset {
            var daylightComponent = ICalTimeZoneComponent(isStandard: false)
            daylightComponent.offsetTo = daylightOffset
            daylightComponent.offsetFrom = standardOffset
            if let name = daylightName {
                daylightComponent.timeZoneName = name
            }
            timeZone.components.append(daylightComponent)
        }

        return timeZone
    }

    /// Get common time zones
    public static var commonTimeZones: [String: ICalTimeZone] {
        [
            "UTC": createBasicTimeZone(id: "UTC", standardOffset: "+0000", standardName: "UTC"),
            "EST": createBasicTimeZone(
                id: "America/New_York",
                standardOffset: "-0500",
                daylightOffset: "-0400",
                standardName: "EST",
                daylightName: "EDT"
            ),
            "PST": createBasicTimeZone(
                id: "America/Los_Angeles",
                standardOffset: "-0800",
                daylightOffset: "-0700",
                standardName: "PST",
                daylightName: "PDT"
            ),
            "CET": createBasicTimeZone(
                id: "Europe/Berlin",
                standardOffset: "+0100",
                daylightOffset: "+0200",
                standardName: "CET",
                daylightName: "CEST"
            ),
            "JST": createBasicTimeZone(id: "Asia/Tokyo", standardOffset: "+0900", standardName: "JST"),
        ]
    }
}

// MARK: - Validation Utilities

public struct ValidationUtilities {
    /// Check if email is valid format
    public static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    /// Check if UID is valid format
    public static func isValidUID(_ uid: String) -> Bool {
        !uid.isEmpty && uid.count <= 255
    }

    /// Check if priority is valid range
    public static func isValidPriority(_ priority: Int) -> Bool {
        priority >= 0 && priority <= 9
    }

    /// Check if percent complete is valid range
    public static func isValidPercentComplete(_ percent: Int) -> Bool {
        percent >= 0 && percent <= 100
    }
}
