import Foundation

/// Comprehensive formatter for vCard values following RFC-6350
internal struct VCardFormatter {

    // MARK: - Date and Time Formatting

    private static let iso8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // MARK: - Name Formatting

    static func format(name: VCardName) -> String {
        let components = [
            name.familyNames.joined(separator: " "),
            name.givenNames.joined(separator: " "),
            name.additionalNames.joined(separator: " "),
            name.honorificPrefixes.joined(separator: " "),
            name.honorificSuffixes.joined(separator: " "),
        ]
        return components.joined(separator: ";")
    }

    static func parseName(_ value: String) -> VCardName? {
        let components = value.split(separator: ";", maxSplits: 4, omittingEmptySubsequences: false)

        let familyNames = components.count > 0 ? String(components[0]).split(separator: " ").map(String.init).filter { !$0.isEmpty } : []
        let givenNames = components.count > 1 ? String(components[1]).split(separator: " ").map(String.init).filter { !$0.isEmpty } : []
        let additionalNames = components.count > 2 ? String(components[2]).split(separator: " ").map(String.init).filter { !$0.isEmpty } : []
        let honorificPrefixes = components.count > 3 ? String(components[3]).split(separator: " ").map(String.init).filter { !$0.isEmpty } : []
        let honorificSuffixes = components.count > 4 ? String(components[4]).split(separator: " ").map(String.init).filter { !$0.isEmpty } : []

        return VCardName(
            familyNames: familyNames,
            givenNames: givenNames,
            additionalNames: additionalNames,
            honorificPrefixes: honorificPrefixes,
            honorificSuffixes: honorificSuffixes
        )
    }

    // MARK: - Address Formatting

    static func format(address: VCardAddress) -> String {
        let components = [
            address.postOfficeBox ?? "",
            address.extendedAddress ?? "",
            address.streetAddress ?? "",
            address.locality ?? "",
            address.region ?? "",
            address.postalCode ?? "",
            address.countryName ?? "",
        ]
        return components.joined(separator: ";")
    }

    static func parseAddress(_ value: String) -> VCardAddress? {
        let components = value.split(separator: ";", maxSplits: 6, omittingEmptySubsequences: false)

        return VCardAddress(
            postOfficeBox: components.count > 0 && !components[0].isEmpty ? String(components[0]) : nil,
            extendedAddress: components.count > 1 && !components[1].isEmpty ? String(components[1]) : nil,
            streetAddress: components.count > 2 && !components[2].isEmpty ? String(components[2]) : nil,
            locality: components.count > 3 && !components[3].isEmpty ? String(components[3]) : nil,
            region: components.count > 4 && !components[4].isEmpty ? String(components[4]) : nil,
            postalCode: components.count > 5 && !components[5].isEmpty ? String(components[5]) : nil,
            countryName: components.count > 6 && !components[6].isEmpty ? String(components[6]) : nil
        )
    }

    // MARK: - Geographical Formatting

    static func format(geo: VCardGeo) -> String {
        "geo:\(geo.latitude),\(geo.longitude)"
    }

    static func parseGeo(_ value: String) -> VCardGeo? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle geo: URI format
        if trimmed.hasPrefix("geo:") {
            let coords = String(trimmed.dropFirst(4))
            let components = coords.split(separator: ",")
            guard components.count >= 2,
                let lat = Double(components[0]),
                let lon = Double(components[1])
            else {
                return nil
            }
            return VCardGeo(latitude: lat, longitude: lon)
        }

