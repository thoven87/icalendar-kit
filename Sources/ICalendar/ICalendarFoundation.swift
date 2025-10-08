import Foundation

// MARK: - Core Protocol Definitions

/// Base protocol for all iCalendar components that can be parsed and serialized
public protocol ICalendarComponent: Sendable {
    /// The component name (e.g., "VEVENT", "VTODO", "VJOURNAL")
    static var componentName: String { get }

    /// Instance component name (allows dynamic component names)
    var instanceComponentName: String { get }

    /// Properties associated with this component
    var properties: [ICalendarProperty] { get set }

    /// Sub-components contained within this component
    var components: [any ICalendarComponent] { get set }

    /// Initialize from properties and components
    init(properties: [ICalendarProperty], components: [any ICalendarComponent])

    /// Validates this component against RFC 5545 rules
    func validate() -> ICalValidationResult

    /// Applies RFC 5545 compliance rules to this component
    mutating func applyCompliance()
}

extension ICalendarComponent {
    /// Default implementation uses static componentName
    public var instanceComponentName: String {
        Self.componentName
    }

    /// Default implementation returns success
    public func validate() -> ICalValidationResult {
        .success
    }

    /// Default implementation does nothing
    public mutating func applyCompliance() {
        // Default implementation - subclasses can override
    }
}

/// Protocol for properties that can appear in iCalendar components
public protocol ICalendarProperty: Sendable {
    /// The property name (e.g., "DTSTART", "SUMMARY", "DESCRIPTION")
    var name: String { get }

    /// The property value
    var value: String { get }

    /// Property parameters (e.g., TZID, VALUE, LANGUAGE)
    var parameters: [String: String] { get }

    /// Initialize with name, value, and parameters
    init(name: String, value: String, parameters: [String: String])
}

/// Protocol for parameter encoding/decoding
public protocol ICalendarParameter: Sendable {
    /// Parameter name
    var name: String { get }

    /// Parameter value
    var value: String { get }
}

// MARK: - Core Data Types

/// Represents an iCalendar property with name, value, and parameters
public struct ICalProperty: ICalendarProperty {
    public let name: String
    public let value: String
    public let parameters: [String: String]

    public init(name: String, value: String, parameters: [String: String] = [:]) {
        self.name = name
        self.value = value
        self.parameters = parameters
    }
}

/// Represents an iCalendar parameter
public struct ICalParameter: ICalendarParameter {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

// MARK: - Value Types

/// Represents different iCalendar value types
public enum ICalendarValueType: String, Sendable, CaseIterable, Codable {
    case binary = "BINARY"
    case boolean = "BOOLEAN"
    case calendarAddress = "CAL-ADDRESS"
    case date = "DATE"
    case dateTime = "DATE-TIME"
    case duration = "DURATION"
    case float = "FLOAT"
    case integer = "INTEGER"
    case period = "PERIOD"
    case recur = "RECUR"
    case text = "TEXT"
    case time = "TIME"
    case uri = "URI"
    case utcOffset = "UTC-OFFSET"
}

// MARK: - Status and Classification Types

/// Event status values
public enum ICalEventStatus: String, Sendable, CaseIterable, Codable {
    case tentative = "TENTATIVE"
    case confirmed = "CONFIRMED"
    case cancelled = "CANCELLED"
}

/// To-do status values
public enum ICalTodoStatus: String, Sendable, CaseIterable, Codable {
    case needsAction = "NEEDS-ACTION"
    case completed = "COMPLETED"
    case inProcess = "IN-PROCESS"
    case cancelled = "CANCELLED"
}

/// Journal status values
public enum ICalJournalStatus: String, Sendable, CaseIterable, Codable {
    case draft = "DRAFT"
    case final = "FINAL"
    case cancelled = "CANCELLED"
}

/// Classification values
public enum ICalClassification: String, Sendable, CaseIterable, Codable {
    case publicAccess = "PUBLIC"
    case privateAccess = "PRIVATE"
    case confidential = "CONFIDENTIAL"
}

/// Transparency values for events
public enum ICalTransparency: String, Sendable, CaseIterable, Codable {
    case opaque = "OPAQUE"
    case transparent = "TRANSPARENT"
}

// MARK: - Participant and Role Types

/// Calendar user type
public enum ICalUserType: String, Sendable, CaseIterable, Codable {
    case individual = "INDIVIDUAL"
    case group = "GROUP"
    case resource = "RESOURCE"
    case room = "ROOM"
    case unknown = "UNKNOWN"
}

/// Participation role
public enum ICalRole: String, Sendable, CaseIterable, Codable {
    case chair = "CHAIR"
    case requiredParticipant = "REQ-PARTICIPANT"
    case optionalParticipant = "OPT-PARTICIPANT"
    case nonParticipant = "NON-PARTICIPANT"
}

/// Participation status
public enum ICalParticipationStatus: String, Sendable, CaseIterable, Codable {
    case needsAction = "NEEDS-ACTION"
    case accepted = "ACCEPTED"
    case declined = "DECLINED"
    case tentative = "TENTATIVE"
    case delegated = "DELEGATED"
    case completed = "COMPLETED"
    case inProcess = "IN-PROCESS"
}

/// Relationship type
public enum ICalRelationshipType: String, Sendable, CaseIterable, Codable {
    case parent = "PARENT"
    case child = "CHILD"
    case sibling = "SIBLING"
}

// MARK: - RFC 7986 Extension Types

/// Display types for IMAGE property
public enum ICalDisplayType: String, Sendable, CaseIterable, Codable {
    case badge = "BADGE"
    case graphic = "GRAPHIC"
    case fullsize = "FULLSIZE"
    case thumbnail = "THUMBNAIL"
}

/// Feature types for CONFERENCE property
public enum ICalFeatureType: String, Sendable, CaseIterable, Codable {
    case audio = "AUDIO"
    case chat = "CHAT"
    case feed = "FEED"
    case moderator = "MODERATOR"
    case phone = "PHONE"
    case screen = "SCREEN"
    case video = "VIDEO"
}

/// Represents geographic coordinates
public struct ICalGeoCoordinate: Sendable, Codable, Hashable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// String representation in "latitude;longitude" format
    public var stringValue: String {
        String(format: "%.6f;%.6f", latitude, longitude)
    }

