import Foundation

// MARK: - Date Extensions

extension Date {
    /// Create a VCardDate from this date
    public func asVCardDate() -> VCardDate {
        VCardDate(date: self)
    }

    /// Create a VCardDateTime from this date
    public func asVCardDateTime() -> VCardDateTime {
        VCardDateTime(date: self)
    }
}

// MARK: - String Extensions

extension String {
    /// Parse as VCardDate
    public var asVCardDate: VCardDate? {
        VCardFormatter.parseDate(self)
    }

    /// Parse as VCardGeo
    public var asVCardGeo: VCardGeo? {
        VCardFormatter.parseGeo(self)
    }

    /// Escape for vCard text property
    public var escapedForVCard: String {
        VCardFormatter.escapeText(self)
    }

    /// Unescape from vCard text property
    public var unescapedFromVCard: String {
        VCardFormatter.unescapeText(self)
    }

    /// Validate as email address
    public var isValidEmail: Bool {
        VCardFormatter.isValidEmail(self)
    }

    /// Validate as URI
    public var isValidURI: Bool {
        VCardFormatter.isValidURI(self)
    }

    /// Validate as telephone number
    public var isValidTelephone: Bool {
        VCardFormatter.isValidTelephone(self)
    }
}

// MARK: - Array Extensions

extension Array where Element == VCard {
    /// Filter vCards by kind
    public func vCards(ofKind kind: String) -> [VCard] {
        self.filter { $0.kind?.lowercased() == kind.lowercased() }
    }

    /// Filter individual contacts
    public var individuals: [VCard] {
        vCards(ofKind: VCardKind.individual)
    }

    /// Filter organizations
    public var organizations: [VCard] {
        vCards(ofKind: VCardKind.org)
    }

    /// Filter groups
    public var groups: [VCard] {
        vCards(ofKind: VCardKind.group)
    }

    /// Filter vCards with email addresses
    public var withEmails: [VCard] {
        self.filter { !$0.emails.isEmpty }
    }

    /// Filter vCards with phone numbers
    public var withPhones: [VCard] {
        self.filter { !$0.telephones.isEmpty }
    }

    /// Filter vCards with addresses
    public var withAddresses: [VCard] {
        self.filter { !$0.addresses.isEmpty }
    }

    /// Filter vCards with photos
    public var withPhotos: [VCard] {
        self.filter { $0.photo != nil }
    }

    /// Sort vCards by formatted name
    public var sortedByName: [VCard] {
        self.sorted { lhs, rhs in
            let lhsName = lhs.formattedName ?? ""
            let rhsName = rhs.formattedName ?? ""
            return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
        }
    }

    /// Sort vCards by organization
    public var sortedByOrganization: [VCard] {
        self.sorted { lhs, rhs in
            let lhsOrg = lhs.organization?.organizationName ?? ""
            let rhsOrg = rhs.organization?.organizationName ?? ""
            return lhsOrg.localizedCaseInsensitiveCompare(rhsOrg) == .orderedAscending
        }
    }
}

// MARK: - VCard Builder

/// Fluent interface for building vCards
public struct VCardBuilder: Sendable {
    private var vcard: VCard

    public init(formattedName: String, version: VCardVersion = .v4_0) {
        self.vcard = VCard(formattedName: formattedName, version: version)
    }

    public func version(_ version: VCardVersion) -> VCardBuilder {
        var builder = self
        builder.vcard.version = version
        return builder
    }

    public func name(
        familyName: String? = nil,
        givenName: String? = nil,
        middleName: String? = nil,
        prefix: String? = nil,
        suffix: String? = nil
    ) -> VCardBuilder {
        var builder = self
        builder.vcard.name = VCardName(
            familyNames: familyName.map { [$0] } ?? [],
            givenNames: givenName.map { [$0] } ?? [],
            additionalNames: middleName.map { [$0] } ?? [],
            honorificPrefixes: prefix.map { [$0] } ?? [],
            honorificSuffixes: suffix.map { [$0] } ?? []
        )
        return builder
    }

    public func nickname(_ nickname: String) -> VCardBuilder {
        var builder = self
        builder.vcard.nicknames = (builder.vcard.nicknames) + [nickname]
        return builder
    }

    public func email(_ email: String, types: [VCardPropertyType] = []) -> VCardBuilder {
        var builder = self
        builder.vcard.addEmail(email, types: types)
        return builder
    }

