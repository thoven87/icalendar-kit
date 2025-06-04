import Foundation

// MARK: - Calendar Container

/// Represents a complete iCalendar object (VCALENDAR)
public struct ICalendar: ICalendarComponent, Sendable {
    public static let componentName = "VCALENDAR"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Calendar version (typically "2.0")
    public var version: String {
        get { getPropertyValue(ICalPropertyName.version) ?? "2.0" }
        set { setPropertyValue(ICalPropertyName.version, value: newValue) }
    }

    /// Product identifier
    public var productId: String {
        get { getPropertyValue(ICalPropertyName.productId) ?? "" }
        set { setPropertyValue(ICalPropertyName.productId, value: newValue) }
    }

    /// Calendar scale (typically "GREGORIAN")
    public var calendarScale: String? {
        get { getPropertyValue(ICalPropertyName.calendarScale) }
        set { setPropertyValue(ICalPropertyName.calendarScale, value: newValue) }
    }

    /// iTIP method
    public var method: String? {
        get { getPropertyValue(ICalPropertyName.method) }
        set { setPropertyValue(ICalPropertyName.method, value: newValue) }
    }

    /// Events contained in this calendar
    public var events: [ICalEvent] {
        components.compactMap { $0 as? ICalEvent }
    }

    /// To-dos contained in this calendar
    public var todos: [ICalTodo] {
        components.compactMap { $0 as? ICalTodo }
    }

    /// Journal entries contained in this calendar
    public var journals: [ICalJournal] {
        components.compactMap { $0 as? ICalJournal }
    }

    /// Time zones contained in this calendar
    public var timeZones: [ICalTimeZone] {
        components.compactMap { $0 as? ICalTimeZone }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components
    }

    public init(productId: String, version: String = "2.0", components: [any ICalendarComponent] = []) {
        self.properties = [
            ICalProperty(name: ICalPropertyName.version, value: version),
            ICalProperty(name: ICalPropertyName.productId, value: productId),
        ]
        self.components = components
    }

    /// Add an event to the calendar
    public mutating func addEvent(_ event: ICalEvent) {
        components.append(event)
    }

    /// Add a to-do to the calendar
    public mutating func addTodo(_ todo: ICalTodo) {
        components.append(todo)
    }

    /// Add a journal entry to the calendar
    public mutating func addJournal(_ journal: ICalJournal) {
        components.append(journal)
    }

    /// Add a time zone to the calendar
    public mutating func addTimeZone(_ timeZone: ICalTimeZone) {
        components.append(timeZone)
    }
}

// MARK: - Event Component

/// Represents a calendar event (VEVENT)
public struct ICalEvent: ICalendarComponent, Sendable {
    public static let componentName = "VEVENT"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Unique identifier for the event
    public var uid: String {
        get { getPropertyValue(ICalPropertyName.uid) ?? UUID().uuidString }
        set { setPropertyValue(ICalPropertyName.uid, value: newValue) }
    }

