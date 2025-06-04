import Foundation

// MARK: - Core Protocol Definitions

/// Base protocol for all iCalendar components that can be parsed and serialized
public protocol ICalendarComponent: Sendable {
    /// The component name (e.g., "VEVENT", "VTODO", "VJOURNAL")
    static var componentName: String { get }

    /// Properties associated with this component
    var properties: [ICalendarProperty] { get set }

    /// Sub-components contained within this component
    var components: [any ICalendarComponent] { get set }

    /// Initialize from properties and components
    init(properties: [ICalendarProperty], components: [any ICalendarComponent])
}

/// Protocol for properties that can appear in iCalendar components
public protocol ICalendarProperty: Sendable {
    /// The property name (e.g., "DTSTART", "SUMMARY", "DESCRIPTION")
    var name: String { get }

    /// The property value
    var value: String { get }

    /// Property parameters (e.g., TZID, VALUE, LANGUAGE)
    var parameters: [String: String] { get }

    /// Initialize with name, value, and parameters
    init(name: String, value: String, parameters: [String: String])
}

/// Protocol for parameter encoding/decoding
public protocol ICalendarParameter: Sendable {
    /// Parameter name
    var name: String { get }

    /// Parameter value
    var value: String { get }
}

// MARK: - Core Data Types

/// Represents an iCalendar property with name, value, and parameters
public struct ICalProperty: ICalendarProperty {
    public let name: String
    public let value: String
    public let parameters: [String: String]

    public init(name: String, value: String, parameters: [String: String] = [:]) {
        self.name = name
        self.value = value
        self.parameters = parameters
    }
}

/// Represents an iCalendar parameter
public struct ICalParameter: ICalendarParameter {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

// MARK: - Value Types

/// Represents different iCalendar value types
public enum ICalendarValueType: String, Sendable, CaseIterable, Codable {
    case binary = "BINARY"
    case boolean = "BOOLEAN"
    case calendarAddress = "CAL-ADDRESS"
    case date = "DATE"
    case dateTime = "DATE-TIME"
    case duration = "DURATION"
    case float = "FLOAT"
    case integer = "INTEGER"
    case period = "PERIOD"
    case recur = "RECUR"
    case text = "TEXT"
    case time = "TIME"
    case uri = "URI"
    case utcOffset = "UTC-OFFSET"
}

/// Represents an iCalendar date-time value
public struct ICalDateTime: Sendable, Codable, Hashable {
    public let date: Date
    public let timeZone: TimeZone?
    public let isDateOnly: Bool

    public init(date: Date, timeZone: TimeZone? = nil, isDateOnly: Bool = false) {
        self.date = date
        self.timeZone = timeZone
        self.isDateOnly = isDateOnly
    }
}

/// Represents an iCalendar duration
public struct ICalDuration: Sendable, Codable, Hashable {
    public let weeks: Int
    public let days: Int
    public let hours: Int
    public let minutes: Int
    public let seconds: Int
    public let isNegative: Bool

    public init(weeks: Int = 0, days: Int = 0, hours: Int = 0, minutes: Int = 0, seconds: Int = 0, isNegative: Bool = false) {
        self.weeks = weeks
        self.days = days
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.isNegative = isNegative
    }

    /// Total duration in seconds
    public var totalSeconds: TimeInterval {
        let total = Double(weeks * 7 * 24 * 3600 + days * 24 * 3600 + hours * 3600 + minutes * 60 + seconds)
        return isNegative ? -total : total
    }
}

/// Represents an iCalendar period
public struct ICalPeriod: Sendable, Codable, Hashable {
    public let start: ICalDateTime
    public let end: ICalDateTime?
    public let duration: ICalDuration?

    public init(start: ICalDateTime, end: ICalDateTime) {
        self.start = start
        self.end = end
        self.duration = nil
    }