    public func telephone(_ number: String, types: [VCardPropertyType] = []) -> VCardBuilder {
        var builder = self
        builder.vcard.addTelephone(number, types: types)
        return builder
    }

    public func address(_ address: VCardAddress, types: [VCardPropertyType] = []) -> VCardBuilder {
        var builder = self
        builder.vcard.addAddress(address, types: types)
        return builder
    }

    public func url(_ url: String, type: VCardPropertyType? = nil) -> VCardBuilder {
        var builder = self
        builder.vcard.addUrl(url, type: type)
        return builder
    }

    public func organization(_ name: String, units: [String] = []) -> VCardBuilder {
        var builder = self
        builder.vcard.organization = VCardOrganization(
            organizationName: name,
            organizationalUnits: units
        )
        return builder
    }

    public func title(_ title: String) -> VCardBuilder {
        var builder = self
        builder.vcard.title = title
        return builder
    }

    public func role(_ role: String) -> VCardBuilder {
        var builder = self
        builder.vcard.role = role
        return builder
    }

    public func birthday(_ date: Date) -> VCardBuilder {
        var builder = self
        builder.vcard.birthday = VCardDate(date: date)
        return builder
    }

    public func anniversary(_ date: Date) -> VCardBuilder {
        var builder = self
        builder.vcard.anniversary = VCardDate(date: date)
        return builder
    }

    public func gender(_ gender: VCardGender) -> VCardBuilder {
        var builder = self
        builder.vcard.gender = gender
        return builder
    }

    public func photo(_ photoData: String) -> VCardBuilder {
        var builder = self
        builder.vcard.photo = photoData
        return builder
    }

    public func note(_ note: String) -> VCardBuilder {
        var builder = self
        builder.vcard.note = note
        return builder
    }

    public func geo(latitude: Double, longitude: Double) -> VCardBuilder {
        var builder = self
        builder.vcard.geo = VCardGeo(latitude: latitude, longitude: longitude)
        return builder
    }

    public func timeZone(_ tz: String) -> VCardBuilder {
        var builder = self
        builder.vcard.timeZone = tz
        return builder
    }

    public func language(_ language: VCardLanguageTag) -> VCardBuilder {
        var builder = self
        builder.vcard.languages = (builder.vcard.languages) + [language]
        return builder
    }

    public func category(_ category: String) -> VCardBuilder {
        var builder = self
        builder.vcard.categories = (builder.vcard.categories) + [category]
        return builder
    }

    public func uid(_ uid: String) -> VCardBuilder {
        var builder = self
        builder.vcard.uid = uid
        return builder
    }

    public func kind(_ kind: String) -> VCardBuilder {
        var builder = self
        builder.vcard.kind = kind
        return builder
    }

    public func build() -> VCard {
        vcard
    }
}

// MARK: - Address Builder

/// Fluent interface for building addresses
public struct VCardAddressBuilder: Sendable {
    private var address: VCardAddress

    public init() {
        self.address = VCardAddress()
    }

    public func postOfficeBox(_ box: String) -> VCardAddressBuilder {
        var builder = self
        builder.address = VCardAddress(
            postOfficeBox: box,
            extendedAddress: address.extendedAddress,
            streetAddress: address.streetAddress,
            locality: address.locality,
            region: address.region,
            postalCode: address.postalCode,
            countryName: address.countryName
        )
        return builder
    }

    public func extendedAddress(_ extended: String) -> VCardAddressBuilder {
        var builder = self
        builder.address = VCardAddress(
            postOfficeBox: address.postOfficeBox,
            extendedAddress: extended,
            streetAddress: address.streetAddress,
            locality: address.locality,
            region: address.region,
            postalCode: address.postalCode,
            countryName: address.countryName
        )
        return builder
    }

    public func streetAddress(_ street: String) -> VCardAddressBuilder {
        var builder = self
        builder.address = VCardAddress(
            postOfficeBox: address.postOfficeBox,
            extendedAddress: address.extendedAddress,
            streetAddress: street,
            locality: address.locality,
            region: address.region,
            postalCode: address.postalCode,
            countryName: address.countryName
        )
        return builder
    }

    public func locality(_ locality: String) -> VCardAddressBuilder {
        var builder = self
        builder.address = VCardAddress(
            postOfficeBox: address.postOfficeBox,
            extendedAddress: address.extendedAddress,
            streetAddress: address.streetAddress,
            locality: locality,
            region: address.region,
            postalCode: address.postalCode,
            countryName: address.countryName
        )
        return builder
    }

