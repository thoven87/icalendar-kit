import Foundation

/// Main vCard client providing high-level interface for parsing and creating vCards
/// Following RFC-6350 with Swift 6 sendable conformance and structured concurrency
public struct VCardClient: Sendable {

    // MARK: - Configuration

    public struct Configuration: Sendable {
        public let defaultVersion: VCardVersion
        public let validateOnParse: Bool
        public let validateOnSerialize: Bool
        public let enableExtensions: Bool

        public init(
            defaultVersion: VCardVersion = .v4_0,
            validateOnParse: Bool = true,
            validateOnSerialize: Bool = true,
            enableExtensions: Bool = true
        ) {
            self.defaultVersion = defaultVersion
            self.validateOnParse = validateOnParse
            self.validateOnSerialize = validateOnSerialize
            self.enableExtensions = enableExtensions
        }

        public static let `default` = Configuration()
        public static let strict = Configuration(
            validateOnParse: true,
            validateOnSerialize: true,
            enableExtensions: false
        )
        public static let permissive = Configuration(
            validateOnParse: false,
            validateOnSerialize: false,
            enableExtensions: true
        )
    }

    private let configuration: Configuration

    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    // MARK: - Parsing Operations

    /// Parse vCard content from string
    public func parseVCard(from content: String) async throws -> VCard {
        let parser = VCardParser()

        if configuration.validateOnParse {
            return try await parser.parseAndValidate(content)
        } else {
            return try await parser.parse(content)
        }
    }

    /// Parse vCard content from data
    public func parseVCard(from data: Data) async throws -> VCard {
        let parser = VCardParser()

        if configuration.validateOnParse {
            let vcard = try await parser.parse(data)
            try await parser.validate(vcard)
            return vcard
        } else {
            return try await parser.parse(data)
        }
    }

    /// Parse vCard file from URL
    public func parseVCard(from url: URL) async throws -> VCard {
        let parser = VCardParser()

        if configuration.validateOnParse {
            let vcard = try await parser.parseFile(at: url)
            try await parser.validate(vcard)
            return vcard
        } else {
            return try await parser.parseFile(at: url)
        }
    }

    /// Parse multiple vCards from content
    public func parseVCards(from content: String) async throws -> [VCard] {
        let parser = VCardParser()
        let vcards = try await parser.parseMultiple(content)

        if configuration.validateOnParse {
            for vcard in vcards {
                try await parser.validate(vcard)
            }
        }

        return vcards
    }

    // MARK: - Serialization Operations

    /// Serialize vCard to string
    public func serializeVCard(_ vcard: VCard) async throws -> String {
        let serializer = VCardSerializer(
            options: VCardSerializer.SerializationOptions(
                validateBeforeSerializing: configuration.validateOnSerialize,
                version: configuration.defaultVersion
            )
        )
        return try await serializer.serialize(vcard)
    }

    /// Serialize vCard to data
    public func serializeVCard(_ vcard: VCard) async throws -> Data {
        let serializer = VCardSerializer(
            options: VCardSerializer.SerializationOptions(
                validateBeforeSerializing: configuration.validateOnSerialize,
                version: configuration.defaultVersion
            )
        )
        return try await serializer.serializeToData(vcard)
    }

    /// Serialize vCard to file
    public func serializeVCard(_ vcard: VCard, to url: URL) async throws {
        let serializer = VCardSerializer(
            options: VCardSerializer.SerializationOptions(
                validateBeforeSerializing: configuration.validateOnSerialize,
                version: configuration.defaultVersion
            )
        )
        try await serializer.serializeToFile(vcard, url: url)
    }

    /// Serialize multiple vCards
    public func serializeVCards(_ vcards: [VCard]) async throws -> String {
        let serializer = VCardSerializer(
            options: VCardSerializer.SerializationOptions(
                validateBeforeSerializing: configuration.validateOnSerialize,
                version: configuration.defaultVersion
            )
        )
        return try await serializer.serialize(vcards)
    }

    // MARK: - vCard Creation

