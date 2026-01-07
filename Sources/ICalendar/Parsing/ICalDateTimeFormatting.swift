import Foundation

// MARK: - Date-Time Formatting

extension ICalDateTime {
    /// Formats the date-time for iCalendar property values
    func formatForProperty() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        switch precision {
        case .date:
            formatter.dateFormat = "yyyyMMdd"
            formatter.timeZone = TimeZone(identifier: "UTC")
            return formatter.string(from: date)

        case .dateTime:
            formatter.dateFormat = "yyyyMMdd'T'HHmmss"
            formatter.timeZone = TimeZone(identifier: "UTC")  // Use UTC for floating time
            return formatter.string(from: date)

        case .dateTimeUtc:
            formatter.timeZone = TimeZone(identifier: "UTC")
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            return formatter.string(from: date)

        case .dateTimeZoned:
            formatter.dateFormat = "yyyyMMdd'T'HHmmss"
            formatter.timeZone = timeZone ?? TimeZone(identifier: "UTC")
            return formatter.string(from: date)
        }
    }

    /// Creates ICalDateTime from RFC 5545 formatted string
    static func from(_ value: String, timeZoneId: String? = nil) -> ICalDateTime? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        // DATE format: YYYYMMDD
        if value.count == 8, value.allSatisfy(\.isNumber) {
            formatter.dateFormat = "yyyyMMdd"
            formatter.timeZone = TimeZone(identifier: "UTC")
            guard let date = formatter.date(from: value) else { return nil }
            return ICalDateTime(date: date, timeZone: nil, isDateOnly: true)
        }

        // DATE-TIME with Z (UTC): YYYYMMDDTHHMMSSZ
        if value.hasSuffix("Z") && value.count == 16 {
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            formatter.timeZone = TimeZone(identifier: "UTC")
            guard let date = formatter.date(from: value) else { return nil }
            return ICalDateTime(date: date, timeZone: TimeZone(identifier: "UTC"))
        }

        // DATE-TIME local: YYYYMMDDTHHMMSS
        if value.contains("T") && value.count == 15 {
            formatter.dateFormat = "yyyyMMdd'T'HHmmss"

            if let tzid = timeZoneId, let timeZone = TimeZone(identifier: tzid) {
                formatter.timeZone = timeZone
                guard let date = formatter.date(from: value) else { return nil }
                return ICalDateTime(date: date, timeZone: timeZone)
            } else {
                // Floating time - no timezone specified, use UTC for parsing
                formatter.timeZone = TimeZone(identifier: "UTC")
                guard let date = formatter.date(from: value) else { return nil }
                return ICalDateTime(date: date, timeZone: nil)
            }
        }

        return nil
    }
}

// MARK: - Duration Formatting

extension ICalDuration {
    /// Formats the duration for iCalendar property values
    func formatForProperty() -> String {
        var result = isNegative ? "-P" : "P"

        // Add weeks if present
        if weeks > 0 {
            result += "\(weeks)W"
            return result  // RFC 5545: If weeks are specified, no other components should be present
        }

        // Add days
        if days > 0 {
            result += "\(days)D"
        }

        // Add time component if any time units are present
        if hours > 0 || minutes > 0 || seconds > 0 {
            result += "T"

            if hours > 0 {
                result += "\(hours)H"
            }

            if minutes > 0 {
                result += "\(minutes)M"
            }

            if seconds > 0 {
                result += "\(seconds)S"
            }
        }

        // If no components, return P0D
        if result == "P" || result == "-P" {
            return isNegative ? "-P0D" : "P0D"
        }

        return result
    }

    /// Creates ICalDuration from RFC 5545 formatted string
    static func from(_ value: String) -> ICalDuration? {
        guard value.hasPrefix("P") || value.hasPrefix("-P") else { return nil }

        let isNegative = value.hasPrefix("-")
        let durationString = isNegative ? String(value.dropFirst(2)) : String(value.dropFirst())

        var weeks = 0
        var days = 0
        var hours = 0
        var minutes = 0
        var seconds = 0

        var currentNumber = ""
        var inTimeSection = false

        for char in durationString {
            if char.isNumber {
                currentNumber += String(char)
            } else {
                switch char {
                case "T":
                    // T separator doesn't consume a number
                    inTimeSection = true
                case "W":
                    guard let number = Int(currentNumber) else { return nil }
                    weeks = number
                    currentNumber = ""
                case "D":
                    guard let number = Int(currentNumber) else { return nil }
                    days = number
                    currentNumber = ""
                case "H":
                    guard inTimeSection else { return nil }
                    guard let number = Int(currentNumber) else { return nil }
                    hours = number
                    currentNumber = ""
                case "M":
                    if inTimeSection {
                        guard let number = Int(currentNumber) else { return nil }
                        minutes = number
                        currentNumber = ""
                    } else {
                        // Month - not supported in DURATION
                        return nil
                    }
                case "S":
                    guard inTimeSection else { return nil }
                    guard let number = Int(currentNumber) else { return nil }
                    seconds = number
                    currentNumber = ""
                default:
                    return nil
                }
            }
        }

        return ICalDuration(
            weeks: weeks,
            days: days,
            hours: hours,
            minutes: minutes,
            seconds: seconds,
            isNegative: isNegative
        )
    }
}

// MARK: - Recurrence Rule Formatting

