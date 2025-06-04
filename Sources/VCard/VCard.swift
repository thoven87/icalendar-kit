import Foundation

// MARK: - Main VCard Component

/// Represents a complete vCard following RFC-6350
public struct VCard: VCardComponent, Sendable {
    public static let componentName = "VCARD"

    public var properties: [VCardProperty]

    // MARK: - Required Properties

    /// vCard version (required)
    public var version: VCardVersion {
        get {
            guard let value = getPropertyValue(VCardPropertyName.version),
                let version = VCardVersion(rawValue: value)
            else {
                return .v4_0
            }
            return version
        }
        set { setPropertyValue(VCardPropertyName.version, value: newValue.rawValue) }
    }

    /// Formatted name (required)
    public var formattedName: String? {
        get { getPropertyValue(VCardPropertyName.formattedName) }
        set { setPropertyValue(VCardPropertyName.formattedName, value: newValue) }
    }

    // MARK: - Identification Properties

    /// Structured name
    public var name: VCardName? {
        get { getNameProperty() }
        set { setNameProperty(newValue) }
    }

    /// Nicknames
    public var nicknames: [String] {
        get { getNicknamesProperty() }
        set { setNicknamesProperty(newValue) }
    }

    /// Photo
    public var photo: String? {
        get { getPropertyValue(VCardPropertyName.photo) }
        set { setPropertyValue(VCardPropertyName.photo, value: newValue) }
    }

    /// Birthday
    public var birthday: VCardDate? {
        get { getBirthdayProperty() }
        set { setBirthdayProperty(newValue) }
    }

    /// Anniversary
    public var anniversary: VCardDate? {
        get { getAnniversaryProperty() }
        set { setAnniversaryProperty(newValue) }
    }

    /// Gender
    public var gender: VCardGender? {
        get {
            guard let value = getPropertyValue(VCardPropertyName.gender) else { return nil }
            return VCardGender(rawValue: String(value.prefix(1)))
        }
        set { setPropertyValue(VCardPropertyName.gender, value: newValue?.rawValue) }
    }

    // MARK: - Delivery Addressing Properties

    /// Addresses
    public var addresses: [VCardAddress] {
        get { getAddressesProperty() }
        set { setAddressesProperty(newValue) }
    }

    // MARK: - Communications Properties

    /// Telephone numbers
    public var telephones: [(value: String, types: [VCardPropertyType])] {
        get { getTelephonesProperty() }
        set { setTelephonesProperty(newValue) }
    }

    /// Email addresses
    public var emails: [(value: String, types: [VCardPropertyType])] {
        get { getEmailsProperty() }
        set { setEmailsProperty(newValue) }
    }

    /// Instant messaging addresses
    public var instantMessaging: [String] {
        get { getInstantMessagingProperty() }
        set { setInstantMessagingProperty(newValue) }
    }

    /// Languages
    public var languages: [VCardLanguageTag] {
        get { getLanguagesProperty() }
        set { setLanguagesProperty(newValue) }
    }

    // MARK: - Geographical Properties

    /// Time zone
    public var timeZone: String? {
        get { getPropertyValue(VCardPropertyName.timezone) }
        set { setPropertyValue(VCardPropertyName.timezone, value: newValue) }
    }

    /// Geographical position
    public var geo: VCardGeo? {
        get { getGeoProperty() }
        set { setGeoProperty(newValue) }
    }

    // MARK: - Organizational Properties

    /// Job title
    public var title: String? {
        get { getPropertyValue(VCardPropertyName.title) }
        set { setPropertyValue(VCardPropertyName.title, value: newValue) }
    }

    /// Role
    public var role: String? {
        get { getPropertyValue(VCardPropertyName.role) }
        set { setPropertyValue(VCardPropertyName.role, value: newValue) }
    }

    /// Logo
    public var logo: String? {
        get { getPropertyValue(VCardPropertyName.logo) }
        set { setPropertyValue(VCardPropertyName.logo, value: newValue) }
    }