    /// Date-time stamp (when the event was created/last modified)
    public var dateTimeStamp: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStamp) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStamp, value: newValue) }
    }

    /// Start date and time
    public var dateTimeStart: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStart) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStart, value: newValue) }
    }

    /// End date and time
    public var dateTimeEnd: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeEnd) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeEnd, value: newValue) }
    }

    /// Duration of the event
    public var duration: ICalDuration? {
        get { getDurationProperty(ICalPropertyName.duration) }
        set { setDurationProperty(ICalPropertyName.duration, value: newValue) }
    }

    /// Event summary/title
    public var summary: String? {
        get { getPropertyValue(ICalPropertyName.summary) }
        set { setPropertyValue(ICalPropertyName.summary, value: newValue) }
    }

    /// Event description
    public var description: String? {
        get { getPropertyValue(ICalPropertyName.description) }
        set { setPropertyValue(ICalPropertyName.description, value: newValue) }
    }

    /// Event location
    public var location: String? {
        get { getPropertyValue(ICalPropertyName.location) }
        set { setPropertyValue(ICalPropertyName.location, value: newValue) }
    }

    /// Event status
    public var status: ICalEventStatus? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.status) else { return nil }
            return ICalEventStatus(rawValue: value)
        }
        set { setPropertyValue(ICalPropertyName.status, value: newValue?.rawValue) }
    }

    /// Event transparency
    public var transparency: ICalTransparency? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.transparency) else { return nil }
            return ICalTransparency(rawValue: value)
        }
        set { setPropertyValue(ICalPropertyName.transparency, value: newValue?.rawValue) }
    }

    /// Event classification
    public var classification: ICalClassification? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.classification) else { return nil }
            return ICalClassification(rawValue: value)
        }
        set { setPropertyValue(ICalPropertyName.classification, value: newValue?.rawValue) }
    }

    /// Event priority (0-9, where 0 is undefined)
    public var priority: Int? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.priority) else { return nil }
            return Int(value)
        }
        set { setPropertyValue(ICalPropertyName.priority, value: newValue?.description) }
    }

    /// Sequence number for updates
    public var sequence: Int? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.sequence) else { return nil }
            return Int(value)
        }
        set { setPropertyValue(ICalPropertyName.sequence, value: newValue?.description) }
    }

    /// Recurrence rule
    public var recurrenceRule: ICalRecurrenceRule? {
        get { getRecurrenceRuleProperty(ICalPropertyName.recurrenceRule) }
        set { setRecurrenceRuleProperty(ICalPropertyName.recurrenceRule, value: newValue) }
    }

    /// Event organizer
    public var organizer: ICalAttendee? {
        get { getAttendeeProperty(ICalPropertyName.organizer) }
        set { setAttendeeProperty(ICalPropertyName.organizer, value: newValue) }
    }

    /// Event attendees
    public var attendees: [ICalAttendee] {
        get { getAttendeesProperty(ICalPropertyName.attendee) }
        set { setAttendeesProperty(ICalPropertyName.attendee, values: newValue) }
    }

    /// Event categories
    public var categories: [String] {
        get { getCategoriesProperty() }
        set { setCategoriesProperty(newValue) }
    }

    /// Event URL
    public var url: String? {
        get { getPropertyValue(ICalPropertyName.url) }
        set { setPropertyValue(ICalPropertyName.url, value: newValue) }
    }

    /// Creation date
    public var created: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.created) }
        set { setDateTimeProperty(ICalPropertyName.created, value: newValue) }
    }

    /// Last modified date
    public var lastModified: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.lastModified) }
        set { setDateTimeProperty(ICalPropertyName.lastModified, value: newValue) }
    }

    /// Alarms associated with this event
    public var alarms: [ICalAlarm] {
        components.compactMap { $0 as? ICalAlarm }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components
    }

    public init(uid: String = UUID().uuidString, summary: String) {
        let now = ICalDateTime(date: Date())
        self.properties = [
            ICalProperty(name: ICalPropertyName.uid, value: uid),
            ICalProperty(name: ICalPropertyName.dateTimeStamp, value: ICalendarFormatter.format(dateTime: now)),
            ICalProperty(name: ICalPropertyName.summary, value: summary),
        ]
        self.components = []
    }

    /// Add an alarm to this event
    public mutating func addAlarm(_ alarm: ICalAlarm) {
        components.append(alarm)
    }
}

// MARK: - Todo Component

/// Represents a to-do item (VTODO)
public struct ICalTodo: ICalendarComponent, Sendable {
    public static let componentName = "VTODO"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Unique identifier
    public var uid: String {
        get { getPropertyValue(ICalPropertyName.uid) ?? UUID().uuidString }
        set { setPropertyValue(ICalPropertyName.uid, value: newValue) }
    }