    /// Initialize from string in "latitude;longitude" format
    public init?(from string: String) {
        let components = string.components(separatedBy: ";")
        guard components.count == 2,
            let lat = Double(components[0]),
            let lon = Double(components[1])
        else {
            return nil
        }
        self.latitude = lat
        self.longitude = lon
    }
}

/// Represents timezone URL generation utilities
public struct ICalTimeZoneURLGenerator: Sendable {

    /// Generate TZURL for a given timezone identifier
    public static func generateTZURL(for timezoneId: String) -> String {
        "http://tzurl.org/zoneinfo-outlook/\(timezoneId)"
    }

    /// Generate alternative TZURL for a given timezone identifier
    public static func generateAlternativeTZURL(for timezoneId: String) -> String {
        "https://www.tzurl.org/zoneinfo-outlook/\(timezoneId)"
    }
}

// MARK: - Enhanced ATTACH Property Support

/// Represents attachment types for ATTACH property
public enum ICalAttachmentType: String, Sendable, CaseIterable, Codable {
    case uri = "URI"
    case binary = "BINARY"
}

/// Represents an iCalendar attachment
public struct ICalAttachment: Sendable, Codable, Hashable {
    public let type: ICalAttachmentType
    public let value: String
    public let mediaType: String?
    public let encoding: String?

    public init(uri: String, mediaType: String? = nil) {
        self.type = .uri
        self.value = uri
        self.mediaType = mediaType
        self.encoding = nil
    }

    public init(binaryData: Data, mediaType: String? = nil) {
        self.type = .binary
        self.value = binaryData.base64EncodedString()
        self.mediaType = mediaType
        self.encoding = "BASE64"
    }

    /// Get the decoded binary data (if this is a binary attachment)
    public var decodedData: Data? {
        guard type == .binary else { return nil }
        return Data(base64Encoded: value)
    }
}

// MARK: - RFC 9074 VALARM Extensions

/// Enhanced alarm action types (RFC 9074)
public enum ICalAlarmActionExtended: String, Sendable, CaseIterable, Codable {
    case display = "DISPLAY"
    case audio = "AUDIO"
    case email = "EMAIL"
    case proximity = "PROXIMITY"  // RFC 9074
}

/// Proximity trigger for location-based alarms (RFC 9074)
public struct ICalProximityTrigger: Sendable, Codable, Hashable {
    public let latitude: Double
    public let longitude: Double
    public let radius: Double  // meters
    public let entering: Bool  // true for entering, false for leaving

