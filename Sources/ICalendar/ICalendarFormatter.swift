import Foundation

/// Comprehensive formatter for iCalendar values following RFC 5545, RFC 5546, RFC 6868, RFC 7529, and RFC 7986
internal struct ICalendarFormatter {

    // MARK: - Date and Time Formatting

    private static let iso8601BasicFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let iso8601LocalFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static func format(dateTime: ICalDateTime) -> String {
        if dateTime.isDateOnly {
            return dateOnlyFormatter.string(from: dateTime.date)
        } else if dateTime.timeZone == nil || dateTime.timeZone?.identifier == "UTC" || dateTime.timeZone?.identifier == "GMT" {
            return iso8601BasicFormatter.string(from: dateTime.date)
        } else {
            iso8601LocalFormatter.timeZone = dateTime.timeZone
            return iso8601LocalFormatter.string(from: dateTime.date)
        }
    }

    static func parseDateTime(_ value: String, timeZone: TimeZone = .gmt) -> ICalDateTime? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for date-only format (YYYYMMDD) - timezone should be nil for date-only events
        if trimmedValue.count == 8, !trimmedValue.contains("T") {
            guard let date = dateOnlyFormatter.date(from: trimmedValue) else { return nil }
            return ICalDateTime(date: date, timeZone: nil, isDateOnly: true)
        }

        // Check for UTC format (YYYYMMDDTHHMMSSZ) - MUST use UTC timezone, not parameter
        if trimmedValue.hasSuffix("Z") {
            guard let date = iso8601BasicFormatter.date(from: trimmedValue) else { return nil }
            return ICalDateTime(date: date, timeZone: timeZone, isDateOnly: false)
        }