    /// Date-time stamp
    public var dateTimeStamp: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStamp) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStamp, value: newValue) }
    }

    /// Start date and time
    public var dateTimeStart: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStart) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStart, value: newValue) }
    }

    /// Due date and time
    public var dueDate: ICalDateTime? {
        get { getDateTimeProperty("DUE") }
        set { setDateTimeProperty("DUE", value: newValue) }
    }

    /// Completion date and time
    public var completed: ICalDateTime? {
        get { getDateTimeProperty("COMPLETED") }
        set { setDateTimeProperty("COMPLETED", value: newValue) }
    }

    /// Duration
    public var duration: ICalDuration? {
        get { getDurationProperty(ICalPropertyName.duration) }
        set { setDurationProperty(ICalPropertyName.duration, value: newValue) }
    }

    /// Summary
    public var summary: String? {
        get { getPropertyValue(ICalPropertyName.summary) }
        set { setPropertyValue(ICalPropertyName.summary, value: newValue) }
    }

    /// Description
    public var description: String? {
        get { getPropertyValue(ICalPropertyName.description) }
        set { setPropertyValue(ICalPropertyName.description, value: newValue) }
    }

    /// Status
    public var status: ICalTodoStatus? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.status) else { return nil }
            return ICalTodoStatus(rawValue: value)
        }
        set { setPropertyValue(ICalPropertyName.status, value: newValue?.rawValue) }
    }

    /// Priority
    public var priority: Int? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.priority) else { return nil }
            return Int(value)
        }
        set { setPropertyValue(ICalPropertyName.priority, value: newValue?.description) }
    }

    /// Percent complete
    public var percentComplete: Int? {
        get {
            guard let value = getPropertyValue("PERCENT-COMPLETE") else { return nil }
            return Int(value)
        }
        set { setPropertyValue("PERCENT-COMPLETE", value: newValue?.description) }
    }

    /// Organizer
    public var organizer: ICalAttendee? {
        get { getAttendeeProperty(ICalPropertyName.organizer) }
        set { setAttendeeProperty(ICalPropertyName.organizer, value: newValue) }
    }

    /// Attendees
    public var attendees: [ICalAttendee] {
        get { getAttendeesProperty(ICalPropertyName.attendee) }
        set { setAttendeesProperty(ICalPropertyName.attendee, values: newValue) }
    }

    /// Categories
    public var categories: [String] {
        get { getCategoriesProperty() }
        set { setCategoriesProperty(newValue) }
    }

    /// Alarms
    public var alarms: [ICalAlarm] {
        components.compactMap { $0 as? ICalAlarm }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components
    }

    public init(uid: String = UUID().uuidString, summary: String) {
        let now = ICalDateTime(date: Date())
        self.properties = [
            ICalProperty(name: ICalPropertyName.uid, value: uid),
            ICalProperty(name: ICalPropertyName.dateTimeStamp, value: ICalendarFormatter.format(dateTime: now)),
            ICalProperty(name: ICalPropertyName.summary, value: summary),
        ]
        self.components = []
    }

    /// Add an alarm to this todo
    public mutating func addAlarm(_ alarm: ICalAlarm) {
        components.append(alarm)
    }
}

// MARK: - Journal Component

/// Represents a journal entry (VJOURNAL)
public struct ICalJournal: ICalendarComponent, Sendable {
    public static let componentName = "VJOURNAL"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Unique identifier
    public var uid: String {
        get { getPropertyValue(ICalPropertyName.uid) ?? UUID().uuidString }
        set { setPropertyValue(ICalPropertyName.uid, value: newValue) }
    }