    public init(latitude: Double, longitude: Double, radius: Double, entering: Bool = true) {
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.entering = entering
    }

    /// String representation for PROXIMITY-TRIGGER property
    public var stringValue: String {
        let action = entering ? "ENTERING" : "LEAVING"
        return String(format: "%.6f;%.6f;%.6f;%@", latitude, longitude, radius, action)
    }

    /// Initialize from PROXIMITY-TRIGGER string
    public init?(from string: String) {
        let components = string.components(separatedBy: ";")
        guard components.count >= 4,
            let lat = Double(components[0]),
            let lon = Double(components[1]),
            let rad = Double(components[2])
        else { return nil }

        self.latitude = lat
        self.longitude = lon
        self.radius = rad
        self.entering = components[3].uppercased() == "ENTERING"
    }
}

/// Alarm acknowledgment information (RFC 9074)
public struct ICalAlarmAcknowledgment: Sendable, Codable, Hashable {
    public let acknowledgedAt: ICalDateTime
    public let acknowledgedBy: String?  // attendee who acknowledged

    public init(acknowledgedAt: ICalDateTime, acknowledgedBy: String? = nil) {
        self.acknowledgedAt = acknowledgedAt
        self.acknowledgedBy = acknowledgedBy
    }
}

// MARK: - RFC 9073 Event Publishing Extensions

/// Structured data types for STRUCTURED-DATA property (RFC 9073)
public enum ICalStructuredDataType: String, Sendable, CaseIterable, Codable {
    case json = "application/json"
    case xml = "application/xml"
    case vcard = "text/vcard"
    case custom = "text/plain"
}

/// Structured data container (RFC 9073)
public struct ICalStructuredData: Sendable, Codable, Hashable {
    public let type: ICalStructuredDataType
    public let data: String
    public let schema: String?  // Schema identifier

    public init(type: ICalStructuredDataType, data: String, schema: String? = nil) {
        self.type = type
        self.data = data
        self.schema = schema
    }
}

/// Enhanced location information for VLOCATION (RFC 9073)
public struct ICalEnhancedLocation: Sendable, Codable, Hashable {
    public let name: String
    public let description: String?
    public let geo: ICalGeoCoordinate?
    public let address: String?
    public let url: String?
    public let capacity: Int?
    public let accessibilityFeatures: [String]?
    public let structuredData: ICalStructuredData?

    public init(
        name: String,
        description: String? = nil,
        geo: ICalGeoCoordinate? = nil,
        address: String? = nil,
        url: String? = nil,
        capacity: Int? = nil,
        accessibilityFeatures: [String]? = nil,
        structuredData: ICalStructuredData? = nil
    ) {
        self.name = name
        self.description = description
        self.geo = geo
        self.address = address
        self.url = url
        self.capacity = capacity
        self.accessibilityFeatures = accessibilityFeatures
        self.structuredData = structuredData
    }
}

/// Resource information for VRESOURCE (RFC 9073)
public struct ICalResource: Sendable, Codable, Hashable {
    public let name: String
    public let description: String?
    public let resourceType: String  // Equipment, Room, Person, etc.
    public let capacity: Int?
    public let features: [String]?
    public let contact: String?
    public let bookingUrl: String?
    public let cost: String?

    public init(
        name: String,
        description: String? = nil,
        resourceType: String,
        capacity: Int? = nil,
        features: [String]? = nil,
        contact: String? = nil,
        bookingUrl: String? = nil,
        cost: String? = nil
    ) {
        self.name = name
        self.description = description
        self.resourceType = resourceType
        self.capacity = capacity
        self.features = features
        self.contact = contact
        self.bookingUrl = bookingUrl
        self.cost = cost
    }
}

// MARK: - RFC 9253 Enhanced Relationships

/// Enhanced relationship types (RFC 9253)
public enum ICalEnhancedRelationshipType: String, Sendable, CaseIterable, Codable {
    case parent = "PARENT"
    case child = "CHILD"
    case sibling = "SIBLING"
    case finishToStart = "FINISHTOSTART"
    case finishToFinish = "FINISHTOFINISH"
    case startToStart = "STARTTOSTART"
    case startToFinish = "STARTTOFINISH"
    case dependsOn = "DEPENDS-ON"
    case blocks = "BLOCKS"
}