    public init(start: ICalDateTime, duration: ICalDuration) {
        self.start = start
        self.end = nil
        self.duration = duration
    }
}

/// Represents recurrence rule frequency
public enum ICalRecurrenceFrequency: String, Sendable, CaseIterable, Codable {
    case secondly = "SECONDLY"
    case minutely = "MINUTELY"
    case hourly = "HOURLY"
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case yearly = "YEARLY"
}

/// Represents weekday values for recurrence rules
public enum ICalWeekday: String, Sendable, CaseIterable, Codable {
    case sunday = "SU"
    case monday = "MO"
    case tuesday = "TU"
    case wednesday = "WE"
    case thursday = "TH"
    case friday = "FR"
    case saturday = "SA"
}

/// Represents a recurrence rule
public struct ICalRecurrenceRule: Sendable, Codable, Hashable {
    public let frequency: ICalRecurrenceFrequency
    public let interval: Int?
    public let count: Int?
    public let until: ICalDateTime?
    public let bySecond: [Int]?
    public let byMinute: [Int]?
    public let byHour: [Int]?
    public let byDay: [String]?  // Can include ordinals like "2MO"
    public let byMonthDay: [Int]?
    public let byYearDay: [Int]?
    public let byWeekNo: [Int]?
    public let byMonth: [Int]?
    public let bySetPos: [Int]?
    public let weekStart: ICalWeekday?

    public init(
        frequency: ICalRecurrenceFrequency,
        interval: Int? = nil,
        count: Int? = nil,
        until: ICalDateTime? = nil,
        bySecond: [Int]? = nil,
        byMinute: [Int]? = nil,
        byHour: [Int]? = nil,
        byDay: [String]? = nil,
        byMonthDay: [Int]? = nil,
        byYearDay: [Int]? = nil,
        byWeekNo: [Int]? = nil,
        byMonth: [Int]? = nil,
        bySetPos: [Int]? = nil,
        weekStart: ICalWeekday? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.count = count
        self.until = until
        self.bySecond = bySecond
        self.byMinute = byMinute
        self.byHour = byHour
        self.byDay = byDay
        self.byMonthDay = byMonthDay
        self.byYearDay = byYearDay
        self.byWeekNo = byWeekNo
        self.byMonth = byMonth
        self.bySetPos = bySetPos
        self.weekStart = weekStart
    }
}

// MARK: - Status and Classification Types

/// Event status values
public enum ICalEventStatus: String, Sendable, CaseIterable, Codable {
    case tentative = "TENTATIVE"
    case confirmed = "CONFIRMED"
    case cancelled = "CANCELLED"
}

/// To-do status values
public enum ICalTodoStatus: String, Sendable, CaseIterable, Codable {
    case needsAction = "NEEDS-ACTION"
    case completed = "COMPLETED"
    case inProcess = "IN-PROCESS"
    case cancelled = "CANCELLED"
}

/// Journal status values
public enum ICalJournalStatus: String, Sendable, CaseIterable, Codable {
    case draft = "DRAFT"
    case final = "FINAL"
    case cancelled = "CANCELLED"
}

/// Classification values
public enum ICalClassification: String, Sendable, CaseIterable, Codable {
    case publicAccess = "PUBLIC"
    case privateAccess = "PRIVATE"
    case confidential = "CONFIDENTIAL"
}

/// Transparency values for events
public enum ICalTransparency: String, Sendable, CaseIterable, Codable {
    case opaque = "OPAQUE"
    case transparent = "TRANSPARENT"
}

// MARK: - Participant and Role Types

/// Calendar user type
public enum ICalUserType: String, Sendable, CaseIterable, Codable {
    case individual = "INDIVIDUAL"
    case group = "GROUP"
    case resource = "RESOURCE"
    case room = "ROOM"
    case unknown = "UNKNOWN"
}

/// Participation role
public enum ICalRole: String, Sendable, CaseIterable, Codable {
    case chair = "CHAIR"
    case requiredParticipant = "REQ-PARTICIPANT"
    case optionalParticipant = "OPT-PARTICIPANT"
    case nonParticipant = "NON-PARTICIPANT"
}

/// Participation status
public enum ICalParticipationStatus: String, Sendable, CaseIterable, Codable {
    case needsAction = "NEEDS-ACTION"
    case accepted = "ACCEPTED"
    case declined = "DECLINED"
    case tentative = "TENTATIVE"
    case delegated = "DELEGATED"
    case completed = "COMPLETED"
    case inProcess = "IN-PROCESS"
}

/// Relationship type
public enum ICalRelationshipType: String, Sendable, CaseIterable, Codable {
    case parent = "PARENT"
    case child = "CHILD"
    case sibling = "SIBLING"
}

// MARK: - Error Types

/// Errors that can occur during iCalendar parsing or creation
public enum ICalendarError: Error, Sendable {
    case invalidFormat(String)
    case missingRequiredProperty(String)
    case invalidPropertyValue(property: String, value: String)
    case invalidDateFormat(String)
    case invalidDuration(String)
    case invalidRecurrenceRule(String)
    case unsupportedComponent(String)
    case encodingError(String)
    case decodingError(String)
    case invalidParameterValue(parameter: String, value: String)
}

// MARK: - Constants

/// Common iCalendar property names
public struct ICalPropertyName {
    public static let version = "VERSION"
    public static let productId = "PRODID"
    public static let calendarScale = "CALSCALE"
    public static let method = "METHOD"