    /// Organization
    public var organization: VCardOrganization? {
        get { getOrganizationProperty() }
        set { setOrganizationProperty(newValue) }
    }

    /// Members (for group vCards)
    public var members: [String] {
        get { getMembersProperty() }
        set { setMembersProperty(newValue) }
    }

    /// Related entities
    public var related: [(value: String, relation: String?)] {
        get { getRelatedProperty() }
        set { setRelatedProperty(newValue) }
    }

    // MARK: - Explanatory Properties

    /// Categories
    public var categories: [String] {
        get { getCategoriesProperty() }
        set { setCategoriesProperty(newValue) }
    }

    /// Note
    public var note: String? {
        get { getPropertyValue(VCardPropertyName.note) }
        set { setPropertyValue(VCardPropertyName.note, value: newValue) }
    }

    /// Product ID
    public var productId: String? {
        get { getPropertyValue(VCardPropertyName.productId) }
        set { setPropertyValue(VCardPropertyName.productId, value: newValue) }
    }

    /// Revision date
    public var revision: Date? {
        get { getRevisionProperty() }
        set { setRevisionProperty(newValue) }
    }

    /// Sound
    public var sound: String? {
        get { getPropertyValue(VCardPropertyName.sound) }
        set { setPropertyValue(VCardPropertyName.sound, value: newValue) }
    }

    /// Unique identifier
    public var uid: String? {
        get { getPropertyValue(VCardPropertyName.uid) }
        set { setPropertyValue(VCardPropertyName.uid, value: newValue) }
    }

    /// URLs
    public var urls: [String] {
        get { getUrlsProperty() }
        set { setUrlsProperty(newValue) }
    }

    /// Cryptographic keys
    public var keys: [String] {
        get { getKeysProperty() }
        set { setKeysProperty(newValue) }
    }

    // MARK: - Calendar Properties

    /// Free/busy URL
    public var freeBusyUrl: String? {
        get { getPropertyValue(VCardPropertyName.freeBusyUrl) }
        set { setPropertyValue(VCardPropertyName.freeBusyUrl, value: newValue) }
    }

    /// Calendar address URI
    public var calendarAddressUri: String? {
        get { getPropertyValue(VCardPropertyName.calendarAddressUri) }
        set { setPropertyValue(VCardPropertyName.calendarAddressUri, value: newValue) }
    }

    /// Calendar URI
    public var calendarUri: String? {
        get { getPropertyValue(VCardPropertyName.calendarUri) }
        set { setPropertyValue(VCardPropertyName.calendarUri, value: newValue) }
    }

    // MARK: - Extension Properties

    /// Source
    public var source: String? {
        get { getPropertyValue(VCardPropertyName.source) }
        set { setPropertyValue(VCardPropertyName.source, value: newValue) }
    }

    /// Kind (individual, group, org, location, etc.)
    public var kind: String? {
        get { getPropertyValue(VCardPropertyName.kind) }
        set { setPropertyValue(VCardPropertyName.kind, value: newValue) }
    }

    /// XML data
    public var xml: String? {
        get { getPropertyValue(VCardPropertyName.xml) }
        set { setPropertyValue(VCardPropertyName.xml, value: newValue) }
    }

    // MARK: - Initializers

    public init(properties: [VCardProperty] = []) {
        self.properties = properties
    }

    public init(formattedName: String, version: VCardVersion = .v4_0) {
        self.properties = [
            VProperty(name: VCardPropertyName.version, value: version.rawValue),
            VProperty(name: VCardPropertyName.formattedName, value: formattedName),
        ]
    }

    // MARK: - Convenience Methods

    /// Add a telephone number with types
    public mutating func addTelephone(_ number: String, types: [VCardPropertyType] = []) {
        var params: [String: String] = [:]
        if !types.isEmpty {
            params[VCardParameterName.type] = types.map { $0.rawValue }.joined(separator: ",")
        }
        properties.append(VProperty(name: VCardPropertyName.telephone, value: number, parameters: params))
    }

