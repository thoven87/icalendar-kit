import Foundation

/// Serializer for vCard content following RFC-6350 specifications with Swift 6 structured concurrency
public struct VCardSerializer: Sendable {

    // MARK: - Serialization Options

    public struct SerializationOptions: Sendable {
        public let lineLength: Int
        public let sortProperties: Bool
        public let includeOptionalProperties: Bool
        public let validateBeforeSerializing: Bool
        public let version: VCardVersion

        public init(
            lineLength: Int = 75,
            sortProperties: Bool = true,
            includeOptionalProperties: Bool = true,
            validateBeforeSerializing: Bool = true,
            version: VCardVersion = .v4_0
        ) {
            self.lineLength = lineLength
            self.sortProperties = sortProperties
            self.includeOptionalProperties = includeOptionalProperties
            self.validateBeforeSerializing = validateBeforeSerializing
            self.version = version
        }

        public static let `default` = SerializationOptions()
        public static let compact = SerializationOptions(
            lineLength: 75,
            sortProperties: false,
            includeOptionalProperties: false,
            validateBeforeSerializing: false
        )
    }

    private let options: SerializationOptions

    public init(options: SerializationOptions = .default) {
        self.options = options
    }

    // MARK: - Public Interface

    /// Serialize vCard to string
    public func serialize(_ vcard: VCard) throws -> String {
        if options.validateBeforeSerializing {
            let parser = VCardParser()
            try parser.validate(vcard)
        }

        return serializeVCard(vcard)
    }

    /// Serialize vCard to data
    public func serializeToData(_ vcard: VCard) throws -> Data {
        let content = try serialize(vcard)
        guard let data = content.data(using: String.Encoding.utf8) else {
            throw VCardError.encodingError("Failed to encode vCard as UTF-8")
        }
        return data
    }

    /// Serialize vCard to file
    public func serializeToFile(_ vcard: VCard, url: URL) throws {
        let data = try serializeToData(vcard)
        try data.write(to: url)
    }

    /// Serialize multiple vCards
    public func serialize(_ vcards: [VCard]) throws -> String {
        var results: [String] = []

        for vcard in vcards {
            let serialized = try serialize(vcard)
            results.append(serialized)
        }

        return results.joined(separator: "\r\n")
    }

    // MARK: - Core Serialization

    private func serializeVCard(_ vcard: VCard) -> String {
        var lines: [String] = []

        // BEGIN line
        lines.append("BEGIN:VCARD")

        // Ensure VERSION property is first
        lines.append(formatProperty(VProperty(name: VCardPropertyName.version, value: options.version.rawValue)))

        // Properties (excluding VERSION as it's already added)
        let properties =
            options.sortProperties
            ? vcard.properties.filter { $0.name != VCardPropertyName.version }.sorted { $0.name < $1.name }
            : vcard.properties.filter { $0.name != VCardPropertyName.version }

        for property in properties {
            if options.includeOptionalProperties || isRequiredProperty(property.name) {
                lines.append(formatProperty(property))
            }
        }

        // END line
        lines.append("END:VCARD")

        return lines.joined(separator: "\r\n") + "\r\n"
    }

    // MARK: - Property Formatting

    private func formatProperty(_ property: VCardProperty) -> String {
        var line = property.name

        // Add parameters
        let parameters =
            options.sortProperties
            ? property.parameters.sorted { $0.key < $1.key }
            : Array(property.parameters)

        for (key, value) in parameters {
            // Don't escape TYPE parameter values for structured properties
            if key == VCardParameterName.type && (property.name == VCardPropertyName.telephone || property.name == VCardPropertyName.address) {
                line += ";\(key)=\(value)"
            } else {
                let escapedValue = VCardFormatter.escapeParameterValue(value)
                line += ";\(key)=\(escapedValue)"
            }
        }

        // Don't escape values for structured properties like N and ADR
        if property.name == VCardPropertyName.name || property.name == VCardPropertyName.address {
            line += ":\(property.value)"
        } else {
            line += ":\(VCardFormatter.escapeText(property.value))"
        }

        return VCardFormatter.foldLine(line, maxLength: options.lineLength)
    }

    // MARK: - Required Property Checking

