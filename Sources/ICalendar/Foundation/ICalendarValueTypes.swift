import Foundation

// MARK: - Value Types

/// Represents different iCalendar value types
public enum ICalValueType: String, Sendable, CaseIterable, Codable {
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

/// Represents an iCalendar date-time value with Swift 6.1 strict concurrency
public struct ICalDateTime: Sendable, Codable, Hashable {
    public let date: Date
    public let timeZone: TimeZone?
    public let isDateOnly: Bool
    public let precision: DateTimePrecision

    public enum DateTimePrecision: Sendable, Codable {
        case date  // 19970714
        case dateTime  // 19970714T173000
        case dateTimeUtc  // 19970714T173000Z
        case dateTimeZoned  // 19970714T173000 with TZID
    }

    public init(date: Date, timeZone: TimeZone? = nil, isDateOnly: Bool = false) {
        self.date = date
        self.timeZone = timeZone
        self.isDateOnly = isDateOnly

        if isDateOnly {
            self.precision = .date
        } else if let tz = timeZone, tz.identifier == "UTC" || tz.identifier == "GMT" {
            self.precision = .dateTimeUtc  // Explicit UTC timezone
        } else if timeZone == nil {
            self.precision = .dateTime  // Floating time (no timezone, no Z)
        } else {
            self.precision = .dateTimeZoned  // Specific timezone
        }
    }

    /// Whether this date-time requires a TZID parameter
    public var requiresTZIDParameter: Bool {
        !isDateOnly && precision == .dateTimeZoned && timeZone != nil
    }

    /// Whether this is a UTC time
    public var isUTC: Bool {
        precision == .dateTimeUtc || timeZone?.identifier == "UTC"
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

    /// Creates duration from TimeInterval
    public init(timeInterval: TimeInterval) {
        let absInterval = abs(timeInterval)
        let totalSeconds = Int(absInterval)

        let weeks = totalSeconds / (7 * 24 * 3600)
        let remainingAfterWeeks = totalSeconds % (7 * 24 * 3600)

        let days = remainingAfterWeeks / (24 * 3600)
        let remainingAfterDays = remainingAfterWeeks % (24 * 3600)

        let hours = remainingAfterDays / 3600
        let remainingAfterHours = remainingAfterDays % 3600

        let minutes = remainingAfterHours / 60
        let seconds = remainingAfterHours % 60

        self.init(
            weeks: weeks,
            days: days,
            hours: hours,
            minutes: minutes,
            seconds: seconds,
            isNegative: timeInterval < 0
        )
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

    /// Computed end date when using duration
    public var computedEnd: Date? {
        if let end = end {
            return end.date
        } else if let duration = duration {
            return start.date.addingTimeInterval(duration.totalSeconds)
        }
        return nil
    }
}