    /// Add an email address with types
    public mutating func addEmail(_ email: String, types: [VCardPropertyType] = []) {
        var params: [String: String] = [:]
        if !types.isEmpty {
            params[VCardParameterName.type] = types.map { $0.rawValue }.joined(separator: ",")
        }
        properties.append(VProperty(name: VCardPropertyName.email, value: email, parameters: params))
    }

    /// Add an address with types
    public mutating func addAddress(_ address: VCardAddress, types: [VCardPropertyType] = []) {
        var params: [String: String] = [:]
        if !types.isEmpty {
            params[VCardParameterName.type] = types.map { $0.rawValue }.joined(separator: ",")
        }
        let value = VCardFormatter.format(address: address)
        properties.append(VProperty(name: VCardPropertyName.address, value: value, parameters: params))
    }

    /// Add a URL
    public mutating func addUrl(_ url: String, type: VCardPropertyType? = nil) {
        var params: [String: String] = [:]
        if let type = type {
            params[VCardParameterName.type] = type.rawValue
        }
        properties.append(VProperty(name: VCardPropertyName.url, value: url, parameters: params))
    }

    /// Add a category
    public mutating func addCategory(_ category: String) {
        let existing = categories
        categories = existing + [category]
    }

    /// Set preference for a property
    public mutating func setPreference(_ preference: VCardPreference, for propertyName: String, at index: Int = 0) {
        let matchingProperties = properties.enumerated().filter { $0.element.name == propertyName }
        guard index < matchingProperties.count else { return }

        let propertyIndex = matchingProperties[index].offset
        var params = properties[propertyIndex].parameters
        params[VCardParameterName.preference] = String(preference.value)

        properties[propertyIndex] = VProperty(
            name: properties[propertyIndex].name,
            value: properties[propertyIndex].value,
            parameters: params
        )
    }
}

// MARK: - Property Access Helpers

extension VCard {
    /// Get a property value by name
    public func getPropertyValue(_ name: String) -> String? {
        properties.first { $0.name == name }?.value
    }

    /// Set a property value
    public mutating func setPropertyValue(_ name: String, value: String?) {
        properties.removeAll { $0.name == name }
        if let value = value {
            properties.append(VProperty(name: name, value: value))
        }
    }

    /// Get all properties with a given name
    public func getProperties(_ name: String) -> [VCardProperty] {
        properties.filter { $0.name == name }
    }

    /// Get structured name property
    private func getNameProperty() -> VCardName? {
        guard let value = getPropertyValue(VCardPropertyName.name) else { return nil }
        return VCardFormatter.parseName(value)
    }

    /// Set structured name property
    private mutating func setNameProperty(_ name: VCardName?) {
        guard let name = name else {
            setPropertyValue(VCardPropertyName.name, value: nil)
            return
        }
        setPropertyValue(VCardPropertyName.name, value: VCardFormatter.format(name: name))
    }

    /// Get nicknames property
    private func getNicknamesProperty() -> [String] {
        guard let value = getPropertyValue(VCardPropertyName.nickname) else { return [] }
        return value.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    }

    /// Set nicknames property
    private mutating func setNicknamesProperty(_ nicknames: [String]) {
        if nicknames.isEmpty {
            setPropertyValue(VCardPropertyName.nickname, value: nil)
        } else {
            setPropertyValue(VCardPropertyName.nickname, value: nicknames.joined(separator: ","))
        }
    }

    /// Get birthday property
    private func getBirthdayProperty() -> VCardDate? {
        guard let value = getPropertyValue(VCardPropertyName.birthday) else { return nil }
        return VCardFormatter.parseDate(value)
    }

    /// Set birthday property
    private mutating func setBirthdayProperty(_ birthday: VCardDate?) {
        guard let birthday = birthday else {
            setPropertyValue(VCardPropertyName.birthday, value: nil)
            return
        }
        setPropertyValue(VCardPropertyName.birthday, value: VCardFormatter.format(date: birthday))
    }