    private func isRequiredProperty(_ propertyName: String) -> Bool {
        switch propertyName.uppercased() {
        case VCardPropertyName.version, VCardPropertyName.formattedName:
            return true
        default:
            return false
        }
    }

    // MARK: - Specialized Serialization Methods

    /// Serialize for specific vCard version
    public func serialize(_ vcard: VCard, version: VCardVersion) throws -> String {
        let versionOptions = SerializationOptions(
            lineLength: options.lineLength,
            sortProperties: options.sortProperties,
            includeOptionalProperties: options.includeOptionalProperties,
            validateBeforeSerializing: options.validateBeforeSerializing,
            version: version
        )

        let versionSerializer = VCardSerializer(options: versionOptions)
        return try versionSerializer.serialize(vcard)
    }

    /// Serialize with minimal properties only
    public func serializeMinimal(_ vcard: VCard) throws -> String {
        let minimalOptions = SerializationOptions(
            lineLength: options.lineLength,
            sortProperties: options.sortProperties,
            includeOptionalProperties: false,
            validateBeforeSerializing: false,
            version: options.version
        )

        let minimalSerializer = VCardSerializer(options: minimalOptions)
        return try minimalSerializer.serialize(vcard)
    }

    /// Serialize for Apple Contacts compatibility
    public func serializeForApple(_ vcard: VCard) -> String {
        var lines: [String] = []

        lines.append("BEGIN:VCARD")
        lines.append("VERSION:3.0")

        // Apple Contacts prefers specific property order
        let propertyOrder = [
            VCardPropertyName.formattedName,
            VCardPropertyName.name,
            VCardPropertyName.organization,
            VCardPropertyName.title,
            VCardPropertyName.telephone,
            VCardPropertyName.email,
            VCardPropertyName.address,
            VCardPropertyName.url,
            VCardPropertyName.birthday,
            VCardPropertyName.note,
        ]

        // Add properties in preferred order
        for propertyName in propertyOrder {
            let properties = vcard.properties.filter { $0.name == propertyName }
            for property in properties {
                lines.append(formatPropertyForApple(property))
            }
        }

        // Add remaining properties
        let addedPropertyNames = Set(propertyOrder)
        let remainingProperties = vcard.properties.filter { !addedPropertyNames.contains($0.name) && $0.name != VCardPropertyName.version }
        for property in remainingProperties {
            lines.append(formatPropertyForApple(property))
        }

        lines.append("END:VCARD")

        return lines.joined(separator: "\r\n")
    }

    private func formatPropertyForApple(_ property: VCardProperty) -> String {
        // Apple Contacts has specific formatting preferences
        var line = property.name

        // Handle Apple-specific parameter formatting
        for (key, value) in property.parameters.sorted(by: { $0.key < $1.key }) {
            if key == VCardParameterName.type {
                // Apple prefers TYPE without quotes
                line += ";\(key)=\(value)"
            } else {
                let escapedValue = VCardFormatter.escapeParameterValue(value)
                line += ";\(key)=\(escapedValue)"
            }
        }

        // Don't escape values for structured properties like N and ADR
        if property.name == VCardPropertyName.name || property.name == VCardPropertyName.address {
            line += ":\(property.value)"
        } else {
            line += ":\(VCardFormatter.escapeText(property.value))"
        }

        return VCardFormatter.foldLine(line, maxLength: 75)
    }

    /// Serialize for Google Contacts compatibility
    public func serializeForGoogle(_ vcard: VCard) -> String {
        var lines: [String] = []

        lines.append("BEGIN:VCARD")
        lines.append("VERSION:3.0")

        // Google Contacts specific handling
        let properties = vcard.properties.filter { $0.name != VCardPropertyName.version }

        for property in properties {
            lines.append(formatPropertyForGoogle(property))
        }

        lines.append("END:VCARD")

        return lines.joined(separator: "\r\n")
    }

    private func formatPropertyForGoogle(_ property: VCardProperty) -> String {
        var line = property.name

        // Google-specific parameter handling
        for (key, value) in property.parameters.sorted(by: { $0.key < $1.key }) {
            let escapedValue = VCardFormatter.escapeParameterValue(value)
            line += ";\(key)=\(escapedValue)"
        }

        line += ":\(VCardFormatter.escapeText(property.value))"

        return VCardFormatter.foldLine(line, maxLength: 75)
    }