        // Handle simple lat,lon format
        let components = trimmed.split(separator: ",")
        guard components.count >= 2,
            let lat = Double(components[0]),
            let lon = Double(components[1])
        else {
            return nil
        }
        return VCardGeo(latitude: lat, longitude: lon)
    }

    // MARK: - Organization Formatting

    static func format(organization: VCardOrganization) -> String {
        if organization.organizationalUnits.isEmpty {
            return organization.organizationName
        } else {
            return ([organization.organizationName] + organization.organizationalUnits).joined(separator: ";")
        }
    }

    static func parseOrganization(_ value: String) -> VCardOrganization? {
        let components = value.split(separator: ";", omittingEmptySubsequences: false)
        guard !components.isEmpty else { return nil }

        let organizationName = String(components[0])
        let organizationalUnits = components.dropFirst().map(String.init).filter { !$0.isEmpty }

        return VCardOrganization(
            organizationName: organizationName,
            organizationalUnits: organizationalUnits
        )
    }

    // MARK: - Date Formatting

    static func format(date: VCardDate) -> String {
        var result = ""

        if let year = date.year {
            result += String(format: "%04d", year)
        } else {
            result += "----"
        }

        if let month = date.month {
            result += String(format: "-%02d", month)
        } else {
            result += "--"
        }

        if let day = date.day {
            result += String(format: "-%02d", day)
        } else {
            result += "--"
        }

        return result
    }

    static func parseDate(_ value: String) -> VCardDate? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle YYYY---- format (partial year only)
        if trimmed.hasSuffix("----") && trimmed.count == 8 {
            let yearStr = String(trimmed.prefix(4))
            if let year = Int(yearStr), yearStr.count == 4 {
                return VCardDate(year: year, month: nil, day: nil)
            }
        }

        // Handle YYYY-MM-- format (year and month)
        if trimmed.hasSuffix("--") && trimmed.count == 9 && trimmed.contains("-") {
            // Use regex pattern matching instead of split for YYYY-MM-- format
            let pattern = "^(\\d{4})-(\\d{2})--$"
            if let regex = try? NSRegularExpression(pattern: pattern),
                let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed))
            {
                if let yearRange = Range(match.range(at: 1), in: trimmed),
                    let monthRange = Range(match.range(at: 2), in: trimmed)
                {
                    let yearStr = String(trimmed[yearRange])
                    let monthStr = String(trimmed[monthRange])
                    if let year = Int(yearStr), let month = Int(monthStr) {
                        return VCardDate(year: year, month: month, day: nil)
                    }
                }
            }
        }

        // Handle partial date formats with dashes
        if trimmed.contains("-") {
            let components = trimmed.split(separator: "-", omittingEmptySubsequences: false)

            // Handle full date format YYYY-MM-DD
            if components.count == 3 && !components[2].isEmpty && components[2] != "--" {
                let yearStr = String(components[0])
                let monthStr = String(components[1])
                let dayStr = String(components[2])

                // Reject 2-digit years (like "90-12-25")
                guard yearStr.count == 4 else { return nil }

                if let year = Int(yearStr), let month = Int(monthStr), let day = Int(dayStr) {
                    return VCardDate(year: year, month: month, day: day)
                }
            }
        }

        // Handle YYYYMMDD format
        if trimmed.count == 8 && trimmed.allSatisfy(\.isNumber) {
            let yearStr = String(trimmed.prefix(4))
            let monthStr = String(trimmed.dropFirst(4).prefix(2))
            let dayStr = String(trimmed.dropFirst(6))

            guard let year = Int(yearStr),
                let month = Int(monthStr),
                let day = Int(dayStr)
            else {
                return nil
            }

            return VCardDate(year: year, month: month, day: day)
        }

        // Handle other date formats
        if let foundationDate = dateFormatter.date(from: trimmed) {
            return VCardDate(date: foundationDate)
        }

        return nil
    }

    // MARK: - Timestamp Formatting

    static func format(timestamp: Date) -> String {
        iso8601Formatter.string(from: timestamp)
    }

    static func parseTimestamp(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try ISO 8601 format first
        if let date = iso8601Formatter.date(from: trimmed) {
            return date
        }

        // Try basic date format
        if let date = dateFormatter.date(from: trimmed) {
            return date
        }

        // Try parsing as timestamp
        if let timestamp = TimeInterval(trimmed) {
            return Date(timeIntervalSince1970: timestamp)
        }

        return nil
    }

    // MARK: - Text Escaping (RFC-6350 Section 3.4)

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

    // MARK: - Parameter Value Escaping

    static func escapeParameterValue(_ value: String) -> String {
        // RFC-6350 parameter values that contain special characters should be quoted
        // Exception: TYPE parameters with comma-separated values don't need quotes
        if value.contains(":") || value.contains(";") || value.contains(" ") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\\\""))\""
        }
        return value
    }

    static func unescapeParameterValue(_ value: String) -> String {
        var result = value

        // Remove quotes if present
        if result.hasPrefix("\"") && result.hasSuffix("\"") {
            result = String(result.dropFirst().dropLast())
        }

        return result.replacingOccurrences(of: "\\\"", with: "\"")
    }

    // MARK: - Line Folding (RFC-6350 Section 3.2)

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

    static func formatProperty(_ property: VCardProperty) -> String {
        var line = property.name

        // Add parameters
        for (key, value) in property.parameters.sorted(by: { $0.key < $1.key }) {
            let escapedValue = escapeParameterValue(value)
            line += ";\(key)=\(escapedValue)"
        }

        line += ":\(escapeText(property.value))"

        return foldLine(line)
    }

    static func parseProperty(_ line: String) -> VCardProperty? {
        let unfolded = unfoldLines(line).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !unfolded.isEmpty else { return nil }

        // Find the colon that separates property name/parameters from value
        guard let colonIndex = unfolded.firstIndex(of: ":") else { return nil }

        let nameAndParams = String(unfolded[..<colonIndex])
        let value = String(unfolded[unfolded.index(after: colonIndex)...])

        // Parse property name and parameters
        let parts = nameAndParams.split(separator: ";")
        guard let firstPart = parts.first else { return nil }

        let name = String(firstPart).uppercased()
        var parameters: [String: String] = [:]

        for paramPart in parts.dropFirst() {
            let paramComponents = paramPart.split(separator: "=", maxSplits: 1)
            guard paramComponents.count == 2 else { continue }

            let paramName = String(paramComponents[0]).uppercased()
            let paramValue = unescapeParameterValue(String(paramComponents[1]))

            parameters[paramName] = paramValue
        }

        return VProperty(
            name: name,
            value: unescapeText(value),
            parameters: parameters
        )
    }

    // MARK: - Base64 Encoding/Decoding

    static func encodeBase64(_ data: Data) -> String {
        data.base64EncodedString()
    }

    static func decodeBase64(_ string: String) -> Data? {
        Data(base64Encoded: string)
    }

    // MARK: - URI Validation

    static func isValidURI(_ uri: String) -> Bool {
        guard let url = URL(string: uri) else { return false }
        return url.scheme != nil
    }

    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    static func isValidTelephone(_ telephone: String) -> Bool {
        let cleanedPhone = telephone.replacingOccurrences(of: "[^0-9+\\-\\(\\)\\s]", with: "", options: .regularExpression)
        return !cleanedPhone.isEmpty && cleanedPhone.count >= 3
    }

    // MARK: - Language Tag Validation

    static func isValidLanguageTag(_ tag: String) -> Bool {
        let languageRegex = "^[a-zA-Z]{2,3}(-[a-zA-Z0-9]{2,8})*$"
        return tag.range(of: languageRegex, options: .regularExpression) != nil
    }

    // MARK: - Media Type Validation

    static func isValidMediaType(_ mediaType: String) -> Bool {
        let mediaTypeRegex = "^[a-zA-Z][a-zA-Z0-9]*\\/[a-zA-Z0-9][a-zA-Z0-9!#$&\\-\\^_]*$"
        return mediaType.range(of: mediaTypeRegex, options: .regularExpression) != nil
    }

    // MARK: - Structured Value Helpers

    static func parseStructuredValue(_ value: String, separator: Character = ";") -> [String] {
        value.split(separator: separator, omittingEmptySubsequences: false).map(String.init)
    }

    static func formatStructuredValue(_ components: [String], separator: Character = ";") -> String {
        components.joined(separator: String(separator))
    }

    static func parseListValue(_ value: String, separator: Character = ",") -> [String] {
        value.split(separator: separator).map { String($0).trimmingCharacters(in: .whitespaces) }
    }

    static func formatListValue(_ items: [String], separator: Character = ",") -> String {
        items.joined(separator: String(separator))
    }
}