    /// Get anniversary property
    private func getAnniversaryProperty() -> VCardDate? {
        guard let value = getPropertyValue(VCardPropertyName.anniversary) else { return nil }
        return VCardFormatter.parseDate(value)
    }

    /// Set anniversary property
    private mutating func setAnniversaryProperty(_ anniversary: VCardDate?) {
        guard let anniversary = anniversary else {
            setPropertyValue(VCardPropertyName.anniversary, value: nil)
            return
        }
        setPropertyValue(VCardPropertyName.anniversary, value: VCardFormatter.format(date: anniversary))
    }

    /// Get addresses property
    private func getAddressesProperty() -> [VCardAddress] {
        getProperties(VCardPropertyName.address).compactMap { property in
            VCardFormatter.parseAddress(property.value)
        }
    }

    /// Set addresses property
    private mutating func setAddressesProperty(_ addresses: [VCardAddress]) {
        properties.removeAll { $0.name == VCardPropertyName.address }
        for address in addresses {
            properties.append(
                VProperty(
                    name: VCardPropertyName.address,
                    value: VCardFormatter.format(address: address)
                )
            )
        }
    }

    /// Get telephones property
    private func getTelephonesProperty() -> [(value: String, types: [VCardPropertyType])] {
        getProperties(VCardPropertyName.telephone).map { property in
            let types =
                property.parameters[VCardParameterName.type]?
                .split(separator: ",")
                .compactMap { VCardPropertyType(rawValue: String($0)) } ?? []
            return (value: property.value, types: types)
        }
    }

    /// Set telephones property
    private mutating func setTelephonesProperty(_ telephones: [(value: String, types: [VCardPropertyType])]) {
        properties.removeAll { $0.name == VCardPropertyName.telephone }
        for telephone in telephones {
            var params: [String: String] = [:]
            if !telephone.types.isEmpty {
                params[VCardParameterName.type] = telephone.types.map { $0.rawValue }.joined(separator: ",")
            }
            properties.append(
                VProperty(
                    name: VCardPropertyName.telephone,
                    value: telephone.value,
                    parameters: params
                )
            )
        }
    }

    /// Get emails property
    private func getEmailsProperty() -> [(value: String, types: [VCardPropertyType])] {
        getProperties(VCardPropertyName.email).map { property in
            let types =
                property.parameters[VCardParameterName.type]?
                .split(separator: ",")
                .compactMap { VCardPropertyType(rawValue: String($0)) } ?? []
            return (value: property.value, types: types)
        }
    }

    /// Set emails property
    private mutating func setEmailsProperty(_ emails: [(value: String, types: [VCardPropertyType])]) {
        properties.removeAll { $0.name == VCardPropertyName.email }
        for email in emails {
            var params: [String: String] = [:]
            if !email.types.isEmpty {
                params[VCardParameterName.type] = email.types.map { $0.rawValue }.joined(separator: ",")
            }
            properties.append(
                VProperty(
                    name: VCardPropertyName.email,
                    value: email.value,
                    parameters: params
                )
            )
        }
    }

    /// Get instant messaging property
    private func getInstantMessagingProperty() -> [String] {
        getProperties(VCardPropertyName.impp).map { $0.value }
    }

    /// Set instant messaging property
    private mutating func setInstantMessagingProperty(_ imAddresses: [String]) {
        properties.removeAll { $0.name == VCardPropertyName.impp }
        for address in imAddresses {
            properties.append(VProperty(name: VCardPropertyName.impp, value: address))
        }
    }

    /// Get languages property
    private func getLanguagesProperty() -> [VCardLanguageTag] {
        getProperties(VCardPropertyName.language).map { VCardLanguageTag($0.value) }
    }

    /// Set languages property
    private mutating func setLanguagesProperty(_ languages: [VCardLanguageTag]) {
        properties.removeAll { $0.name == VCardPropertyName.language }
        for language in languages {
            properties.append(VProperty(name: VCardPropertyName.language, value: language.tag))
        }
    }

