import Foundation

// MARK: - Event Component

/// Represents a calendar event (VEVENT)
public struct ICalEvent: ICalendarComponent, ICalendarBuildable, Sendable {
    public static let componentName = "VEVENT"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Unique identifier for the event
    public var uid: String {
        get { getPropertyValue(ICalPropertyName.uid) ?? UUID().uuidString }
        set { setPropertyValue(ICalPropertyName.uid, value: newValue) }
    }

    /// Date-time stamp (when the event was created/last modified)
    public var dateTimeStamp: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStamp) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStamp, value: newValue) }
    }

    /// Start date and time
    public var dateTimeStart: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStart) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStart, value: newValue) }
    }

    /// End date and time
    public var dateTimeEnd: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeEnd) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeEnd, value: newValue) }
    }

    /// Duration of the event
    public var duration: ICalDuration? {
        get { getDurationProperty(ICalPropertyName.duration) }
        set { setDurationProperty(ICalPropertyName.duration, value: newValue) }
    }

    /// Event summary/title
    public var summary: String? {
        get { getPropertyValue(ICalPropertyName.summary) }
        set { setPropertyValue(ICalPropertyName.summary, value: newValue) }
    }

    /// Event description
    public var description: String? {
        get { getPropertyValue(ICalPropertyName.description) }
        set { setPropertyValue(ICalPropertyName.description, value: newValue) }
    }

    /// Event location
    public var location: String? {
        get { getPropertyValue(ICalPropertyName.location) }
        set { setPropertyValue(ICalPropertyName.location, value: newValue) }
    }

    /// Event status
    public var status: ICalEventStatus? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.status) else { return nil }
            return ICalEventStatus(rawValue: value)
        }
        set { setPropertyValue(ICalPropertyName.status, value: newValue?.rawValue) }
    }

    /// Event transparency
    public var transparency: ICalTransparency? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.transparency) else { return nil }
            return ICalTransparency(rawValue: value)
        }
        set { setPropertyValue(ICalPropertyName.transparency, value: newValue?.rawValue) }
    }

    /// Event classification
    public var classification: ICalClassification? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.classification) else { return nil }
            return ICalClassification(rawValue: value)
        }
        set { setPropertyValue(ICalPropertyName.classification, value: newValue?.rawValue) }
    }

    /// Event priority (0-9, where 0 is undefined)
    public var priority: Int? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.priority) else { return nil }
            return Int(value)
        }
        set { setPropertyValue(ICalPropertyName.priority, value: newValue?.description) }
    }

    /// Sequence number for updates
    public var sequence: Int? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.sequence) else { return nil }
            return Int(value)
        }
        set { setPropertyValue(ICalPropertyName.sequence, value: newValue?.description) }
    }

    /// Recurrence rule
    public var recurrenceRule: ICalRecurrenceRule? {
        get { getRecurrenceRuleProperty(ICalPropertyName.recurrenceRule) }
        set { setRecurrenceRuleProperty(ICalPropertyName.recurrenceRule, value: newValue) }
    }

    /// Exception dates - dates when recurring event should not occur
    public var exceptionDates: [ICalDateTime] {
        get { getDateListProperty(ICalPropertyName.exceptionDates) }
        set { setDateListProperty(ICalPropertyName.exceptionDates, values: newValue) }
    }

    /// Event organizer
    public var organizer: ICalAttendee? {
        get { getAttendeeProperty(ICalPropertyName.organizer) }
        set { setAttendeeProperty(ICalPropertyName.organizer, value: newValue) }
    }

    /// Event attendees
    public var attendees: [ICalAttendee] {
        get { getAttendeesProperty(ICalPropertyName.attendee) }
        set { setAttendeesProperty(ICalPropertyName.attendee, values: newValue) }
    }

    /// Event categories
    public var categories: [String] {
        get { getCategoriesProperty() }
        set { setCategoriesProperty(newValue) }
    }

    /// Event URL
    public var url: String? {
        get { getPropertyValue(ICalPropertyName.url) }
        set { setPropertyValue(ICalPropertyName.url, value: newValue) }
    }

    /// Creation date
    public var created: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.created) }
        set { setDateTimeProperty(ICalPropertyName.created, value: newValue) }
    }

    /// Last modified date
    public var lastModified: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.lastModified) }
        set { setDateTimeProperty(ICalPropertyName.lastModified, value: newValue) }
    }

    /// Enhanced attachment support with binary and URI
    public var attachments: [ICalAttachment] {
        get {
            let attachProperties = properties.filter { $0.name == ICalPropertyName.attach }
            return attachProperties.compactMap { property in
                if property.parameters[ICalParameterName.encoding] == "BASE64" {
                    guard let data = Data(base64Encoded: property.value) else { return nil }
                    return ICalAttachment(binaryData: data, mediaType: property.parameters[ICalParameterName.formatType])
                } else {
                    return ICalAttachment(uri: property.value, mediaType: property.parameters[ICalParameterName.formatType])
                }
            }
        }
        set {
            // Remove existing ATTACH properties
            properties.removeAll { $0.name == ICalPropertyName.attach }

            // Add new attachment properties
            for attachment in newValue {
                var parameters: [String: String] = [:]

                if let mediaType = attachment.mediaType {
                    parameters[ICalParameterName.formatType] = mediaType
                }

                if attachment.type == .binary {
                    parameters[ICalParameterName.encoding] = "BASE64"
                    parameters[ICalParameterName.valueType] = "BINARY"
                } else {
                    parameters[ICalParameterName.valueType] = "URI"
                }

                let property = ICalProperty(name: ICalPropertyName.attach, value: attachment.value, parameters: parameters)
                properties.append(property)
            }
        }
    }

    // MARK: - RFC 7986 Extension Properties

    /// Event color
    public var color: String? {
        get { getPropertyValue(ICalPropertyName.color) }
        set { setPropertyValue(ICalPropertyName.color, value: newValue) }
    }

    /// Event image
    public var image: String? {
        get { getPropertyValue(ICalPropertyName.image) }
        set { setPropertyValue(ICalPropertyName.image, value: newValue) }
    }

    /// Images associated with the event
    public var images: [String] {
        get {
            properties
                .filter { $0.name == ICalPropertyName.image }
                .map { $0.value }
        }
        set {
            properties.removeAll { $0.name == ICalPropertyName.image }
            for image in newValue {
                properties.append(ICalProperty(name: ICalPropertyName.image, value: image))
            }
        }
    }

    /// Conference information for the event
    public var conferences: [String] {
        get {
            properties
                .filter { $0.name == ICalPropertyName.conference }
                .map { $0.value }
        }
        set {
            properties.removeAll { $0.name == ICalPropertyName.conference }
            for conference in newValue {
                properties.append(ICalProperty(name: ICalPropertyName.conference, value: conference))
            }
        }
    }

    /// Geographic coordinates for the event
    public var geo: ICalGeoCoordinate? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.geo) else { return nil }
            return ICalGeoCoordinate(from: value)
        }
        set { setPropertyValue(ICalPropertyName.geo, value: newValue?.stringValue) }
    }

    /// Alarms associated with this event
    /// Event alarms
    public var alarms: [ICalAlarm] {
        get { components.compactMap { $0 as? ICalAlarm } }
        set { components = components.filter { !($0 is ICalAlarm) } + newValue }
    }

    /// RFC 9253: Enhanced relationships
    public var enhancedRelationships: [(uid: String, type: ICalEnhancedRelationshipType)] {
        get {
            properties
                .filter { $0.name == ICalPropertyName.relatedTo }
                .compactMap { property in
                    let uid = property.value
                    let relType = property.parameters[ICalParameterName.relationshipType] ?? "PARENT"
                    guard let type = ICalEnhancedRelationshipType(rawValue: relType) else { return nil }
                    return (uid: uid, type: type)
                }
        }
        set {
            // Remove existing RELATED-TO properties
            properties.removeAll { $0.name == ICalPropertyName.relatedTo }

            // Add new RELATED-TO properties
            for relationship in newValue {
                var parameters: [String: String] = [:]
                parameters[ICalParameterName.relationshipType] = relationship.type.rawValue

                let property = ICalProperty(
                    name: ICalPropertyName.relatedTo,
                    value: relationship.uid,
                    parameters: parameters
                )
                properties.append(property)
            }
        }
    }

    /// RFC 9253: External links
    public var links: [ICalLink] {
        get {
            properties
                .filter { $0.name == ICalPropertyName.link }
                .compactMap { property in
                    let href = property.value
                    let rel = property.parameters[ICalParameterName.rel]
                    let type = property.parameters[ICalParameterName.formatType]
                    let title = property.parameters[ICalParameterName.title]
                    let language = property.parameters[ICalParameterName.language]
                    return ICalLink(href: href, rel: rel, type: type, title: title, language: language)
                }
        }
        set {
            // Remove existing LINK properties
            properties.removeAll { $0.name == ICalPropertyName.link }

            // Add new LINK properties
            for link in newValue {
                var parameters: [String: String] = [:]
                if let rel = link.rel { parameters[ICalParameterName.rel] = rel }
                if let type = link.type { parameters[ICalParameterName.formatType] = type }
                if let title = link.title { parameters[ICalParameterName.title] = title }
                if let language = link.language { parameters[ICalParameterName.language] = language }

                let property = ICalProperty(
                    name: ICalPropertyName.link,
                    value: link.href,
                    parameters: parameters
                )
                properties.append(property)
            }
        }
    }

    /// RFC 9253: Semantic concepts
    public var concepts: [ICalConcept] {
        get {
            properties
                .filter { $0.name == ICalPropertyName.concept }
                .compactMap { property in
                    let identifier = property.value
                    let scheme = property.parameters[ICalParameterName.scheme]
                    let label = property.parameters[ICalParameterName.label]
                    let definition = property.parameters["DEFINITION"]
                    return ICalConcept(identifier: identifier, scheme: scheme, label: label, definition: definition)
                }
        }
        set {
            // Remove existing CONCEPT properties
            properties.removeAll { $0.name == ICalPropertyName.concept }

            // Add new CONCEPT properties
            for concept in newValue {
                var parameters: [String: String] = [:]
                if let scheme = concept.scheme { parameters[ICalParameterName.scheme] = scheme }
                if let label = concept.label { parameters[ICalParameterName.label] = label }
                if let definition = concept.definition { parameters["DEFINITION"] = definition }

                let property = ICalProperty(
                    name: ICalPropertyName.concept,
                    value: concept.identifier,
                    parameters: parameters
                )
                properties.append(property)
            }
        }
    }

    /// RFC 9253: Reference identifier for grouping
    public var referenceId: String? {
        get { getPropertyValue(ICalPropertyName.refId) }
        set { setPropertyValue(ICalPropertyName.refId, value: newValue) }
    }

    /// RFC 9073: Structured data
    public var structuredData: ICalStructuredData? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.structuredData) else { return nil }

            // Get type, default to JSON if not specified
            let dataType: ICalStructuredDataType
            if let typeString = getPropertyValue("STRUCTURED-DATA-TYPE") {
                dataType = ICalStructuredDataType(rawValue: typeString) ?? .json
            } else {
                dataType = .json
            }

            let schema = getPropertyValue("SCHEMA")
            return ICalStructuredData(type: dataType, data: value, schema: schema)
        }
        set {
            setPropertyValue(ICalPropertyName.structuredData, value: newValue?.data)
            setPropertyValue("STRUCTURED-DATA-TYPE", value: newValue?.type.rawValue)
            setPropertyValue("SCHEMA", value: newValue?.schema)
        }
    }

    /// RFC 9073: Associated venues
    public var venues: [ICalVenue] {
        get { components.compactMap { $0 as? ICalVenue } }
        set {
            components = components.filter { !($0 is ICalVenue) } + newValue
        }
    }

    /// RFC 9073: Associated locations
    public var locations: [ICalLocationComponent] {
        get { components.compactMap { $0 as? ICalLocationComponent } }
        set {
            components = components.filter { !($0 is ICalLocationComponent) } + newValue
        }
    }

    /// RFC 9073: Associated resources
    public var resources: [ICalResourceComponent] {
        get { components.compactMap { $0 as? ICalResourceComponent } }
        set {
            components = components.filter { !($0 is ICalResourceComponent) } + newValue
        }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components
    }

    public init(uid: String = UUID().uuidString, summary: String) {
        self.properties = [
            ICalProperty(name: ICalPropertyName.uid, value: uid),
            ICalProperty(name: ICalPropertyName.summary, value: summary),
            ICalProperty(name: ICalPropertyName.dateTimeStamp, value: ICalendarFormatter.format(dateTime: Date().asICalDateTimeUTC())),
        ]
        self.components = []
    }

    /// Result builder constructor for ICalEvent with properties
    public init(uid: String, @ICalendarBuilder content: () -> [any ICalendarBuildable]) {
        self.properties = [
            ICalProperty(name: ICalPropertyName.uid, value: uid),
            ICalProperty(name: ICalPropertyName.dateTimeStamp, value: ICalendarFormatter.format(dateTime: Date().asICalDateTimeUTC())),
        ]
        self.components = []

        let buildableItems = content()
        for item in buildableItems {
            switch item.build() {
            case .single(let buildable):
                if let component = buildable as? ComponentBuildable {
                    self.components.append(component.component)
                } else if let property = buildable as? PropertyBuildable {
                    self.properties.append(property.property)
                }
            case .multiple(let buildables):
                for buildable in buildables {
                    if let component = buildable as? ComponentBuildable {
                        self.components.append(component.component)
                    } else if let property = buildable as? PropertyBuildable {
                        self.properties.append(property.property)
                    }
                }
            }
        }
    }

    /// ICalendarBuildable conformance
    public func build() -> BuildResult {
        .single(ComponentBuildable(component: self))
    }

    /// Add an alarm to the event
    public mutating func addAlarm(_ alarm: ICalAlarm) {
        components.append(alarm)
    }

    /// Add a venue to the event (RFC 9073)
    public mutating func addVenue(_ venue: ICalVenue) {
        components.append(venue)
    }

    /// Add a location to the event (RFC 9073)
    public mutating func addLocation(_ location: ICalLocationComponent) {
        components.append(location)
    }

    /// Add a resource to the event (RFC 9073)
    public mutating func addResource(_ resource: ICalResourceComponent) {
        components.append(resource)
    }

}