extension ICalRecurrenceRule {
    /// Formats the recurrence rule for iCalendar property values
    func formatForProperty() -> String {
        var parts: [String] = []

        // FREQ is required
        parts.append("FREQ=\(frequency.rawValue)")

        // UNTIL and COUNT are mutually exclusive
        if let until = until {
            parts.append("UNTIL=\(until.formatForProperty())")
        } else if let count = count {
            parts.append("COUNT=\(count)")
        }

        // INTERVAL
        if interval != 1 {
            parts.append("INTERVAL=\(interval)")
        }

        // BY rules
        if !bySecond.isEmpty {
            parts.append("BYSECOND=\(bySecond.map(String.init).joined(separator: ","))")
        }

        if !byMinute.isEmpty {
            parts.append("BYMINUTE=\(byMinute.map(String.init).joined(separator: ","))")
        }

        if !byHour.isEmpty {
            parts.append("BYHOUR=\(byHour.map(String.init).joined(separator: ","))")
        }

        if !byWeekday.isEmpty {
            parts.append("BYDAY=\(byWeekday.map(\.rawValue).joined(separator: ","))")
        }

        if !byMonthday.isEmpty {
            parts.append("BYMONTHDAY=\(byMonthday.map(String.init).joined(separator: ","))")
        }

        if !byYearday.isEmpty {
            parts.append("BYYEARDAY=\(byYearday.map(String.init).joined(separator: ","))")
        }

        if !byWeekno.isEmpty {
            parts.append("BYWEEKNO=\(byWeekno.map(String.init).joined(separator: ","))")
        }

        if !byMonth.isEmpty {
            parts.append("BYMONTH=\(byMonth.map(String.init).joined(separator: ","))")
        }

        if !bySetpos.isEmpty {
            parts.append("BYSETPOS=\(bySetpos.map(String.init).joined(separator: ","))")
        }

        // WKST
        if weekStart != .monday {
            parts.append("WKST=\(weekStart.rawValue)")
        }

        return parts.joined(separator: ";")
    }

    /// Creates ICalRecurrenceRule from RFC 5545 formatted string
    static func from(_ value: String) -> ICalRecurrenceRule? {
        let parts = value.split(separator: ";")
        var frequency: ICalRecurrenceFrequency?
        var until: ICalDateTime?
        var count: Int?
        var interval = 1
        var bySecond: [Int] = []
        var byMinute: [Int] = []
        var byHour: [Int] = []
        var byWeekday: [ICalWeekday] = []
        var byMonthday: [Int] = []
        var byYearday: [Int] = []
        var byWeekno: [Int] = []
        var byMonth: [Int] = []
        var bySetpos: [Int] = []
        var weekStart = ICalWeekday.monday

        for part in parts {
            let keyValue = part.split(separator: "=", maxSplits: 1)
            guard keyValue.count == 2 else { continue }

            let key = String(keyValue[0])
            let valueString = String(keyValue[1])

            switch key {
            case "FREQ":
                frequency = ICalRecurrenceFrequency(rawValue: valueString)

            case "UNTIL":
                until = ICalDateTime.from(valueString)

            case "COUNT":
                count = Int(valueString)

            case "INTERVAL":
                interval = Int(valueString) ?? 1

            case "BYSECOND":
                bySecond = parseIntList(valueString)

            case "BYMINUTE":
                byMinute = parseIntList(valueString)

            case "BYHOUR":
                byHour = parseIntList(valueString)

            case "BYDAY":
                byWeekday = parseWeekdayList(valueString)

            case "BYMONTHDAY":
                byMonthday = parseIntList(valueString)

            case "BYYEARDAY":
                byYearday = parseIntList(valueString)

            case "BYWEEKNO":
                byWeekno = parseIntList(valueString)

            case "BYMONTH":
                byMonth = parseIntList(valueString)

            case "BYSETPOS":
                bySetpos = parseIntList(valueString)

            case "WKST":
                weekStart = ICalWeekday(rawValue: valueString) ?? .monday

            default:
                // Ignore unknown parameters
                break
            }
        }

        guard let freq = frequency else { return nil }

        return ICalRecurrenceRule(
            frequency: freq,
            until: until,
            count: count,
            interval: interval,
            bySecond: bySecond,
            byMinute: byMinute,
            byHour: byHour,
            byWeekday: byWeekday,
            byMonthday: byMonthday,
            byYearday: byYearday,
            byWeekno: byWeekno,
            byMonth: byMonth,
            bySetpos: bySetpos,
            weekStart: weekStart
        )
    }

    // MARK: - Private Helpers

    private static func parseIntList(_ value: String) -> [Int] {
        value.split(separator: ",").compactMap { Int(String($0)) }
    }

    private static func parseWeekdayList(_ value: String) -> [ICalWeekday] {
        value.split(separator: ",").compactMap { part in
            let weekdayString = String(part)
            // Handle prefixed numbers like "1MO", "2TU", etc.
            if weekdayString.count > 2 {
                let suffix = String(weekdayString.suffix(2))
                return ICalWeekday(rawValue: suffix)
            } else {
                return ICalWeekday(rawValue: weekdayString)
            }
        }
    }
}

// MARK: - Parser Implementations

internal struct ICalDateTimeParser {
    static func parse(_ value: String, timeZoneId: String? = nil) -> ICalDateTime? {
        ICalDateTime.from(value, timeZoneId: timeZoneId)
    }
}

internal struct ICalDurationParser {
    static func parse(_ value: String) -> ICalDuration? {
        ICalDuration.from(value)
    }
}

internal struct ICalRecurrenceRuleParser {
    static func parse(_ value: String) -> ICalRecurrenceRule? {
        ICalRecurrenceRule.from(value)
    }
}

internal struct ICalDateTimeListParser {
    static func parse(_ value: String, timeZoneId: String? = nil) -> [ICalDateTime] {
        let dateStrings = value.split(separator: ",")
        return dateStrings.compactMap { dateString in
            ICalDateTime.from(String(dateString), timeZoneId: timeZoneId)
        }
    }
}