    /// Get geo property
    private func getGeoProperty() -> VCardGeo? {
        guard let value = getPropertyValue(VCardPropertyName.geo) else { return nil }
        return VCardFormatter.parseGeo(value)
    }

    /// Set geo property
    private mutating func setGeoProperty(_ geo: VCardGeo?) {
        guard let geo = geo else {
            setPropertyValue(VCardPropertyName.geo, value: nil)
            return
        }
        setPropertyValue(VCardPropertyName.geo, value: VCardFormatter.format(geo: geo))
    }

    /// Get organization property
    private func getOrganizationProperty() -> VCardOrganization? {
        guard let value = getPropertyValue(VCardPropertyName.organization) else { return nil }
        return VCardFormatter.parseOrganization(value)
    }

    /// Set organization property
    private mutating func setOrganizationProperty(_ organization: VCardOrganization?) {
        guard let organization = organization else {
            setPropertyValue(VCardPropertyName.organization, value: nil)
            return
        }
        setPropertyValue(VCardPropertyName.organization, value: VCardFormatter.format(organization: organization))
    }

    /// Get members property
    private func getMembersProperty() -> [String] {
        getProperties(VCardPropertyName.member).map { $0.value }
    }

    /// Set members property
    private mutating func setMembersProperty(_ members: [String]) {
        properties.removeAll { $0.name == VCardPropertyName.member }
        for member in members {
            properties.append(VProperty(name: VCardPropertyName.member, value: member))
        }
    }

    /// Get related property
    private func getRelatedProperty() -> [(value: String, relation: String?)] {
        getProperties(VCardPropertyName.related).map { property in
            let relation = property.parameters[VCardParameterName.type]
            return (value: property.value, relation: relation)
        }
    }

    /// Set related property
    private mutating func setRelatedProperty(_ related: [(value: String, relation: String?)]) {
        properties.removeAll { $0.name == VCardPropertyName.related }
        for item in related {
            var params: [String: String] = [:]
            if let relation = item.relation {
                params[VCardParameterName.type] = relation
            }
            properties.append(
                VProperty(
                    name: VCardPropertyName.related,
                    value: item.value,
                    parameters: params
                )
            )
        }
    }

    /// Get categories property
    private func getCategoriesProperty() -> [String] {
        guard let value = getPropertyValue(VCardPropertyName.categories) else { return [] }
        return value.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    }

    /// Set categories property
    private mutating func setCategoriesProperty(_ categories: [String]) {
        if categories.isEmpty {
            setPropertyValue(VCardPropertyName.categories, value: nil)
        } else {
            setPropertyValue(VCardPropertyName.categories, value: categories.joined(separator: ","))
        }
    }

    /// Get revision property
    private func getRevisionProperty() -> Date? {
        guard let value = getPropertyValue(VCardPropertyName.revision) else { return nil }
        return VCardFormatter.parseTimestamp(value)
    }

    /// Set revision property
    private mutating func setRevisionProperty(_ revision: Date?) {
        guard let revision = revision else {
            setPropertyValue(VCardPropertyName.revision, value: nil)
            return
        }
        setPropertyValue(VCardPropertyName.revision, value: VCardFormatter.format(timestamp: revision))
    }

    /// Get URLs property
    private func getUrlsProperty() -> [String] {
        getProperties(VCardPropertyName.url).map { $0.value }
    }

    /// Set URLs property
    private mutating func setUrlsProperty(_ urls: [String]) {
        properties.removeAll { $0.name == VCardPropertyName.url }
        for url in urls {
            properties.append(VProperty(name: VCardPropertyName.url, value: url))
        }
    }

    /// Get keys property
    private func getKeysProperty() -> [String] {
        getProperties(VCardPropertyName.key).map { $0.value }
    }

    /// Set keys property
    private mutating func setKeysProperty(_ keys: [String]) {
        properties.removeAll { $0.name == VCardPropertyName.key }
        for key in keys {
            properties.append(VProperty(name: VCardPropertyName.key, value: key))
        }
    }
}