    /// Date-time stamp
    public var dateTimeStamp: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStamp) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStamp, value: newValue) }
    }

    /// Start date and time
    public var dateTimeStart: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStart) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStart, value: newValue) }
    }

    /// Summary
    public var summary: String? {
        get { getPropertyValue(ICalPropertyName.summary) }
        set { setPropertyValue(ICalPropertyName.summary, value: newValue) }
    }

    /// Description
    public var description: String? {
        get { getPropertyValue(ICalPropertyName.description) }
        set { setPropertyValue(ICalPropertyName.description, value: newValue) }
    }

    /// Status
    public var status: ICalJournalStatus? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.status) else { return nil }
            return ICalJournalStatus(rawValue: value)
        }
        set { setPropertyValue(ICalPropertyName.status, value: newValue?.rawValue) }
    }

    /// Classification
    public var classification: ICalClassification? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.classification) else { return nil }
            return ICalClassification(rawValue: value)
        }
        set { setPropertyValue(ICalPropertyName.classification, value: newValue?.rawValue) }
    }

    /// Organizer
    public var organizer: ICalAttendee? {
        get { getAttendeeProperty(ICalPropertyName.organizer) }
        set { setAttendeeProperty(ICalPropertyName.organizer, value: newValue) }
    }

    /// Attendees
    public var attendees: [ICalAttendee] {
        get { getAttendeesProperty(ICalPropertyName.attendee) }
        set { setAttendeesProperty(ICalPropertyName.attendee, values: newValue) }
    }

    /// Categories
    public var categories: [String] {
        get { getCategoriesProperty() }
        set { setCategoriesProperty(newValue) }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components
    }

    public init(uid: String = UUID().uuidString, summary: String) {
        let now = ICalDateTime(date: Date())
        self.properties = [
            ICalProperty(name: ICalPropertyName.uid, value: uid),
            ICalProperty(name: ICalPropertyName.dateTimeStamp, value: ICalendarFormatter.format(dateTime: now)),
            ICalProperty(name: ICalPropertyName.summary, value: summary),
        ]
        self.components = []
    }
}

// MARK: - Alarm Component

/// Alarm action types
public enum ICalAlarmAction: String, Sendable, CaseIterable, Codable {
    case audio = "AUDIO"
    case display = "DISPLAY"
    case email = "EMAIL"
    case procedure = "PROCEDURE"
}

/// Represents an alarm (VALARM)
public struct ICalAlarm: ICalendarComponent, Sendable {
    public static let componentName = "VALARM"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Alarm action
    public var action: ICalAlarmAction? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.action) else { return nil }
            return ICalAlarmAction(rawValue: value)
        }
        set { setPropertyValue(ICalPropertyName.action, value: newValue?.rawValue) }
    }

    /// Trigger (when the alarm should fire)
    public var trigger: String? {
        get { getPropertyValue(ICalPropertyName.trigger) }
        set { setPropertyValue(ICalPropertyName.trigger, value: newValue) }
    }

    /// Repeat count
    public var repeatCount: Int? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.repeatCount) else { return nil }
            return Int(value)
        }
        set { setPropertyValue(ICalPropertyName.repeatCount, value: newValue?.description) }
    }

    /// Duration between repeats
    public var duration: ICalDuration? {
        get { getDurationProperty(ICalPropertyName.duration) }
        set { setDurationProperty(ICalPropertyName.duration, value: newValue) }
    }

    /// Description (for display alarms)
    public var description: String? {
        get { getPropertyValue(ICalPropertyName.description) }
        set { setPropertyValue(ICalPropertyName.description, value: newValue) }
    }

    /// Summary (for email alarms)
    public var summary: String? {
        get { getPropertyValue(ICalPropertyName.summary) }
        set { setPropertyValue(ICalPropertyName.summary, value: newValue) }
    }

    /// Attendees (for email alarms)
    public var attendees: [ICalAttendee] {
        get { getAttendeesProperty(ICalPropertyName.attendee) }
        set { setAttendeesProperty(ICalPropertyName.attendee, values: newValue) }
    }

    /// Attachment (for audio alarms)
    public var attach: String? {
        get { getPropertyValue(ICalPropertyName.attach) }
        set { setPropertyValue(ICalPropertyName.attach, value: newValue) }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components
    }

    public init(action: ICalAlarmAction, trigger: String) {
        self.properties = [
            ICalProperty(name: ICalPropertyName.action, value: action.rawValue),
            ICalProperty(name: ICalPropertyName.trigger, value: trigger),
        ]
        self.components = []
    }
}

// MARK: - Time Zone Component