/// Link to external resources (RFC 9253)
public struct ICalLink: Sendable, Codable, Hashable {
    public let href: String
    public let rel: String?  // relationship type
    public let type: String?  // media type
    public let title: String?
    public let language: String?

    public init(href: String, rel: String? = nil, type: String? = nil, title: String? = nil, language: String? = nil) {
        self.href = href
        self.rel = rel
        self.type = type
        self.title = title
        self.language = language
    }
}

/// Concept for semantic categorization (RFC 9253)
public struct ICalConcept: Sendable, Codable, Hashable {
    public let identifier: String
    public let scheme: String?  // URI of the concept scheme
    public let label: String?
    public let definition: String?

    public init(identifier: String, scheme: String? = nil, label: String? = nil, definition: String? = nil) {
        self.identifier = identifier
        self.scheme = scheme
        self.label = label
        self.definition = definition
    }
}

// MARK: - RFC 7953 Availability

/// Busy/Free status types (RFC 7953)
public enum ICalBusyType: String, Sendable, CaseIterable, Codable {
    case busy = "BUSY"
    case free = "FREE"
    case busyUnavailable = "BUSY-UNAVAILABLE"
    case busyTentative = "BUSY-TENTATIVE"
}

/// Availability information (RFC 7953)
public struct ICalAvailability: Sendable, Codable, Hashable {
    public let start: ICalDateTime
    public let end: ICalDateTime?
    public let duration: ICalDuration?
    public let busyType: ICalBusyType
    public let summary: String?
    public let description: String?
    public let location: String?

    public init(
        start: ICalDateTime,
        end: ICalDateTime? = nil,
        duration: ICalDuration? = nil,
        busyType: ICalBusyType,
        summary: String? = nil,
        description: String? = nil,
        location: String? = nil
    ) {
        self.start = start
        self.end = end
        self.duration = duration
        self.busyType = busyType
        self.summary = summary
        self.description = description
        self.location = location
    }
}

// MARK: - RFC 6047 iMIP Transport

/// Email transport information for iMIP (RFC 6047)
public struct ICalEmailTransport: Sendable, Codable, Hashable {
    public let from: String
    public let to: [String]
    public let cc: [String]?
    public let bcc: [String]?
    public let subject: String
    public let messageId: String?
    public let inReplyTo: String?
    public let references: [String]?

    public init(
        from: String,
        to: [String],
        cc: [String]? = nil,
        bcc: [String]? = nil,
        subject: String,
        messageId: String? = nil,
        inReplyTo: String? = nil,
        references: [String]? = nil
    ) {
        self.from = from
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.messageId = messageId
        self.inReplyTo = inReplyTo
        self.references = references
    }
}

// MARK: - Error Types

/// Errors that can occur during iCalendar parsing or creation
public enum ICalendarError: Error, Sendable {
    case invalidFormat(String)
    case missingRequiredProperty(String)
    case invalidPropertyValue(property: String, value: String)
    case invalidDateFormat(String)
    case invalidDuration(String)
    case invalidRecurrenceRule(String)
    case unsupportedComponent(String)
    case encodingError(String)
    case decodingError(String)
    case invalidParameterValue(parameter: String, value: String)
    case dateCalculationFailed(String)
    case invalidCalendarOperation(String)
}

// MARK: - Constants

/// Common iCalendar property names
public struct ICalPropertyName {
    public static let version = "VERSION"
    public static let productId = "PRODID"
    public static let calendarScale = "CALSCALE"
    public static let method = "METHOD"

    // Event properties
    public static let uid = "UID"
    public static let dateTimeStamp = "DTSTAMP"
    public static let dateTimeStart = "DTSTART"
    public static let dateTimeEnd = "DTEND"
    public static let duration = "DURATION"
    public static let summary = "SUMMARY"
    public static let description = "DESCRIPTION"
    public static let location = "LOCATION"
    public static let status = "STATUS"
    public static let transparency = "TRANSP"
    public static let classification = "CLASS"
    public static let priority = "PRIORITY"
    public static let sequence = "SEQUENCE"
    public static let recurrenceRule = "RRULE"
    public static let recurrenceId = "RECURRENCE-ID"
    public static let exceptionDates = "EXDATE"
    public static let recurrenceDates = "RDATE"
    public static let organizer = "ORGANIZER"
    public static let attendee = "ATTENDEE"
    public static let categories = "CATEGORIES"
    public static let comment = "COMMENT"
    public static let contact = "CONTACT"
    public static let relatedTo = "RELATED-TO"
    public static let url = "URL"
    public static let attach = "ATTACH"
    public static let alarm = "VALARM"
    public static let created = "CREATED"
    public static let lastModified = "LAST-MODIFIED"

