import Foundation

/// Parser for vCard content following RFC-6350 specifications with Swift 6 structured concurrency
public struct VCardParser: Sendable {

    // MARK: - Parsing State

    private enum ParsingState {
        case idle
        case inVCard
    }

    // MARK: - Public Interface

    /// Parse vCard content from string
    public func parse(_ content: String) throws -> VCard {
        let lines = preprocessLines(content)
        return try parseLines(lines)
    }

    /// Parse vCard content from data
    public func parse(_ data: Data) throws -> VCard {
        guard let content = String(data: data, encoding: .utf8) else {
            throw VCardError.decodingError("Unable to decode data as UTF-8")
        }
        return try parse(content)
    }

    /// Parse vCard file from URL
    public func parseFile(at url: URL) throws -> VCard {
        let data = try Data(contentsOf: url)
        return try parse(data)
    }

    // MARK: - Line Preprocessing

    private func preprocessLines(_ content: String) -> [String] {
        // Unfold lines according to RFC-6350 Section 3.2
        let unfolded = VCardFormatter.unfoldLines(content)

        // Split into lines and filter empty ones
        return unfolded.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Core Parsing Logic

    private func parseLines(_ lines: [String]) throws -> VCard {
        var vcard: VCard?
        var currentProperties: [VCardProperty] = []
        var state: ParsingState = .idle

        for line in lines {
            if line.hasPrefix("BEGIN:") {
                let componentName = String(line.dropFirst(6))

                if componentName == "VCARD" {
                    guard state == .idle else {
                        throw VCardError.invalidFormat("Nested VCARD components are not allowed")
                    }
                    state = .inVCard
                } else {
                    throw VCardError.invalidFormat("Unknown component: \(componentName)")
                }

            } else if line.hasPrefix("END:") {
                let componentName = String(line.dropFirst(4))

                if componentName == "VCARD" {
                    guard state == .inVCard else {
                        throw VCardError.invalidFormat("END:VCARD without matching BEGIN:VCARD")
                    }

                    vcard = VCard(properties: currentProperties)
                    currentProperties = []
                    state = .idle
                } else {
                    throw VCardError.invalidFormat("Unknown component end: \(componentName)")
                }

            } else {
                // Parse property
                guard state == .inVCard else {
                    throw VCardError.invalidFormat("Property outside of VCARD component: \(line)")
                }

                guard let property = VCardFormatter.parseProperty(line) else {
                    throw VCardError.invalidFormat("Invalid property format: \(line)")
                }
                currentProperties.append(property)
            }
        }

        guard let result = vcard else {
            throw VCardError.invalidFormat("No VCARD component found")
        }

        return result
    }

    // MARK: - Validation

    /// Validate parsed vCard for RFC compliance
    public func validate(_ vcard: VCard) throws {
        // Check required properties
        guard vcard.version == .v4_0 || vcard.version == .v3_0 else {
            throw VCardError.invalidVersion("Unsupported version: \(vcard.version.rawValue)")
        }

        guard vcard.formattedName != nil else {
            throw VCardError.missingRequiredProperty("FN")
        }

        // Validate property values
        try validateProperties(vcard)
    }

    private func validateProperties(_ vcard: VCard) throws {
        // Validate email addresses
        for email in vcard.emails {
            guard VCardFormatter.isValidEmail(email.value) else {
                throw VCardError.invalidPropertyValue(property: "EMAIL", value: email.value)
            }
        }

        // Validate URLs
        for url in vcard.urls {
            guard VCardFormatter.isValidURI(url) else {
                throw VCardError.invalidPropertyValue(property: "URL", value: url)
            }
        }

        // Validate telephone numbers
        for telephone in vcard.telephones {
            guard VCardFormatter.isValidTelephone(telephone.value) else {
                throw VCardError.invalidPropertyValue(property: "TEL", value: telephone.value)
            }
        }

        // Validate language tags
        for language in vcard.languages {
            guard VCardFormatter.isValidLanguageTag(language.tag) else {
                throw VCardError.invalidPropertyValue(property: "LANG", value: language.tag)
            }
        }

        // Validate UID format if present
        if let uid = vcard.uid {
            guard !uid.isEmpty else {
                throw VCardError.invalidPropertyValue(property: "UID", value: uid)
            }
        }

        // Validate revision date format if present
        if let _ = vcard.revision {
            // Already validated during parsing
        }

        // Validate geo coordinates if present
        if let geo = vcard.geo {
            guard geo.latitude >= -90 && geo.latitude <= 90 else {
                throw VCardError.invalidPropertyValue(property: "GEO", value: "Invalid latitude: \(geo.latitude)")
            }
            guard geo.longitude >= -180 && geo.longitude <= 180 else {
                throw VCardError.invalidPropertyValue(property: "GEO", value: "Invalid longitude: \(geo.longitude)")
            }
        }

        // Validate birthday/anniversary dates if present
        if let birthday = vcard.birthday {
            try validateDate(birthday, propertyName: "BDAY")
        }

        if let anniversary = vcard.anniversary {
            try validateDate(anniversary, propertyName: "ANNIVERSARY")
        }
    }

    private func validateDate(_ date: VCardDate, propertyName: String) throws {
        // Validate date components
        if let year = date.year {
            guard year > 0 && year <= 9999 else {
                throw VCardError.invalidPropertyValue(property: propertyName, value: "Invalid year: \(year)")
            }
        }

        if let month = date.month {
            guard month >= 1 && month <= 12 else {
                throw VCardError.invalidPropertyValue(property: propertyName, value: "Invalid month: \(month)")
            }
        }

        if let day = date.day {
            guard day >= 1 && day <= 31 else {
                throw VCardError.invalidPropertyValue(property: propertyName, value: "Invalid day: \(day)")
            }
        }
    }

    // MARK: - Multiple vCard Parsing

    /// Parse multiple vCards from a string containing multiple VCARD objects
    public func parseMultiple(_ content: String) throws -> [VCard] {
        let lines = preprocessLines(content)
        var vcards: [VCard] = []
        var currentVCardLines: [String] = []
        var inVCard = false

        for line in lines {
            if line.hasPrefix("BEGIN:VCARD") {
                guard !inVCard else {
                    throw VCardError.invalidFormat("Nested VCARD components are not allowed")
                }
                inVCard = true
                currentVCardLines.append(line)
            } else if line.hasPrefix("END:VCARD") {
                currentVCardLines.append(line)

                let vcard = try parseLines(currentVCardLines)
                vcards.append(vcard)
                currentVCardLines = []
                inVCard = false
            } else if inVCard {
                currentVCardLines.append(line)
            } else {
                throw VCardError.invalidFormat("Property outside of VCARD component: \(line)")
            }
        }

        if inVCard {
            throw VCardError.invalidFormat("Incomplete VCARD component")
        }

        return vcards
    }

    // MARK: - Convenience Extensions

    /// Parse and validate in one operation
    public func parseAndValidate(_ content: String) throws -> VCard {
        let vcard = try parse(content)
        try validate(vcard)
        return vcard
    }

    /// Parse with custom validation
    public func parse(_ content: String, customValidation: @Sendable (VCard) throws -> Void) throws -> VCard {
        let vcard = try parse(content)
        try customValidation(vcard)
        return vcard
    }

    // MARK: - Property Extraction Helpers

    /// Extract all properties of a specific type
    public func extractProperties(_ vcard: VCard, ofType type: String) -> [VCardProperty] {
        vcard.properties.filter { $0.name.uppercased() == type.uppercased() }
    }

    /// Extract properties with specific parameters
    public func extractProperties(_ vcard: VCard, withParameter paramName: String, value: String) -> [VCardProperty] {
        vcard.properties.filter { property in
            property.parameters[paramName.uppercased()]?.uppercased() == value.uppercased()
        }
    }

    /// Get preferred property of a type (highest preference value)
    public func getPreferredProperty(_ vcard: VCard, ofType type: String) -> VCardProperty? {
        let properties = extractProperties(vcard, ofType: type)

        return properties.min { lhs, rhs in
            let lhsPref = lhs.parameters[VCardParameterName.preference].flatMap { Int($0) } ?? 100
            let rhsPref = rhs.parameters[VCardParameterName.preference].flatMap { Int($0) } ?? 100
            return lhsPref < rhsPref
        }
    }

    // MARK: - Statistics and Analysis

    /// Get parsing statistics for a vCard
    public func getStatistics(_ vcard: VCard) -> VCardStatistics {
        let propertyCount = vcard.properties.count
        let emailCount = vcard.emails.count
        let telephoneCount = vcard.telephones.count
        let addressCount = vcard.addresses.count
        let urlCount = vcard.urls.count
        let languageCount = vcard.languages.count

        let hasPhoto = vcard.photo != nil
        let hasBirthday = vcard.birthday != nil
        let hasOrganization = vcard.organization != nil
        let hasGeo = vcard.geo != nil

        let propertyTypes = Set(vcard.properties.map { $0.name })

        return VCardStatistics(
            version: vcard.version,
            propertyCount: propertyCount,
            emailCount: emailCount,
            telephoneCount: telephoneCount,
            addressCount: addressCount,
            urlCount: urlCount,
            languageCount: languageCount,
            hasPhoto: hasPhoto,
            hasBirthday: hasBirthday,
            hasOrganization: hasOrganization,
            hasGeo: hasGeo,
            propertyTypes: propertyTypes
        )
    }
}

// MARK: - Statistics Structure

public struct VCardStatistics: Sendable {
    public let version: VCardVersion
    public let propertyCount: Int
    public let emailCount: Int
    public let telephoneCount: Int
    public let addressCount: Int
    public let urlCount: Int
    public let languageCount: Int
    public let hasPhoto: Bool
    public let hasBirthday: Bool
    public let hasOrganization: Bool
    public let hasGeo: Bool
    public let propertyTypes: Set<String>

    public var description: String {
        """
        vCard Statistics (Version \(version.rawValue)):
        - Total Properties: \(propertyCount)
        - Email Addresses: \(emailCount)
        - Telephone Numbers: \(telephoneCount)
        - Addresses: \(addressCount)
        - URLs: \(urlCount)
        - Languages: \(languageCount)
        - Has Photo: \(hasPhoto)
        - Has Birthday: \(hasBirthday)
        - Has Organization: \(hasOrganization)
        - Has Geographic Info: \(hasGeo)
        - Property Types: \(propertyTypes.sorted().joined(separator: ", "))
        """
    }
}