/// Represents a time zone (VTIMEZONE)
public struct ICalTimeZone: ICalendarComponent, Sendable {
    public static let componentName = "VTIMEZONE"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Time zone identifier
    public var timeZoneId: String? {
        get { getPropertyValue(ICalPropertyName.timeZoneId) }
        set { setPropertyValue(ICalPropertyName.timeZoneId, value: newValue) }
    }

    /// Time zone URL
    public var timeZoneUrl: String? {
        get { getPropertyValue(ICalPropertyName.timeZoneUrl) }
        set { setPropertyValue(ICalPropertyName.timeZoneUrl, value: newValue) }
    }

    /// Last modified
    public var lastModified: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.lastModified) }
        set { setDateTimeProperty(ICalPropertyName.lastModified, value: newValue) }
    }

    /// Standard time components
    public var standardTimes: [ICalTimeZoneComponent] {
        components.compactMap { $0 as? ICalTimeZoneComponent }.filter { $0.isStandard }
    }

    /// Daylight time components
    public var daylightTimes: [ICalTimeZoneComponent] {
        components.compactMap { $0 as? ICalTimeZoneComponent }.filter { !$0.isStandard }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components
    }

    public init(timeZoneId: String) {
        self.properties = [
            ICalProperty(name: ICalPropertyName.timeZoneId, value: timeZoneId)
        ]
        self.components = []
    }
}

// MARK: - Time Zone Sub-Component

/// Represents a time zone sub-component (STANDARD or DAYLIGHT)
public struct ICalTimeZoneComponent: ICalendarComponent, Sendable {
    public let isStandard: Bool

    public static var componentName: String { "STANDARD" }  // Or "DAYLIGHT"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Start date and time
    public var dateTimeStart: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStart) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStart, value: newValue) }
    }

    /// Offset from UTC
    public var offsetFrom: String? {
        get { getPropertyValue(ICalPropertyName.timeZoneOffsetFrom) }
        set { setPropertyValue(ICalPropertyName.timeZoneOffsetFrom, value: newValue) }
    }

    /// Offset to UTC
    public var offsetTo: String? {
        get { getPropertyValue(ICalPropertyName.timeZoneOffsetTo) }
        set { setPropertyValue(ICalPropertyName.timeZoneOffsetTo, value: newValue) }
    }

    /// Time zone name
    public var timeZoneName: String? {
        get { getPropertyValue(ICalPropertyName.timeZoneName) }
        set { setPropertyValue(ICalPropertyName.timeZoneName, value: newValue) }
    }

    /// Recurrence rule
    public var recurrenceRule: ICalRecurrenceRule? {
        get { getRecurrenceRuleProperty(ICalPropertyName.recurrenceRule) }
        set { setRecurrenceRuleProperty(ICalPropertyName.recurrenceRule, value: newValue) }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = [], isStandard: Bool = true) {
        self.properties = properties
        self.components = components
        self.isStandard = isStandard
    }

    public init(properties: [ICalendarProperty], components: [any ICalendarComponent]) {
        self.properties = properties
        self.components = components
        self.isStandard = true
    }
}

// MARK: - Attendee/Organizer

/// Represents an attendee or organizer
public struct ICalAttendee: Sendable, Codable, Hashable {
    public let email: String
    public let commonName: String?
    public let role: ICalRole?
    public let participationStatus: ICalParticipationStatus?
    public let userType: ICalUserType?
    public let rsvp: Bool?
    public let delegatedFrom: String?
    public let delegatedTo: String?
    public let sentBy: String?
    public let directory: String?
    public let member: [String]?

    public init(
        email: String,
        commonName: String? = nil,
        role: ICalRole? = nil,
        participationStatus: ICalParticipationStatus? = nil,
        userType: ICalUserType? = nil,
        rsvp: Bool? = nil,
        delegatedFrom: String? = nil,
        delegatedTo: String? = nil,
        sentBy: String? = nil,
        directory: String? = nil,
        member: [String]? = nil
    ) {
        self.email = email
        self.commonName = commonName
        self.role = role
        self.participationStatus = participationStatus
        self.userType = userType
        self.rsvp = rsvp
        self.delegatedFrom = delegatedFrom
        self.delegatedTo = delegatedTo
        self.sentBy = sentBy
        self.directory = directory
        self.member = member
    }
}