    // Alarm properties
    public static let action = "ACTION"
    public static let trigger = "TRIGGER"
    public static let repeatCount = "REPEAT"

    // Time zone properties
    public static let timeZoneId = "TZID"
    public static let timeZoneName = "TZNAME"
    public static let timeZoneOffsetFrom = "TZOFFSETFROM"
    public static let timeZoneOffsetTo = "TZOFFSETTO"
    public static let timeZoneUrl = "TZURL"

    // RFC 7986 Extension properties
    public static let name = "NAME"
    public static let color = "COLOR"
    public static let image = "IMAGE"
    public static let source = "SOURCE"
    public static let refreshInterval = "REFRESH-INTERVAL"
    public static let conference = "CONFERENCE"
    public static let geo = "GEO"

    // X-WR Extension properties (Apple/CalDAV)
    public static let xWrCalName = "X-WR-CALNAME"
    public static let xWrCalDesc = "X-WR-CALDESC"
    public static let xWrRelCalId = "X-WR-RELCALID"
    public static let xWrTimeZone = "X-WR-TIMEZONE"
    public static let xPublishedTTL = "X-PUBLISHED-TTL"
    public static let xLicLocation = "X-LIC-LOCATION"

    // Microsoft Extension properties
    public static let xAltDesc = "X-ALT-DESC"

    // RFC 7529 Non-Gregorian Recurrence
    public static let rscale = "RSCALE"

    // RFC 9074 VALARM Extensions
    public static let proximityTrigger = "PROXIMITY-TRIGGER"
    public static let acknowledged = "ACKNOWLEDGED"

    // RFC 9073 Event Publishing Extensions
    public static let structuredData = "STRUCTURED-DATA"
    public static let venue = "VENUE"
    public static let enhancedLocation = "ENHANCED-LOCATION"
    public static let resource = "RESOURCE"

    // RFC 9253 Enhanced Relationships
    public static let link = "LINK"
    public static let concept = "CONCEPT"
    public static let refId = "REFID"

    // RFC 7953 Availability
    public static let busyType = "BUSYTYPE"
    public static let available = "AVAILABLE"
    public static let busy = "BUSY"
}

/// Common iCalendar parameter names
public struct ICalParameterName {
    public static let alternateRepresentation = "ALTREP"
    public static let commonName = "CN"
    public static let calendarUserType = "CUTYPE"
    public static let delegatedFrom = "DELEGATED-FROM"
    public static let delegatedTo = "DELEGATED-TO"
    public static let directory = "DIR"
    public static let encoding = "ENCODING"
    public static let formatType = "FMTTYPE"
    public static let freeBusyType = "FBTYPE"
    public static let language = "LANGUAGE"
    public static let member = "MEMBER"
    public static let participationStatus = "PARTSTAT"
    public static let range = "RANGE"
    public static let related = "RELATED"
    public static let relationshipType = "RELTYPE"
    public static let role = "ROLE"
    public static let rsvp = "RSVP"
    public static let sentBy = "SENT-BY"
    public static let timeZoneId = "TZID"
    public static let valueType = "VALUE"

    // RFC 7986 Extension parameters
    public static let display = "DISPLAY"
    public static let email = "EMAIL"
    public static let feature = "FEATURE"
    public static let label = "LABEL"

    // RFC 7529 Non-Gregorian parameters
    public static let rscale = "RSCALE"

    // RFC 9074 VALARM Extension parameters
    public static let proximity = "PROXIMITY"
    public static let acknowledgedBy = "ACKNOWLEDGED-BY"

    // RFC 9073 Event Publishing parameters
    public static let schema = "SCHEMA"
    public static let structuredDataType = "STRUCTURED-DATA-TYPE"

    // RFC 9253 Enhanced Relationship parameters
    public static let href = "HREF"
    public static let rel = "REL"
    public static let title = "TITLE"
    public static let scheme = "SCHEME"

    // RFC 7953 Availability parameters
    public static let busyStatus = "BUSY-STATUS"
}