    // Event properties
    public static let uid = "UID"
    public static let dateTimeStamp = "DTSTAMP"
    public static let dateTimeStart = "DTSTART"
    public static let dateTimeEnd = "DTEND"
    public static let duration = "DURATION"
    public static let summary = "SUMMARY"
    public static let description = "DESCRIPTION"
    public static let location = "LOCATION"
    public static let status = "STATUS"
    public static let transparency = "TRANSP"
    public static let classification = "CLASS"
    public static let priority = "PRIORITY"
    public static let sequence = "SEQUENCE"
    public static let recurrenceRule = "RRULE"
    public static let recurrenceId = "RECURRENCE-ID"
    public static let exceptionDates = "EXDATE"
    public static let recurrenceDates = "RDATE"
    public static let organizer = "ORGANIZER"
    public static let attendee = "ATTENDEE"
    public static let categories = "CATEGORIES"
    public static let comment = "COMMENT"
    public static let contact = "CONTACT"
    public static let relatedTo = "RELATED-TO"
    public static let url = "URL"
    public static let attach = "ATTACH"
    public static let alarm = "VALARM"
    public static let created = "CREATED"
    public static let lastModified = "LAST-MODIFIED"

    // Alarm properties
    public static let action = "ACTION"
    public static let trigger = "TRIGGER"
    public static let repeatCount = "REPEAT"

    // Time zone properties
    public static let timeZoneId = "TZID"
    public static let timeZoneName = "TZNAME"
    public static let timeZoneOffsetFrom = "TZOFFSETFROM"
    public static let timeZoneOffsetTo = "TZOFFSETTO"
    public static let timeZoneUrl = "TZURL"
}

/// Common iCalendar parameter names
public struct ICalParameterName {
    public static let alternateRepresentation = "ALTREP"
    public static let commonName = "CN"
    public static let calendarUserType = "CUTYPE"
    public static let delegatedFrom = "DELEGATED-FROM"
    public static let delegatedTo = "DELEGATED-TO"
    public static let directory = "DIR"
    public static let encoding = "ENCODING"
    public static let formatType = "FMTYPE"
    public static let freeBusyType = "FBTYPE"
    public static let language = "LANGUAGE"
    public static let member = "MEMBER"
    public static let participationStatus = "PARTSTAT"
    public static let range = "RANGE"
    public static let related = "RELATED"
    public static let relationshipType = "RELTYPE"
    public static let role = "ROLE"
    public static let rsvp = "RSVP"
    public static let sentBy = "SENT-BY"
    public static let timeZoneId = "TZID"
    public static let valueType = "VALUE"
}