// MARK: - Component Extensions for Property Access

extension ICalendarComponent {
    /// Get a property value by name
    public func getPropertyValue(_ name: String) -> String? {
        properties.first { $0.name == name }?.value
    }

    /// Set a property value
    public mutating func setPropertyValue(_ name: String, value: String?) {
        properties.removeAll { $0.name == name }
        if let value = value {
            properties.append(ICalProperty(name: name, value: value))
        }
    }

    /// Get a date-time property
    public func getDateTimeProperty(_ name: String) -> ICalDateTime? {
        guard let value = getPropertyValue(name) else { return nil }
        return ICalendarFormatter.parseDateTime(value)
    }

    /// Set a date-time property
    public mutating func setDateTimeProperty(_ name: String, value: ICalDateTime?) {
        guard let value = value else {
            setPropertyValue(name, value: nil)
            return
        }
        setPropertyValue(name, value: ICalendarFormatter.format(dateTime: value))
    }

    /// Get a duration property
    public func getDurationProperty(_ name: String) -> ICalDuration? {
        guard let value = getPropertyValue(name) else { return nil }
        return ICalendarFormatter.parseDuration(value)
    }

    /// Set a duration property
    public mutating func setDurationProperty(_ name: String, value: ICalDuration?) {
        guard let value = value else {
            setPropertyValue(name, value: nil)
            return
        }
        setPropertyValue(name, value: ICalendarFormatter.format(duration: value))
    }

    /// Get a recurrence rule property
    public func getRecurrenceRuleProperty(_ name: String) -> ICalRecurrenceRule? {
        guard let value = getPropertyValue(name) else { return nil }
        return ICalendarFormatter.parseRecurrenceRule(value)
    }

    /// Set a recurrence rule property
    public mutating func setRecurrenceRuleProperty(_ name: String, value: ICalRecurrenceRule?) {
        guard let value = value else {
            setPropertyValue(name, value: nil)
            return
        }
        setPropertyValue(name, value: ICalendarFormatter.format(recurrenceRule: value))
    }

    /// Get an attendee property
    public func getAttendeeProperty(_ name: String) -> ICalAttendee? {
        guard let property = properties.first(where: { $0.name == name }) else { return nil }
        return ICalendarFormatter.parseAttendee(property.value, parameters: property.parameters)
    }

    /// Set an attendee property
    public mutating func setAttendeeProperty(_ name: String, value: ICalAttendee?) {
        properties.removeAll { $0.name == name }
        if let value = value {
            let (valueString, parameters) = ICalendarFormatter.format(attendee: value)
            properties.append(ICalProperty(name: name, value: valueString, parameters: parameters))
        }
    }

    /// Get attendees properties
    public func getAttendeesProperty(_ name: String) -> [ICalAttendee] {
        properties.filter { $0.name == name }.compactMap { property in
            ICalendarFormatter.parseAttendee(property.value, parameters: property.parameters)
        }
    }

    /// Set attendees properties
    public mutating func setAttendeesProperty(_ name: String, values: [ICalAttendee]) {
        properties.removeAll { $0.name == name }
        for value in values {
            let (valueString, parameters) = ICalendarFormatter.format(attendee: value)
            properties.append(ICalProperty(name: name, value: valueString, parameters: parameters))
        }
    }

    /// Get categories property
    public func getCategoriesProperty() -> [String] {
        guard let value = getPropertyValue(ICalPropertyName.categories) else { return [] }
        return value.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    }

    /// Set categories property
    public mutating func setCategoriesProperty(_ categories: [String]) {
        if categories.isEmpty {
            setPropertyValue(ICalPropertyName.categories, value: nil)
        } else {
            setPropertyValue(ICalPropertyName.categories, value: categories.joined(separator: ","))
        }
    }
}