    /// Create a new vCard with formatted name
    public func createVCard(formattedName: String, version: VCardVersion? = nil) -> VCard {
        VCard(
            formattedName: formattedName,
            version: version ?? configuration.defaultVersion
        )
    }

    /// Create a vCard for a person
    public func createPersonVCard(
        formattedName: String,
        familyName: String? = nil,
        givenName: String? = nil,
        middleName: String? = nil,
        prefix: String? = nil,
        suffix: String? = nil
    ) -> VCard {
        var vcard = createVCard(formattedName: formattedName)

        if familyName != nil || givenName != nil || middleName != nil || prefix != nil || suffix != nil {
            vcard.name = VCardName(
                familyNames: familyName.map { [$0] } ?? [],
                givenNames: givenName.map { [$0] } ?? [],
                additionalNames: middleName.map { [$0] } ?? [],
                honorificPrefixes: prefix.map { [$0] } ?? [],
                honorificSuffixes: suffix.map { [$0] } ?? []
            )
        }

        vcard.kind = VCardKind.individual
        return vcard
    }

    /// Create a vCard for an organization
    public func createOrganizationVCard(
        organizationName: String,
        organizationalUnits: [String] = []
    ) -> VCard {
        var vcard = createVCard(formattedName: organizationName)
        vcard.organization = VCardOrganization(
            organizationName: organizationName,
            organizationalUnits: organizationalUnits
        )
        vcard.kind = VCardKind.org
        return vcard
    }

    /// Create a vCard for a group
    public func createGroupVCard(
        groupName: String,
        members: [String] = []
    ) -> VCard {
        var vcard = createVCard(formattedName: groupName)
        vcard.kind = VCardKind.group
        vcard.members = members
        return vcard
    }

    // MARK: - Contact Information Methods

    /// Add email address to vCard
    public func addEmail(
        to vcard: inout VCard,
        email: String,
        types: [VCardPropertyType] = [],
        preference: VCardPreference? = nil
    ) {
        var params: [String: String] = [:]
        if !types.isEmpty {
            params[VCardParameterName.type] = types.map { $0.rawValue }.joined(separator: ",")
        }
        if let pref = preference {
            params[VCardParameterName.preference] = String(pref.value)
        }

        let property = VProperty(name: VCardPropertyName.email, value: email, parameters: params)
        vcard.properties.append(property)
    }

    /// Add telephone number to vCard
    public func addTelephone(
        to vcard: inout VCard,
        number: String,
        types: [VCardPropertyType] = [],
        preference: VCardPreference? = nil
    ) {
        var params: [String: String] = [:]
        if !types.isEmpty {
            params[VCardParameterName.type] = types.map { $0.rawValue }.joined(separator: ",")
        }
        if let pref = preference {
            params[VCardParameterName.preference] = String(pref.value)
        }

        let property = VProperty(name: VCardPropertyName.telephone, value: number, parameters: params)
        vcard.properties.append(property)
    }

    /// Add address to vCard
    public func addAddress(
        to vcard: inout VCard,
        address: VCardAddress,
        types: [VCardPropertyType] = [],
        preference: VCardPreference? = nil,
        label: String? = nil
    ) {
        var params: [String: String] = [:]
        if !types.isEmpty {
            params[VCardParameterName.type] = types.map { $0.rawValue }.joined(separator: ",")
        }
        if let pref = preference {
            params[VCardParameterName.preference] = String(pref.value)
        }
        if let label = label {
            params[VCardParameterName.label] = label
        }

        let value = VCardFormatter.format(address: address)
        let property = VProperty(name: VCardPropertyName.address, value: value, parameters: params)
        vcard.properties.append(property)
    }

    /// Add URL to vCard
    public func addUrl(
        to vcard: inout VCard,
        url: String,
        type: VCardPropertyType? = nil,
        preference: VCardPreference? = nil
    ) {
        var params: [String: String] = [:]
        if let type = type {
            params[VCardParameterName.type] = type.rawValue
        }
        if let pref = preference {
            params[VCardParameterName.preference] = String(pref.value)
        }

        let property = VProperty(name: VCardPropertyName.url, value: url, parameters: params)
        vcard.properties.append(property)
    }