    public func region(_ region: String) -> VCardAddressBuilder {
        var builder = self
        builder.address = VCardAddress(
            postOfficeBox: address.postOfficeBox,
            extendedAddress: address.extendedAddress,
            streetAddress: address.streetAddress,
            locality: address.locality,
            region: region,
            postalCode: address.postalCode,
            countryName: address.countryName
        )
        return builder
    }

    public func postalCode(_ code: String) -> VCardAddressBuilder {
        var builder = self
        builder.address = VCardAddress(
            postOfficeBox: address.postOfficeBox,
            extendedAddress: address.extendedAddress,
            streetAddress: address.streetAddress,
            locality: address.locality,
            region: address.region,
            postalCode: code,
            countryName: address.countryName
        )
        return builder
    }

    public func country(_ country: String) -> VCardAddressBuilder {
        var builder = self
        builder.address = VCardAddress(
            postOfficeBox: address.postOfficeBox,
            extendedAddress: address.extendedAddress,
            streetAddress: address.streetAddress,
            locality: address.locality,
            region: address.region,
            postalCode: address.postalCode,
            countryName: country
        )
        return builder
    }

    public func build() -> VCardAddress {
        address
    }
}

// MARK: - Quick Creation Functions

public func vcard(formattedName: String, @VCardPropertyBuilder builder: (VCardBuilder) -> VCardBuilder) -> VCard {
    let vCardBuilder = VCardBuilder(formattedName: formattedName)
    return builder(vCardBuilder).build()
}

public func address(@VCardAddressPropertyBuilder builder: (VCardAddressBuilder) -> VCardAddressBuilder) -> VCardAddress {
    let addressBuilder = VCardAddressBuilder()
    return builder(addressBuilder).build()
}

// MARK: - Result Builders

@resultBuilder
public struct VCardPropertyBuilder {
    public static func buildBlock(_ builder: VCardBuilder) -> VCardBuilder {
        builder
    }
}

@resultBuilder
public struct VCardAddressPropertyBuilder {
    public static func buildBlock(_ builder: VCardAddressBuilder) -> VCardAddressBuilder {
        builder
    }
}

// MARK: - Common Contact Types

public struct ContactTemplates {
    /// Create a basic personal contact
    public static func personalContact(
        name: String,
        email: String? = nil,
        phone: String? = nil
    ) -> VCard {
        let builder = VCardBuilder(formattedName: name)
            .kind(VCardKind.individual)

        var result = builder
        if let email = email {
            result = result.email(email, types: [.home])
        }
        if let phone = phone {
            result = result.telephone(phone, types: [.home, .voice])
        }

        return result.build()
    }

    /// Create a business contact
    public static func businessContact(
        name: String,
        title: String? = nil,
        company: String? = nil,
        email: String? = nil,
        phone: String? = nil
    ) -> VCard {
        var builder = VCardBuilder(formattedName: name)
            .kind(VCardKind.individual)

        if let title = title {
            builder = builder.title(title)
        }

        if let company = company {
            builder = builder.organization(company)
        }

        if let email = email {
            builder = builder.email(email, types: [.work])
        }

        if let phone = phone {
            builder = builder.telephone(phone, types: [.work, .voice])
        }

        return builder.build()
    }

    /// Create an organization contact
    public static func organizationContact(
        name: String,
        website: String? = nil,
        email: String? = nil,
        phone: String? = nil
    ) -> VCard {
        var builder = VCardBuilder(formattedName: name)
            .kind(VCardKind.org)
            .organization(name)

        if let website = website {
            builder = builder.url(website)
        }

        if let email = email {
            builder = builder.email(email, types: [.work])
        }

        if let phone = phone {
            builder = builder.telephone(phone, types: [.work, .voice])
        }

        return builder.build()
    }
}

// MARK: - Validation Utilities

public struct VCardValidationUtilities {
    /// Check if vCard has minimum required information
    public static func hasMinimumInfo(_ vcard: VCard) -> Bool {
        vcard.formattedName != nil && !vcard.formattedName!.isEmpty
    }

    /// Check if vCard has contact information
    public static func hasContactInfo(_ vcard: VCard) -> Bool {
        !vcard.emails.isEmpty || !vcard.telephones.isEmpty || !vcard.addresses.isEmpty
    }

    /// Check if vCard appears to be a person
    public static func isPerson(_ vcard: VCard) -> Bool {
        vcard.kind == VCardKind.individual || vcard.name != nil
    }