    /// Serialize for Outlook compatibility
    public func serializeForOutlook(_ vcard: VCard) -> String {
        var lines: [String] = []

        lines.append("BEGIN:VCARD")
        lines.append("VERSION:2.1")  // Outlook prefers 2.1

        // Outlook-specific property handling
        let properties = vcard.properties.filter { $0.name != VCardPropertyName.version }

        for property in properties {
            lines.append(formatPropertyForOutlook(property))
        }

        lines.append("END:VCARD")

        return lines.joined(separator: "\r\n")
    }

    private func formatPropertyForOutlook(_ property: VCardProperty) -> String {
        // Outlook has different formatting requirements
        var line = property.name

        // Outlook-specific parameter formatting
        for (key, value) in property.parameters.sorted(by: { $0.key < $1.key }) {
            if key == VCardParameterName.encoding && value == "BASE64" {
                line += ";\(key)=\(value)"
            } else {
                let escapedValue = VCardFormatter.escapeParameterValue(value)
                line += ";\(key)=\(escapedValue)"
            }
        }

        line += ":\(VCardFormatter.escapeText(property.value))"

        return VCardFormatter.foldLine(line, maxLength: 75)
    }

    // MARK: - Pretty Printing

    /// Serialize with human-readable formatting
    public func serializePretty(_ vcard: VCard) -> String {
        let prettyOptions = SerializationOptions(
            lineLength: 120,  // Longer lines for readability
            sortProperties: true,
            includeOptionalProperties: true,
            validateBeforeSerializing: false,
            version: options.version
        )

        let prettySerializer = VCardSerializer(options: prettyOptions)
        let content = try! prettySerializer.serialize(vcard)

        // Add extra spacing for readability
        return
            content
            .replacingOccurrences(of: "\r\n", with: "\r\n")
    }

    // MARK: - Statistics and Analysis

    /// Get serialization statistics
    public func getStatistics(_ vcard: VCard) -> SerializationStatistics {
        let content = try! serialize(vcard)
        let lines = content.components(separatedBy: CharacterSet.newlines)

        return SerializationStatistics(
            totalLines: lines.count,
            totalCharacters: content.count,
            propertyCount: vcard.properties.count,
            emailCount: vcard.emails.count,
            telephoneCount: vcard.telephones.count,
            addressCount: vcard.addresses.count,
            urlCount: vcard.urls.count,
            averageLineLength: lines.isEmpty ? 0 : content.count / lines.count
        )
    }
}

// MARK: - Serialization Statistics

public struct SerializationStatistics: Sendable {
    public let totalLines: Int
    public let totalCharacters: Int
    public let propertyCount: Int
    public let emailCount: Int
    public let telephoneCount: Int
    public let addressCount: Int
    public let urlCount: Int
    public let averageLineLength: Int

    public var description: String {
        """
        vCard Serialization Statistics:
        - Total Lines: \(totalLines)
        - Total Characters: \(totalCharacters)
        - Properties: \(propertyCount)
        - Email Addresses: \(emailCount)
        - Telephone Numbers: \(telephoneCount)
        - Addresses: \(addressCount)
        - URLs: \(urlCount)
        - Average Line Length: \(averageLineLength)
        """
    }
}

// MARK: - Convenience Extensions

extension VCardSerializer {

    /// Quick serialize to string
    public static func serialize(_ vcard: VCard) throws -> String {
        let serializer = VCardSerializer()
        return try serializer.serialize(vcard)
    }

    /// Quick serialize to data
    public static func serializeToData(_ vcard: VCard) throws -> Data {
        let serializer = VCardSerializer()
        return try serializer.serializeToData(vcard)
    }

    /// Serialize with custom line ending
    public func serialize(_ vcard: VCard, lineEnding: String) throws -> String {
        let content = try serialize(vcard)
        return content.replacingOccurrences(of: "\r\n", with: lineEnding)
    }
}

extension CharacterSet {
    static let newlines = CharacterSet.newlines
}