    /// Add instant messaging address
    public func addInstantMessaging(
        to vcard: inout VCard,
        address: String,
        service: String? = nil,
        preference: VCardPreference? = nil
    ) {
        var params: [String: String] = [:]
        if let service = service {
            params[VCardParameterName.type] = service
        }
        if let pref = preference {
            params[VCardParameterName.preference] = String(pref.value)
        }

        let property = VProperty(name: VCardPropertyName.impp, value: address, parameters: params)
        vcard.properties.append(property)
    }

    // MARK: - Advanced Creation Methods

    /// Create a contact with business information
    public func createBusinessContact(
        name: String,
        jobTitle: String? = nil,
        organization: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        address: VCardAddress? = nil
    ) -> VCard {
        var vcard = createPersonVCard(formattedName: name)

        if let jobTitle = jobTitle {
            vcard.title = jobTitle
        }

        if let organization = organization {
            vcard.organization = VCardOrganization(organizationName: organization)
        }

        if let email = email {
            addEmail(to: &vcard, email: email, types: [.work])
        }

        if let phone = phone {
            addTelephone(to: &vcard, number: phone, types: [.work, .voice])
        }

        if let address = address {
            addAddress(to: &vcard, address: address, types: [.work])
        }

        return vcard
    }

    /// Create a personal contact
    public func createPersonalContact(
        name: String,
        nickname: String? = nil,
        birthday: Date? = nil,
        email: String? = nil,
        phone: String? = nil,
        address: VCardAddress? = nil
    ) -> VCard {
        var vcard = createPersonVCard(formattedName: name)

        if let nickname = nickname {
            vcard.nicknames = [nickname]
        }

        if let birthday = birthday {
            vcard.birthday = VCardDate(date: birthday)
        }

        if let email = email {
            addEmail(to: &vcard, email: email, types: [.home])
        }

        if let phone = phone {
            addTelephone(to: &vcard, number: phone, types: [.home, .voice])
        }

        if let address = address {
            addAddress(to: &vcard, address: address, types: [.home])
        }

        return vcard
    }

    // MARK: - Utility Operations

    /// Validate a vCard
    public func validateVCard(_ vcard: VCard) async throws {
        let parser = VCardParser()
        try await parser.validate(vcard)
    }

    /// Get vCard statistics
    public func getVCardStatistics(_ vcard: VCard) async -> VCardStatistics {
        let parser = VCardParser()
        return await parser.getStatistics(vcard)
    }

    /// Find contacts by name
    public func findContacts(
        in vcards: [VCard],
        containing searchText: String
    ) -> [VCard] {
        let lowercaseSearch = searchText.lowercased()

        return vcards.filter { vcard in
            // Search in formatted name
            if let fn = vcard.formattedName, fn.lowercased().contains(lowercaseSearch) {
                return true
            }

            // Search in name components
            if let name = vcard.name {
                let allNames = name.familyNames + name.givenNames + name.additionalNames
                if allNames.contains(where: { $0.lowercased().contains(lowercaseSearch) }) {
                    return true
                }
            }

            // Search in nicknames
            if vcard.nicknames.contains(where: { $0.lowercased().contains(lowercaseSearch) }) {
                return true
            }

            // Search in organization
            if let org = vcard.organization?.organizationName.lowercased(), org.contains(lowercaseSearch) {
                return true
            }

            return false
        }
    }

    /// Find contacts by email
    public func findContacts(
        in vcards: [VCard],
        withEmail email: String
    ) -> [VCard] {
        let lowercaseEmail = email.lowercased()

        return vcards.filter { vcard in
            vcard.emails.contains { $0.value.lowercased() == lowercaseEmail }
        }
    }

    /// Find contacts by phone number
    public func findContacts(
        in vcards: [VCard],
        withPhoneNumber phone: String
    ) -> [VCard] {
        let cleanPhone = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        return vcards.filter { vcard in
            vcard.telephones.contains { telephone in
                let cleanTelphone = telephone.value.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                return cleanTelphone.contains(cleanPhone) || cleanPhone.contains(cleanTelphone)
            }
        }
    }

