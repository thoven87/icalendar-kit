import Foundation

// MARK: - Core Protocol Definitions

/// Base protocol for all vCard properties that can be parsed and serialized
public protocol VCardProperty: Sendable {
    /// The property name (e.g., "FN", "N", "EMAIL", "TEL")
    var name: String { get }

    /// The property value
    var value: String { get }

    /// Property parameters (e.g., TYPE, PREF, CHARSET)
    var parameters: [String: String] { get }

    /// Initialize with name, value, and parameters
    init(name: String, value: String, parameters: [String: String])
}

/// Protocol for vCard components
public protocol VCardComponent: Sendable {
    /// The component name (always "VCARD" for vCard 4.0)
    static var componentName: String { get }

    /// Properties associated with this vCard
    var properties: [VCardProperty] { get set }

    /// Initialize from properties
    init(properties: [VCardProperty])
}

/// Protocol for parameter encoding/decoding
public protocol VCardParameter: Sendable {
    /// Parameter name
    var name: String { get }

    /// Parameter value
    var value: String { get }
}

// MARK: - Core Data Types

/// Represents a vCard property with name, value, and parameters
public struct VProperty: VCardProperty {
    public let name: String
    public let value: String
    public let parameters: [String: String]

    public init(name: String, value: String, parameters: [String: String] = [:]) {
        self.name = name
        self.value = value
        self.parameters = parameters
    }
}

/// Represents a vCard parameter
public struct VParameter: VCardParameter {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

// MARK: - vCard Value Types

/// Represents different vCard value types
public enum VCardValueType: String, Sendable, CaseIterable, Codable {
    case text = "TEXT"
    case uri = "URI"
    case date = "DATE"
    case time = "TIME"
    case dateTime = "DATE-TIME"
    case dateAndOrTime = "DATE-AND-OR-TIME"
    case timestamp = "TIMESTAMP"
    case boolean = "BOOLEAN"
    case integer = "INTEGER"
    case float = "FLOAT"
    case utcOffset = "UTC-OFFSET"
    case languageTag = "LANGUAGE-TAG"
}

/// Represents a structured name (N property)
public struct VCardName: Sendable, Codable, Hashable {
    public let familyNames: [String]
    public let givenNames: [String]
    public let additionalNames: [String]
    public let honorificPrefixes: [String]
    public let honorificSuffixes: [String]

    public init(
        familyNames: [String] = [],
        givenNames: [String] = [],
        additionalNames: [String] = [],
        honorificPrefixes: [String] = [],
        honorificSuffixes: [String] = []
    ) {
        self.familyNames = familyNames
        self.givenNames = givenNames
        self.additionalNames = additionalNames
        self.honorificPrefixes = honorificPrefixes
        self.honorificSuffixes = honorificSuffixes
    }

    /// Full name string
    public var fullName: String {
        let all = givenNames + additionalNames + familyNames
        return all.joined(separator: " ")
    }
}

/// Represents a structured address (ADR property)
public struct VCardAddress: Sendable, Codable, Hashable {
    public let postOfficeBox: String?
    public let extendedAddress: String?
    public let streetAddress: String?
    public let locality: String?
    public let region: String?
    public let postalCode: String?
    public let countryName: String?

    public init(
        postOfficeBox: String? = nil,
        extendedAddress: String? = nil,
        streetAddress: String? = nil,
        locality: String? = nil,
        region: String? = nil,
        postalCode: String? = nil,
        countryName: String? = nil
    ) {
        self.postOfficeBox = postOfficeBox
        self.extendedAddress = extendedAddress
        self.streetAddress = streetAddress
        self.locality = locality
        self.region = region
        self.postalCode = postalCode
        self.countryName = countryName
    }

    /// Full address string
    public var fullAddress: String {
        let components = [streetAddress, locality, region, postalCode, countryName]
        return components.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

/// Represents geographical information (GEO property)
public struct VCardGeo: Sendable, Codable, Hashable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// URI representation
    public var uri: String {
        "geo:\(latitude),\(longitude)"
    }
}

/// Represents organization information (ORG property)
public struct VCardOrganization: Sendable, Codable, Hashable {
    public let organizationName: String
    public let organizationalUnits: [String]