        // Local time format (YYYYMMDDTHHMMSS) - use provided timezone
        guard let date = iso8601LocalFormatter.date(from: trimmedValue) else { return nil }
        return ICalDateTime(date: date, timeZone: timeZone, isDateOnly: false)
    }

    // MARK: - Duration Formatting

    static func format(duration: ICalDuration) -> String {
        var result = duration.isNegative ? "-P" : "P"

        if duration.weeks > 0 {
            result += "\(duration.weeks)W"
        } else {
            if duration.days > 0 {
                result += "\(duration.days)D"
            }

            if duration.hours > 0 || duration.minutes > 0 || duration.seconds > 0 {
                result += "T"

                if duration.hours > 0 {
                    result += "\(duration.hours)H"
                }

                if duration.minutes > 0 {
                    result += "\(duration.minutes)M"
                }

                if duration.seconds > 0 {
                    result += "\(duration.seconds)S"
                }
            }
        }

        // Handle the case where duration is zero
        if result == "P" || result == "-P" {
            result += "T0S"
        }

        return result
    }

    static func parseDuration(_ value: String) -> ICalDuration? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }

        var isNegative = false
        var parseValue = trimmedValue

        // Check for negative duration
        if parseValue.hasPrefix("-") {
            isNegative = true
            parseValue = String(parseValue.dropFirst())
        }

        // Must start with P
        guard parseValue.hasPrefix("P") else { return nil }
        parseValue = String(parseValue.dropFirst())

        var weeks = 0
        var days = 0
        var hours = 0
        var minutes = 0
        var seconds = 0

        var inTimeSection = false
        var currentNumber = ""

        for char in parseValue {
            if char.isNumber {
                currentNumber += String(char)
            } else if char == "T" {
                inTimeSection = true
            } else if let number = Int(currentNumber) {
                switch char {
                case "W":
                    weeks = number
                case "D":
                    days = number
                case "H":
                    if inTimeSection {
                        hours = number
                    }
                case "M":
                    if inTimeSection {
                        minutes = number
                    }
                case "S":
                    if inTimeSection {
                        seconds = number
                    }
                default:
                    return nil
                }
                currentNumber = ""
            } else {
                return nil
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

    // MARK: - Recurrence Rule Formatting

    static func format(recurrenceRule: ICalRecurrenceRule) -> String {
        var parts: [String] = []

        parts.append("FREQ=\(recurrenceRule.frequency.rawValue)")

        if let interval = recurrenceRule.interval, interval > 1 {
            parts.append("INTERVAL=\(interval)")
        }

        if let count = recurrenceRule.count {
            parts.append("COUNT=\(count)")
        }

        if let until = recurrenceRule.until {
            parts.append("UNTIL=\(format(dateTime: until))")
        }

        if let bySecond = recurrenceRule.bySecond, !bySecond.isEmpty {
            parts.append("BYSECOND=\(bySecond.map(String.init).joined(separator: ","))")
        }

        if let byMinute = recurrenceRule.byMinute, !byMinute.isEmpty {
            parts.append("BYMINUTE=\(byMinute.map(String.init).joined(separator: ","))")
        }

        if let byHour = recurrenceRule.byHour, !byHour.isEmpty {
            parts.append("BYHOUR=\(byHour.map(String.init).joined(separator: ","))")
        }

        if let byDay = recurrenceRule.byDay, !byDay.isEmpty {
            parts.append("BYDAY=\(byDay.joined(separator: ","))")
        }

        if let byMonthDay = recurrenceRule.byMonthDay, !byMonthDay.isEmpty {
            parts.append("BYMONTHDAY=\(byMonthDay.map(String.init).joined(separator: ","))")
        }

        if let byYearDay = recurrenceRule.byYearDay, !byYearDay.isEmpty {
            parts.append("BYYEARDAY=\(byYearDay.map(String.init).joined(separator: ","))")
        }

        if let byWeekNo = recurrenceRule.byWeekNo, !byWeekNo.isEmpty {
            parts.append("BYWEEKNO=\(byWeekNo.map(String.init).joined(separator: ","))")
        }

        if let byMonth = recurrenceRule.byMonth, !byMonth.isEmpty {
            parts.append("BYMONTH=\(byMonth.map(String.init).joined(separator: ","))")
        }

        if let bySetPos = recurrenceRule.bySetPos, !bySetPos.isEmpty {
            parts.append("BYSETPOS=\(bySetPos.map(String.init).joined(separator: ","))")
        }

        if let weekStart = recurrenceRule.weekStart {
            parts.append("WKST=\(weekStart.rawValue)")
        }

        // RFC 7529: RSCALE parameter for non-Gregorian calendars
        if let rscale = recurrenceRule.rscale {
            parts.append("RSCALE=\(rscale.rawValue)")
        }

        return parts.joined(separator: ";")
    }

    static func parseRecurrenceRule(_ value: String) -> ICalRecurrenceRule? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmedValue.split(separator: ";")

        var frequency: ICalRecurrenceFrequency?
        var interval: Int?
        var count: Int?
        var until: ICalDateTime?
        var bySecond: [Int]?
        var byMinute: [Int]?
        var byHour: [Int]?
        var byDay: [String]?
        var byMonthDay: [Int]?
        var byYearDay: [Int]?
        var byWeekNo: [Int]?
        var byMonth: [Int]?
        var bySetPos: [Int]?
        var weekStart: ICalWeekday?
        var rscale: ICalRecurrenceScale?

        for part in parts {
            let keyValue = part.split(separator: "=", maxSplits: 1)
            guard keyValue.count == 2 else { continue }

            let key = String(keyValue[0])
            let val = String(keyValue[1])

            switch key {
            case "FREQ":
                frequency = ICalRecurrenceFrequency(rawValue: val)
            case "INTERVAL":
                interval = Int(val)
            case "COUNT":
                count = Int(val)
            case "UNTIL":
                until = parseDateTime(val)
            case "BYSECOND":
                bySecond = val.split(separator: ",").compactMap { Int($0) }
            case "BYMINUTE":
                byMinute = val.split(separator: ",").compactMap { Int($0) }
            case "BYHOUR":
                byHour = val.split(separator: ",").compactMap { Int($0) }
            case "BYDAY":
                byDay = val.split(separator: ",").map { String($0) }
            case "BYMONTHDAY":
                byMonthDay = val.split(separator: ",").compactMap { Int($0) }
            case "BYYEARDAY":
                byYearDay = val.split(separator: ",").compactMap { Int($0) }
            case "BYWEEKNO":
                byWeekNo = val.split(separator: ",").compactMap { Int($0) }
            case "BYMONTH":
                byMonth = val.split(separator: ",").compactMap { Int($0) }
            case "BYSETPOS":
                bySetPos = val.split(separator: ",").compactMap { Int($0) }
            case "WKST":
                weekStart = ICalWeekday(rawValue: val)
            case "RSCALE":
                rscale = ICalRecurrenceScale(rawValue: val)
            default:
                break
            }
        }

        guard let frequency = frequency else { return nil }

        return ICalRecurrenceRule(
            frequency: frequency,
            interval: interval,
            count: count,
            until: until,
            bySecond: bySecond,
            byMinute: byMinute,
            byHour: byHour,
            byDay: byDay,
            byMonthDay: byMonthDay,
            byYearDay: byYearDay,
            byWeekNo: byWeekNo,
            byMonth: byMonth,
            bySetPos: bySetPos,
            weekStart: weekStart,
            rscale: rscale
        )
    }

    // MARK: - Attendee Formatting

    static func parseAttendee(_ value: String, parameters: [String: String]) -> ICalAttendee? {
        // Extract email from value (usually in format "mailto:email@example.com")
        let email: String
        if value.hasPrefix("mailto:") {
            email = String(value.dropFirst(7))
        } else {
            email = value
        }

        guard !email.isEmpty else { return nil }

        let commonName = parameters[ICalParameterName.commonName]
        let role = parameters[ICalParameterName.role].flatMap { ICalRole(rawValue: $0) }
        let participationStatus = parameters[ICalParameterName.participationStatus].flatMap { ICalParticipationStatus(rawValue: $0) }
        let userType = parameters[ICalParameterName.calendarUserType].flatMap { ICalUserType(rawValue: $0) }
        let rsvp = parameters[ICalParameterName.rsvp].flatMap { Bool($0.uppercased()) }
        let delegatedFrom = parameters[ICalParameterName.delegatedFrom]
        let delegatedTo = parameters[ICalParameterName.delegatedTo]
        let sentBy = parameters[ICalParameterName.sentBy]
        let directory = parameters[ICalParameterName.directory]
        let member = parameters[ICalParameterName.member]?.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        return ICalAttendee(
            email: email,
            commonName: commonName,
            role: role,
            participationStatus: participationStatus,
            userType: userType,
            rsvp: rsvp,
            delegatedFrom: delegatedFrom,
            delegatedTo: delegatedTo,
            sentBy: sentBy,
            directory: directory,
            member: member
        )
    }

    static func format(attendee: ICalAttendee) -> (String, [String: String]) {
        let value = "mailto:\(attendee.email)"
        var parameters: [String: String] = [:]

        if let commonName = attendee.commonName {
            parameters[ICalParameterName.commonName] = commonName
        }

        if let role = attendee.role {
            parameters[ICalParameterName.role] = role.rawValue
        }

        if let participationStatus = attendee.participationStatus {
            parameters[ICalParameterName.participationStatus] = participationStatus.rawValue
        }

        if let userType = attendee.userType {
            parameters[ICalParameterName.calendarUserType] = userType.rawValue
        }

        if let rsvp = attendee.rsvp {
            parameters[ICalParameterName.rsvp] = rsvp ? "TRUE" : "FALSE"
        }

        if let delegatedFrom = attendee.delegatedFrom {
            parameters[ICalParameterName.delegatedFrom] = delegatedFrom
        }

        if let delegatedTo = attendee.delegatedTo {
            parameters[ICalParameterName.delegatedTo] = delegatedTo
        }

        if let sentBy = attendee.sentBy {
            parameters[ICalParameterName.sentBy] = sentBy
        }

        if let directory = attendee.directory {
            parameters[ICalParameterName.directory] = directory
        }

        if let member = attendee.member, !member.isEmpty {
            parameters[ICalParameterName.member] = member.joined(separator: ",")
        }

        return (value, parameters)
    }

    // MARK: - Text Escaping (RFC 5545 Section 3.3.11)

    static func escapeText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }

    static func unescapeText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\\\", with: "\\")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\N", with: "\n")
            .replacingOccurrences(of: "\\r", with: "\r")
            .replacingOccurrences(of: "\\R", with: "\r")
    }

    // MARK: - Parameter Value Escaping (RFC 6868)

    static func escapeParameterValue(_ value: String) -> String {
        value
            .replacingOccurrences(of: "^", with: "^^")
            .replacingOccurrences(of: "\n", with: "^n")
            .replacingOccurrences(of: "\r", with: "^r")
            .replacingOccurrences(of: "\"", with: "^'")
    }

    static func unescapeParameterValue(_ value: String) -> String {
        value
            .replacingOccurrences(of: "^n", with: "\n")
            .replacingOccurrences(of: "^r", with: "\r")
            .replacingOccurrences(of: "^'", with: "\"")
            .replacingOccurrences(of: "^^", with: "^")
    }

    // MARK: - Line Folding (RFC 5545 Section 3.1)

    static func foldLine(_ line: String, maxLength: Int = 75) -> String {
        guard line.count > maxLength else { return line }

        var result = ""
        var currentLine = line

        while currentLine.count > maxLength {
            let cutIndex = currentLine.index(currentLine.startIndex, offsetBy: maxLength)
            result += String(currentLine[..<cutIndex]) + "\r\n "
            currentLine = String(currentLine[cutIndex...])
        }

        result += currentLine
        return result
    }

    static func unfoldLines(_ text: String) -> String {
        text.replacingOccurrences(of: "\r\n ", with: "")
            .replacingOccurrences(of: "\r\n\t", with: "")
            .replacingOccurrences(of: "\n ", with: "")
            .replacingOccurrences(of: "\n\t", with: "")
    }

    // MARK: - Property Formatting

    static func formatProperty(_ property: ICalendarProperty) -> String {
        var line = property.name

        // Add parameters
        for (key, value) in property.parameters.sorted(by: { $0.key < $1.key }) {
            let escapedValue = escapeParameterValue(value)
            if escapedValue.contains(" ") || escapedValue.contains(":") || escapedValue.contains(";") || escapedValue.contains(",") {
                line += ";\(key)=\"\(escapedValue)\""
            } else {
                line += ";\(key)=\(escapedValue)"
            }
        }

        line += ":\(escapeText(property.value))"

        return foldLine(line)
    }

    static func parseProperty(_ line: String) -> ICalendarProperty? {
        let unfolded = unfoldLines(line).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !unfolded.isEmpty else { return nil }

        // Find the colon that separates property name/parameters from value
        guard let colonIndex = unfolded.firstIndex(of: ":") else { return nil }

        let nameAndParams = String(unfolded[..<colonIndex])
        let value = String(unfolded[unfolded.index(after: colonIndex)...])

        // Parse property name and parameters
        let parts = nameAndParams.split(separator: ";")
        guard let firstPart = parts.first else { return nil }

        let name = String(firstPart)
        var parameters: [String: String] = [:]

        for paramPart in parts.dropFirst() {
            let paramComponents = paramPart.split(separator: "=", maxSplits: 1)
            guard paramComponents.count == 2 else { continue }

            let paramName = String(paramComponents[0])
            var paramValue = String(paramComponents[1])

            // Remove quotes if present
            if paramValue.hasPrefix("\"") && paramValue.hasSuffix("\"") {
                paramValue = String(paramValue.dropFirst().dropLast())
            }

            parameters[paramName] = unescapeParameterValue(paramValue)
        }

        return ICalProperty(
            name: name,
            value: unescapeText(value),
            parameters: parameters
        )
    }

    // MARK: - UTC Offset Formatting

    static func formatUTCOffset(seconds: Int) -> String {
        let absSeconds = abs(seconds)
        let hours = absSeconds / 3600
        let minutes = (absSeconds % 3600) / 60
        let remainingSeconds = absSeconds % 60

        let sign = seconds >= 0 ? "+" : "-"

        if remainingSeconds == 0 {
            return String(format: "%@%02d%02d", sign, hours, minutes)
        } else {
            return String(format: "%@%02d%02d%02d", sign, hours, minutes, remainingSeconds)
        }
    }

    static func parseUTCOffset(_ value: String) -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 5 else { return nil }

        let sign: Int
        let offsetString: String

        if trimmed.hasPrefix("+") {
            sign = 1
            offsetString = String(trimmed.dropFirst())
        } else if trimmed.hasPrefix("-") {
            sign = -1
            offsetString = String(trimmed.dropFirst())
        } else {
            return nil
        }

        guard offsetString.count >= 4 else { return nil }

        let hoursString = String(offsetString.prefix(2))
        let minutesString = String(offsetString.dropFirst(2).prefix(2))

        guard let hours = Int(hoursString), let minutes = Int(minutesString) else {
            return nil
        }

        var totalSeconds = hours * 3600 + minutes * 60

        // Check for seconds component
        if offsetString.count >= 6 {
            let secondsString = String(offsetString.dropFirst(4).prefix(2))
            if let seconds = Int(secondsString) {
                totalSeconds += seconds
            }
        }

        return sign * totalSeconds
    }

    // MARK: - Base64 Encoding/Decoding (RFC 7986 IMAGE property support)

    /// Encode data as base64 string for BINARY image properties
    static func encodeBase64(_ data: Data) -> String {
        data.base64EncodedString()
    }

    /// Decode base64 string to data for BINARY image properties
    static func decodeBase64(_ string: String) -> Data? {
        Data(base64Encoded: string)
    }

    /// Create IMAGE property with binary data (base64 encoded)
    static func createBinaryImageProperty(_ data: Data, mediaType: String? = nil) -> ICalProperty {
        let base64String = encodeBase64(data)
        var parameters: [String: String] = [
            ICalParameterName.encoding: "BASE64",
            ICalParameterName.valueType: "BINARY",
        ]

        if let mediaType = mediaType {
            parameters[ICalParameterName.formatType] = mediaType
        }

        return ICalProperty(name: ICalPropertyName.image, value: base64String, parameters: parameters)
    }

    /// Create IMAGE property with URI reference
    static func createURIImageProperty(_ uri: String, mediaType: String? = nil) -> ICalProperty {
        var parameters: [String: String] = [
            ICalParameterName.valueType: "URI"
        ]

        if let mediaType = mediaType {
            parameters[ICalParameterName.formatType] = mediaType
        }

        return ICalProperty(name: ICalPropertyName.image, value: uri, parameters: parameters)
    }
}

extension Bool {
    init?(_ string: String) {
        switch string.uppercased() {
        case "TRUE", "YES", "1":
            self = true
        case "FALSE", "NO", "0":
            self = false
        default:
            return nil
        }
    }
}