    /// Merge duplicate contacts
    public func mergeContacts(_ vcards: [VCard]) -> [VCard] {
        var mergedContacts: [VCard] = []
        var processedUIDs: Set<String> = []

        for vcard in vcards {
            if let uid = vcard.uid, processedUIDs.contains(uid) {
                continue
            }

            // Find potential duplicates
            let duplicates = vcards.filter { other in
                if let uid = vcard.uid, let otherUID = other.uid, uid == otherUID {
                    return true
                }

                // Check for name similarity
                if let fn1 = vcard.formattedName, let fn2 = other.formattedName {
                    return fn1.lowercased() == fn2.lowercased()
                }

                return false
            }

            if duplicates.count > 1 {
                let merged = mergeVCardInstances(duplicates)
                mergedContacts.append(merged)

                for duplicate in duplicates {
                    if let uid = duplicate.uid {
                        processedUIDs.insert(uid)
                    }
                }
            } else {
                mergedContacts.append(vcard)
                if let uid = vcard.uid {
                    processedUIDs.insert(uid)
                }
            }
        }

        return mergedContacts
    }

    private func mergeVCardInstances(_ vcards: [VCard]) -> VCard {
        guard let first = vcards.first else {
            return VCard(formattedName: "Unknown")
        }

        var merged = first

        // Combine properties from all vCards
        for vcard in vcards.dropFirst() {
            for property in vcard.properties {
                // Avoid duplicating properties
                let exists = merged.properties.contains { existing in
                    existing.name == property.name && existing.value == property.value
                }

                if !exists {
                    merged.properties.append(property)
                }
            }
        }

        return merged
    }

    // MARK: - Export/Import Helpers

    /// Export vCards to different formats
    public func exportVCards(
        _ vcards: [VCard],
        format: ExportFormat
    ) async throws -> String {
        let serializer = VCardSerializer()

        switch format {
        case .standard:
            return try await serializer.serialize(vcards)
        case .apple:
            var results: [String] = []
            for vcard in vcards {
                let result = await serializer.serializeForApple(vcard)
                results.append(result)
            }
            return results.joined(separator: "\r\n")
        case .google:
            var results: [String] = []
            for vcard in vcards {
                let result = await serializer.serializeForGoogle(vcard)
                results.append(result)
            }
            return results.joined(separator: "\r\n")
        case .outlook:
            var results: [String] = []
            for vcard in vcards {
                let result = await serializer.serializeForOutlook(vcard)
                results.append(result)
            }
            return results.joined(separator: "\r\n")
        }
    }

    public enum ExportFormat: Sendable {
        case standard
        case apple
        case google
        case outlook
    }
}

// MARK: - Convenience Extensions

extension VCardClient {

    /// Quick parse from string
    public static func parse(_ content: String) async throws -> VCard {
        let client = VCardClient()
        return try await client.parseVCard(from: content)
    }

    /// Quick serialize to string
    public static func serialize(_ vcard: VCard) async throws -> String {
        let client = VCardClient()
        return try await client.serializeVCard(vcard)
    }

    /// Create a simple contact card
    public func createContact(
        name: String,
        email: String? = nil,
        phone: String? = nil
    ) -> VCard {
        var vcard = createPersonVCard(formattedName: name)

        if let email = email {
            vcard.addEmail(email)
        }

        if let phone = phone {
            vcard.addTelephone(phone)
        }

        return vcard
    }

    /// Create a business card
    public func createBusinessCard(
        name: String,
        title: String,
        company: String,
        email: String,
        phone: String,
        website: String? = nil
    ) -> VCard {
        var vcard = createBusinessContact(
            name: name,
            jobTitle: title,
            organization: company,
            email: email,
            phone: phone
        )

        if let website = website {
            addUrl(to: &vcard, url: website, type: .work)
        }

        return vcard
    }
}