    /// Check if vCard appears to be an organization
    public static func isOrganization(_ vcard: VCard) -> Bool {
        vcard.kind == VCardKind.org || vcard.organization != nil
    }

    /// Check if vCard has complete name information
    public static func hasCompleteName(_ vcard: VCard) -> Bool {
        guard let name = vcard.name else { return false }
        return !name.familyNames.isEmpty && !name.givenNames.isEmpty
    }

    /// Check if vCard has valid email addresses
    public static func hasValidEmails(_ vcard: VCard) -> Bool {
        vcard.emails.allSatisfy { VCardFormatter.isValidEmail($0.value) }
    }

    /// Check if vCard has valid phone numbers
    public static func hasValidPhones(_ vcard: VCard) -> Bool {
        vcard.telephones.allSatisfy { VCardFormatter.isValidTelephone($0.value) }
    }

    /// Check if vCard has valid URLs
    public static func hasValidURLs(_ vcard: VCard) -> Bool {
        vcard.urls.allSatisfy { VCardFormatter.isValidURI($0) }
    }
}

// MARK: - Import/Export Utilities

public struct VCardIOUtilities {
    /// Extract vCards from a directory of .vcf files
    public static func extractVCardsFromDirectory(at url: URL) async throws -> [VCard] {
        let fileManager = FileManager.default
        let client = VCardClient()
        var allVCards: [VCard] = []

        let files = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        let vcfFiles = files.filter { $0.pathExtension.lowercased() == "vcf" }

        for file in vcfFiles {
            do {
                let vcards = try await client.parseVCards(from: String(contentsOf: file, encoding: .utf8))
                allVCards.append(contentsOf: vcards)
            } catch {
                // Continue with other files even if one fails
                print("Failed to parse \(file.lastPathComponent): \(error)")
            }
        }

        return allVCards
    }

    /// Export vCards to individual files
    public static func exportVCardsToFiles(_ vcards: [VCard], directory: URL) async throws {
        let fileManager = FileManager.default
        let client = VCardClient()

        // Create directory if it doesn't exist
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        for (index, vcard) in vcards.enumerated() {
            let fileName = vcard.formattedName?.replacingOccurrences(of: " ", with: "_") ?? "contact_\(index)"
            let fileURL = directory.appendingPathComponent("\(fileName).vcf")

            try await client.serializeVCard(vcard, to: fileURL)
        }
    }

    /// Backup vCards to a single file
    public static func backupVCards(_ vcards: [VCard], to url: URL) async throws {
        let client = VCardClient()
        let allVCardsContent = try await client.serializeVCards(vcards)
        try allVCardsContent.write(to: url, atomically: true, encoding: .utf8)
    }
}

// MARK: - Contact Merging Utilities

public struct VCardMergingUtilities {
    /// Merge two vCards intelligently
    public static func merge(_ primary: VCard, with secondary: VCard) -> VCard {
        var merged = primary

        // Merge emails
        let existingEmails = Set(merged.emails.map { $0.value.lowercased() })
        for email in secondary.emails {
            if !existingEmails.contains(email.value.lowercased()) {
                merged.addEmail(email.value, types: email.types)
            }
        }

        // Merge phones
        let existingPhones = Set(merged.telephones.map { cleanPhoneNumber($0.value) })
        for phone in secondary.telephones {
            let cleanPhone = cleanPhoneNumber(phone.value)
            if !existingPhones.contains(cleanPhone) {
                merged.addTelephone(phone.value, types: phone.types)
            }
        }

        // Merge addresses
        for address in secondary.addresses {
            let addressExists = merged.addresses.contains { existing in
                existing.streetAddress == address.streetAddress && existing.locality == address.locality && existing.region == address.region
            }
            if !addressExists {
                merged.addAddress(address)
            }
        }

        // Merge other properties
        if merged.birthday == nil && secondary.birthday != nil {
            merged.birthday = secondary.birthday
        }

        if merged.organization == nil && secondary.organization != nil {
            merged.organization = secondary.organization
        }

        if merged.title == nil && secondary.title != nil {
            merged.title = secondary.title
        }

        if merged.photo == nil && secondary.photo != nil {
            merged.photo = secondary.photo
        }

        // Merge categories
        let existingCategories = Set(merged.categories)
        for category in secondary.categories {
            if !existingCategories.contains(category) {
                merged.categories.append(category)
            }
        }

        return merged
    }

    private static func cleanPhoneNumber(_ phone: String) -> String {
        phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
    }
}