    public init(organizationName: String, organizationalUnits: [String] = []) {
        self.organizationName = organizationName
        self.organizationalUnits = organizationalUnits
    }

    /// Full organization string
    public var fullOrganization: String {
        if organizationalUnits.isEmpty {
            return organizationName
        } else {
            return ([organizationName] + organizationalUnits).joined(separator: ", ")
        }
    }
}

// MARK: - Enumerated Types

/// vCard version enumeration
public enum VCardVersion: String, Sendable, CaseIterable, Codable {
    case v3_0 = "3.0"
    case v4_0 = "4.0"
}

/// Common vCard property types
public enum VCardPropertyType: String, Sendable, CaseIterable, Codable {
    // Contact types
    case work = "WORK"
    case home = "HOME"
    case other = "OTHER"

    // Communication types
    case voice = "VOICE"
    case fax = "FAX"
    case cell = "CELL"
    case video = "VIDEO"
    case pager = "PAGER"
    case textphone = "TEXTPHONE"
    case text = "TEXT"
    case mainNumber = "MAIN-NUMBER"

    // Email types
    case internet = "INTERNET"

    // Address types
    case postal = "POSTAL"
    case parcel = "PARCEL"
    case dom = "DOM"
    case intl = "INTL"

    // URL types
    case contact = "CONTACT"

    // Photo/Logo types
    case jpeg = "JPEG"
    case png = "PNG"
    case gif = "GIF"
}

/// Gender values for GENDER property
public enum VCardGender: String, Sendable, CaseIterable, Codable {
    case male = "M"
    case female = "F"
    case other = "O"
    case none = "N"
    case unknown = "U"
}

/// Calendar address user types
public enum VCardCalendarUserType: String, Sendable, CaseIterable, Codable {
    case individual = "INDIVIDUAL"
    case group = "GROUP"
    case resource = "RESOURCE"
    case room = "ROOM"
    case unknown = "UNKNOWN"
}

/// Free/busy URL types
public enum VCardFreeBusyType: String, Sendable, CaseIterable, Codable {
    case free = "FREE"
    case busy = "BUSY"
    case busyUnavailable = "BUSY-UNAVAILABLE"
    case busyTentative = "BUSY-TENTATIVE"
}

// MARK: - Error Types

/// Errors that can occur during vCard parsing or creation
public enum VCardError: Error, Sendable {
    case invalidFormat(String)
    case missingRequiredProperty(String)
    case invalidPropertyValue(property: String, value: String)
    case invalidVersion(String)
    case unsupportedVersion(String)
    case encodingError(String)
    case decodingError(String)
    case invalidParameterValue(parameter: String, value: String)
    case malformedStructuredValue(String)
}

// MARK: - Constants

/// Common vCard property names
public struct VCardPropertyName {
    // Core properties
    public static let version = "VERSION"
    public static let formattedName = "FN"
    public static let name = "N"
    public static let nickname = "NICKNAME"
    public static let photo = "PHOTO"
    public static let birthday = "BDAY"
    public static let anniversary = "ANNIVERSARY"
    public static let gender = "GENDER"

    // Delivery addressing properties
    public static let address = "ADR"

    // Communications properties
    public static let telephone = "TEL"
    public static let email = "EMAIL"
    public static let impp = "IMPP"
    public static let language = "LANG"

    // Geographical properties
    public static let timezone = "TZ"
    public static let geo = "GEO"

    // Organizational properties
    public static let title = "TITLE"
    public static let role = "ROLE"
    public static let logo = "LOGO"
    public static let organization = "ORG"
    public static let member = "MEMBER"
    public static let related = "RELATED"

    // Explanatory properties
    public static let categories = "CATEGORIES"
    public static let note = "NOTE"
    public static let productId = "PRODID"
    public static let revision = "REV"
    public static let sound = "SOUND"
    public static let uid = "UID"
    public static let clientPidMap = "CLIENTPIDMAP"
    public static let url = "URL"
    public static let key = "KEY"

    // Security properties
    public static let class_ = "CLASS"

    // Calendar properties
    public static let freeBusyUrl = "FBURL"
    public static let calendarAddressUri = "CALADRURI"
    public static let calendarUri = "CALURI"

