import Foundation

// MARK: - Recurrence Types

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

    /// Foundation Calendar weekday equivalent
    public var foundationWeekday: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
}

/// Calendar scale for recurrence rules (RFC 7529)
public enum ICalRecurrenceScale: String, Sendable, CaseIterable, Codable {
    case gregorian = "GREGORIAN"
    case hebrew = "HEBREW"
    case islamic = "ISLAMIC"
    case chinese = "CHINESE"
    case buddhist = "BUDDHIST"
    case japanese = "JAPANESE"
    case persian = "PERSIAN"
    case indian = "INDIAN"
    case coptic = "COPTIC"
    case ethiopic = "ETHIOPIC"

    /// Convert to Foundation Calendar.Identifier
    public var foundationIdentifier: Calendar.Identifier {
        switch self {
        case .gregorian: return .gregorian
        case .hebrew: return .hebrew
        case .islamic: return .islamic
        case .chinese: return .chinese
        case .buddhist: return .buddhist
        case .japanese: return .japanese
        case .persian: return .persian
        case .indian: return .indian
        case .coptic: return .coptic
        case .ethiopic: return .ethiopicAmeteAlem
        }
    }
}

/// Represents a complete recurrence rule
public struct ICalRecurrenceRule: Sendable, Codable, Hashable {
    public let frequency: ICalRecurrenceFrequency
    public let until: ICalDateTime?
    public let count: Int?
    public let interval: Int
    public let bySecond: [Int]
    public let byMinute: [Int]
    public let byHour: [Int]
    public let byWeekday: [ICalWeekday]
    public let byMonthday: [Int]
    public let byYearday: [Int]
    public let byWeekno: [Int]
    public let byMonth: [Int]
    public let bySetpos: [Int]
    public let weekStart: ICalWeekday
    public let recurrenceScale: ICalRecurrenceScale

    /// Backward compatibility alias for recurrenceScale
    public var rscale: ICalRecurrenceScale {
        recurrenceScale
    }

    public init(
        frequency: ICalRecurrenceFrequency,
        until: ICalDateTime? = nil,
        count: Int? = nil,
        interval: Int = 1,
        bySecond: [Int] = [],
        byMinute: [Int] = [],
        byHour: [Int] = [],
        byWeekday: [ICalWeekday] = [],
        byMonthday: [Int] = [],
        byYearday: [Int] = [],
        byWeekno: [Int] = [],
        byMonth: [Int] = [],
        bySetpos: [Int] = [],
        weekStart: ICalWeekday = .monday,
        recurrenceScale: ICalRecurrenceScale = .gregorian
    ) {
        self.frequency = frequency
        self.until = until
        self.count = count
        self.interval = interval
        self.bySecond = bySecond
        self.byMinute = byMinute
        self.byHour = byHour
        self.byWeekday = byWeekday
        self.byMonthday = byMonthday
        self.byYearday = byYearday
        self.byWeekno = byWeekno
        self.byMonth = byMonth
        self.bySetpos = bySetpos
        self.weekStart = weekStart
        self.recurrenceScale = recurrenceScale
    }
}