    // Extension properties
    public static let source = "SOURCE"
    public static let kind = "KIND"
    public static let xml = "XML"
}

/// Common vCard parameter names
public struct VCardParameterName {
    public static let type = "TYPE"
    public static let preference = "PREF"
    public static let language = "LANGUAGE"
    public static let value = "VALUE"
    public static let sortAs = "SORT-AS"
    public static let geoLocation = "GEO"
    public static let timezone = "TZ"
    public static let altId = "ALTID"
    public static let pid = "PID"
    public static let calScale = "CALSCALE"
    public static let encoding = "ENCODING"
    public static let formatType = "FMTTYPE"
    public static let charset = "CHARSET"
    public static let label = "LABEL"
    public static let group = "GROUP"
    public static let cc = "CC"
    public static let index = "INDEX"
    public static let level = "LEVEL"
}

/// vCard 4.0 KIND property values
public struct VCardKind {
    public static let individual = "individual"
    public static let group = "group"
    public static let org = "org"
    public static let location = "location"
    public static let application = "application"
    public static let device = "device"
}

// MARK: - Utility Types

/// Represents a preference value (1-100)
public struct VCardPreference: Sendable, Codable, Hashable {
    public let value: Int

    public init?(_ value: Int) {
        guard value >= 1 && value <= 100 else { return nil }
        self.value = value
    }

    public static let highest = VCardPreference(1)!
    public static let lowest = VCardPreference(100)!
    public static let `default` = VCardPreference(50)!
}

/// Represents a language tag
public struct VCardLanguageTag: Sendable, Codable, Hashable {
    public let tag: String

    public init(_ tag: String) {
        self.tag = tag
    }

    public static let english = VCardLanguageTag("en")
    public static let spanish = VCardLanguageTag("es")
    public static let french = VCardLanguageTag("fr")
    public static let german = VCardLanguageTag("de")
    public static let italian = VCardLanguageTag("it")
    public static let japanese = VCardLanguageTag("ja")
    public static let chinese = VCardLanguageTag("zh")
}

/// Represents an alternative ID for grouping related properties
public struct VCardAltId: Sendable, Codable, Hashable {
    public let id: String

    public init(_ id: String) {
        self.id = id
    }
}

/// Represents a property ID for tracking property instances
public struct VCardPropertyId: Sendable, Codable, Hashable {
    public let id: String

    public init(_ id: String) {
        self.id = id
    }
}

// MARK: - Date and Time Types

/// Represents a vCard date (can be partial)
public struct VCardDate: Sendable, Codable, Hashable {
    public let year: Int?
    public let month: Int?
    public let day: Int?

    public init(year: Int? = nil, month: Int? = nil, day: Int? = nil) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(date: Date) {
        // Use UTC calendar for server consistency
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let components = utcCalendar.dateComponents([.year, .month, .day], from: date)
        self.year = components.year
        self.month = components.month
        self.day = components.day
    }

    /// Convert to Foundation Date if complete
    public var date: Date? {
        guard let year = year, let month = month, let day = day else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        // Use UTC calendar for server consistency
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        return utcCalendar.date(from: components)
    }
}

/// Represents a vCard time
public struct VCardTime: Sendable, Codable, Hashable {
    public let hour: Int?
    public let minute: Int?
    public let second: Int?
    public let timeZone: TimeZone?

    public init(hour: Int? = nil, minute: Int? = nil, second: Int? = nil, timeZone: TimeZone? = nil) {
        self.hour = hour
        self.minute = minute
        self.second = second
        self.timeZone = timeZone
    }
}

/// Represents a vCard date-time
public struct VCardDateTime: Sendable, Codable, Hashable {
    public let date: VCardDate
    public let time: VCardTime?

    public init(date: VCardDate, time: VCardTime? = nil) {
        self.date = date
        self.time = time
    }

    public init(date: Date) {
        self.date = VCardDate(date: date)
        // Use UTC calendar for server consistency
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let components = utcCalendar.dateComponents([.hour, .minute, .second], from: date)
        self.time = VCardTime(
            hour: components.hour,
            minute: components.minute,
            second: components.second
        )
    }
}
