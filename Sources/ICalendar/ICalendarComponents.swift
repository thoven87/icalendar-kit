import Foundation

// MARK: - Todo Component

/// Represents a to-do item (VTODO)
public struct ICalTodo: ICalendarComponent, Sendable {
    public static let componentName = "VTODO"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Unique identifier
    public var uid: String {
        get { getPropertyValue(ICalPropertyName.uid) ?? UUID().uuidString }
        set { setPropertyValue(ICalPropertyName.uid, value: newValue) }
    }

    /// Date-time stamp (required by RFC 5545)
    public var dateTimeStamp: ICalDateTime {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStamp)! }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStamp, value: newValue) }
    }

    /// Start date and time
    public var dateTimeStart: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStart) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStart, value: newValue) }
    }

    /// Due date and time
    public var dueDate: ICalDateTime? {
        get { getDateTimeProperty("DUE") }
        set { setDateTimeProperty("DUE", value: newValue) }
    }

    /// Completion date and time
    public var completed: ICalDateTime? {
        get { getDateTimeProperty("COMPLETED") }
        set { setDateTimeProperty("COMPLETED", value: newValue) }
    }

    /// Duration
    public var duration: ICalDuration? {
        get { getDurationProperty(ICalPropertyName.duration) }
        set { setDurationProperty(ICalPropertyName.duration, value: newValue) }
    }

    /// Summary
    public var summary: String? {
        get { getPropertyValue(ICalPropertyName.summary) }
        set { setPropertyValue(ICalPropertyName.summary, value: newValue) }
    }

    /// Description
    public var description: String? {
        get { getPropertyValue(ICalPropertyName.description) }
        set { setPropertyValue(ICalPropertyName.description, value: newValue) }
    }

    /// Status
    public var status: ICalTodoStatus? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.status) else { return nil }
            return ICalTodoStatus(rawValue: value)
        }
        set { setPropertyValue(ICalPropertyName.status, value: newValue?.rawValue) }
    }

    /// Priority
    public var priority: Int? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.priority) else { return nil }
            return Int(value)
        }
        set { setPropertyValue(ICalPropertyName.priority, value: newValue?.description) }
    }

    /// Percent complete
    public var percentComplete: Int? {
        get {
            guard let value = getPropertyValue("PERCENT-COMPLETE") else { return nil }
            return Int(value)
        }
        set { setPropertyValue("PERCENT-COMPLETE", value: newValue?.description) }
    }

    /// Organizer
    public var organizer: ICalAttendee? {
        get { getAttendeeProperty(ICalPropertyName.organizer) }
        set { setAttendeeProperty(ICalPropertyName.organizer, value: newValue) }
    }

    /// Attendees
    public var attendees: [ICalAttendee] {
        get { getAttendeesProperty(ICalPropertyName.attendee) }
        set { setAttendeesProperty(ICalPropertyName.attendee, values: newValue) }
    }

    /// Categories
    public var categories: [String] {
        get { getCategoriesProperty() }
        set { setCategoriesProperty(newValue) }
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

    /// Todo color
    public var color: String? {
        get { getPropertyValue(ICalPropertyName.color) }
        set { setPropertyValue(ICalPropertyName.color, value: newValue) }
    }

    /// Images associated with the todo
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

    /// Conference information for the todo
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

    /// Geographic coordinates for the todo
    public var geo: ICalGeoCoordinate? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.geo) else { return nil }
            return ICalGeoCoordinate(from: value)
        }
        set { setPropertyValue(ICalPropertyName.geo, value: newValue?.stringValue) }
    }

    /// Alarms
    public var alarms: [ICalAlarm] {
        components.compactMap { $0 as? ICalAlarm }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components

        // Ensure required properties are set
        if getPropertyValue(ICalPropertyName.uid) == nil {
            setPropertyValue(ICalPropertyName.uid, value: UUID().uuidString)
        }
        if getDateTimeProperty(ICalPropertyName.dateTimeStamp) == nil {
            setDateTimeProperty(ICalPropertyName.dateTimeStamp, value: ICalDateTime(date: Date()))
        }
    }

    public init(uid: String = UUID().uuidString, summary: String) {
        let now = ICalDateTime(date: Date())
        self.properties = [
            ICalProperty(name: ICalPropertyName.uid, value: uid),
            ICalProperty(name: ICalPropertyName.dateTimeStamp, value: ICalendarFormatter.format(dateTime: now)),
            ICalProperty(name: ICalPropertyName.summary, value: summary),
        ]
        self.components = []
    }

    /// Add an alarm to this todo
    public mutating func addAlarm(_ alarm: ICalAlarm) {
        components.append(alarm)
    }
}

// MARK: - Journal Component

/// Represents a journal entry (VJOURNAL)
public struct ICalJournal: ICalendarComponent, Sendable {
    public static let componentName = "VJOURNAL"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Unique identifier
    public var uid: String {
        get { getPropertyValue(ICalPropertyName.uid) ?? UUID().uuidString }
        set { setPropertyValue(ICalPropertyName.uid, value: newValue) }
    }

    /// Date-time stamp (required by RFC 5545)
    public var dateTimeStamp: ICalDateTime {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStamp) ?? ICalDateTime(date: Date()) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStamp, value: newValue) }
    }

    /// Start date and time
    public var dateTimeStart: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStart) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStart, value: newValue) }
    }

    /// Summary
    public var summary: String? {
        get { getPropertyValue(ICalPropertyName.summary) }
        set { setPropertyValue(ICalPropertyName.summary, value: newValue) }
    }

    /// Description
    public var description: String? {
        get { getPropertyValue(ICalPropertyName.description) }
        set { setPropertyValue(ICalPropertyName.description, value: newValue) }
    }

    /// Status
    public var status: ICalJournalStatus? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.status) else { return nil }
            return ICalJournalStatus(rawValue: value)
        }
        set { setPropertyValue(ICalPropertyName.status, value: newValue?.rawValue) }
    }

    /// Classification
    public var classification: ICalClassification? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.classification) else { return nil }
            return ICalClassification(rawValue: value)
        }
        set { setPropertyValue(ICalPropertyName.classification, value: newValue?.rawValue) }
    }

    /// Organizer
    public var organizer: ICalAttendee? {
        get { getAttendeeProperty(ICalPropertyName.organizer) }
        set { setAttendeeProperty(ICalPropertyName.organizer, value: newValue) }
    }

    /// Attendees
    public var attendees: [ICalAttendee] {
        get { getAttendeesProperty(ICalPropertyName.attendee) }
        set { setAttendeesProperty(ICalPropertyName.attendee, values: newValue) }
    }

    /// Categories
    public var categories: [String] {
        get { getCategoriesProperty() }
        set { setCategoriesProperty(newValue) }
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

    /// Journal color
    public var color: String? {
        get { getPropertyValue(ICalPropertyName.color) }
        set { setPropertyValue(ICalPropertyName.color, value: newValue) }
    }

    /// Images associated with the journal
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

    /// Geographic coordinates for the journal
    public var geo: ICalGeoCoordinate? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.geo) else { return nil }
            return ICalGeoCoordinate(from: value)
        }
        set { setPropertyValue(ICalPropertyName.geo, value: newValue?.stringValue) }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components

        // Ensure required properties are set
        if getPropertyValue(ICalPropertyName.uid) == nil {
            setPropertyValue(ICalPropertyName.uid, value: UUID().uuidString)
        }
        if getDateTimeProperty(ICalPropertyName.dateTimeStamp) == nil {
            setDateTimeProperty(ICalPropertyName.dateTimeStamp, value: ICalDateTime(date: Date()))
        }
    }

    public init(uid: String = UUID().uuidString, summary: String) {
        let now = ICalDateTime(date: Date())
        self.properties = [
            ICalProperty(name: ICalPropertyName.uid, value: uid),
            ICalProperty(name: ICalPropertyName.dateTimeStamp, value: ICalendarFormatter.format(dateTime: now)),
            ICalProperty(name: ICalPropertyName.summary, value: summary),
        ]
        self.components = []
    }
}

// MARK: - Alarm Component

/// Alarm action types
public enum ICalAlarmAction: String, Sendable, CaseIterable, Codable {
    case audio = "AUDIO"
    case display = "DISPLAY"
    case email = "EMAIL"
    case procedure = "PROCEDURE"
    case proximity = "PROXIMITY"  // RFC 9074
}

// MARK: - Type-Safe Alarm Types

/// RFC 5545 compliant alarm types that encode requirements in the type system
public enum ICalAlarmType: Sendable {
    case audio(AudioAlarm)
    case display(DisplayAlarm)
    case email(EmailAlarm)
    case proximity(ProximityAlarm)  // RFC 9074
}

/// Audio alarm - only requires ACTION and TRIGGER (RFC 5545)
public struct AudioAlarm: Sendable, Hashable, Codable {
    public let trigger: String
    public let attachment: ICalAttachment?
    public let duration: ICalDuration?
    public let repeatCount: Int?

    /// Create audio alarm (duration and repeatCount must both be provided or both be nil)
    public init(
        trigger: String,
        attachment: ICalAttachment? = nil
    ) {
        self.trigger = trigger
        self.attachment = attachment
        self.duration = nil
        self.repeatCount = nil
    }

    /// Create repeating audio alarm (both duration and repeatCount required)
    public init(
        trigger: String,
        attachment: ICalAttachment? = nil,
        duration: ICalDuration,
        repeatCount: Int
    ) {
        self.trigger = trigger
        self.attachment = attachment
        self.duration = duration
        self.repeatCount = repeatCount
    }
}

/// Display alarm - requires ACTION, TRIGGER, and DESCRIPTION (RFC 5545)
public struct DisplayAlarm: Sendable, Hashable, Codable {
    public let trigger: String
    public let description: String
    public let duration: ICalDuration?
    public let repeatCount: Int?

    /// Create display alarm (required: trigger and description)
    public init(trigger: String, description: String) {
        self.trigger = trigger
        self.description = description
        self.duration = nil
        self.repeatCount = nil
    }

    /// Create repeating display alarm (both duration and repeatCount required)
    public init(
        trigger: String,
        description: String,
        duration: ICalDuration,
        repeatCount: Int
    ) {
        self.trigger = trigger
        self.description = description
        self.duration = duration
        self.repeatCount = repeatCount
    }
}

/// Email alarm - requires ACTION, TRIGGER, DESCRIPTION, SUMMARY, and ATTENDEES (RFC 5545)
public struct EmailAlarm: Sendable, Hashable, Codable {
    public let trigger: String
    public let description: String
    public let summary: String
    public let attendees: [ICalAttendee]
    public let attachments: [ICalAttachment]
    public let duration: ICalDuration?
    public let repeatCount: Int?

    /// Create email alarm with array of attendees (primary initializer)
    public init(
        trigger: String,
        description: String,
        summary: String,
        attendees: [ICalAttendee],
        attachments: [ICalAttachment] = [],
        duration: ICalDuration? = nil,
        repeatCount: Int? = nil
    ) throws {
        guard !attendees.isEmpty else {
            throw ICalendarError.emailAlarmRequiresAttendees
        }

        // RFC 5545: DURATION and REPEAT must both be present or both absent
        if (duration != nil && repeatCount == nil) || (duration == nil && repeatCount != nil) {
            throw ICalendarError.durationRepeatMismatch
        }

        self.trigger = trigger
        self.description = description
        self.summary = summary
        self.attendees = attendees
        self.attachments = attachments
        self.duration = duration
        self.repeatCount = repeatCount
    }

    /// Convenience initializer with variadic attendees for clean API
    public init(
        trigger: String,
        description: String,
        summary: String,
        attendees: ICalAttendee...,
        attachments: [ICalAttachment] = [],
        duration: ICalDuration? = nil,
        repeatCount: Int? = nil
    ) throws {
        try self.init(
            trigger: trigger,
            description: description,
            summary: summary,
            attendees: Array(attendees),
            attachments: attachments,
            duration: duration,
            repeatCount: repeatCount
        )
    }
}

/// Proximity alarm - RFC 9074 extension for location-based alarms
public struct ProximityAlarm: Sendable, Hashable, Codable {
    public let proximityTrigger: ICalProximityTrigger
    public let description: String?
    public let duration: ICalDuration?
    public let repeatCount: Int?

    /// Create proximity alarm (proximityTrigger required)
    public init(
        proximityTrigger: ICalProximityTrigger,
        description: String? = nil
    ) {
        self.proximityTrigger = proximityTrigger
        self.description = description
        self.duration = nil
        self.repeatCount = nil
    }

    /// Create repeating proximity alarm (duration and repeatCount required)
    public init(
        proximityTrigger: ICalProximityTrigger,
        description: String? = nil,
        duration: ICalDuration,
        repeatCount: Int
    ) {
        self.proximityTrigger = proximityTrigger
        self.description = description
        self.duration = duration
        self.repeatCount = repeatCount
    }
}

// MARK: - ICalAlarm

/// RFC 5545 compliant alarm that can only be created in valid states
public struct ICalAlarm: ICalendarComponent, Sendable {
    public static let componentName = "VALARM"

    public let type: ICalAlarmType
    public let uid: String?
    public let acknowledgment: ICalAlarmAcknowledgment?
    public let relatedAlarms: [String]

    // ICalendarComponent protocol requirements
    public var properties: [ICalendarProperty] {
        get { generateProperties() }
        set {
            // Properties are read-only in type-safe alarms since they're generated from the alarm type.
            // This setter exists only for ICalendarComponent protocol conformance but is intentionally no-op.
            // To modify an alarm, create a new instance with the desired type.
        }
    }
    public var components: [any ICalendarComponent] {
        get { [] }
        set {
            // Components are always empty for alarms since VALARM cannot contain sub-components per RFC 5545.
            // This setter exists only for ICalendarComponent protocol conformance but is intentionally no-op.
        }
    }

    public init(
        type: ICalAlarmType,
        uid: String? = nil,
        acknowledgment: ICalAlarmAcknowledgment? = nil,
        relatedAlarms: [String] = []
    ) {
        self.type = type
        self.uid = uid
        self.acknowledgment = acknowledgment
        self.relatedAlarms = relatedAlarms
    }

    /// Convenience initializers for each alarm type
    public init(audio: AudioAlarm, uid: String? = nil) {
        self.init(type: .audio(audio), uid: uid)
    }

    public init(display: DisplayAlarm, uid: String? = nil) {
        self.init(type: .display(display), uid: uid)
    }

    public init(email: EmailAlarm, uid: String? = nil) {
        self.init(type: .email(email), uid: uid)
    }

    public init(proximity: ProximityAlarm, uid: String? = nil) {
        self.init(type: .proximity(proximity), uid: uid)
    }

    /// ICalendarComponent protocol requirement - parse properties to create correct alarm type
    public init(properties: [ICalendarProperty], components: [any ICalendarComponent]) {
        // Extract common properties
        let actionProp = properties.first { $0.name == ICalPropertyName.action }
        let triggerProp = properties.first { $0.name == ICalPropertyName.trigger }
        let descriptionProp = properties.first { $0.name == ICalPropertyName.description }
        let summaryProp = properties.first { $0.name == ICalPropertyName.summary }
        let attendeeProps = properties.filter { $0.name == ICalPropertyName.attendee }
        let attachProps = properties.filter { $0.name == ICalPropertyName.attach }
        let durationProp = properties.first { $0.name == ICalPropertyName.duration }
        let repeatProp = properties.first { $0.name == ICalPropertyName.repeatCount }

        let trigger = triggerProp?.value ?? "PT0S"
        let duration = durationProp?.value != nil ? ICalDuration.from(durationProp!.value) : nil
        let repeatCount = repeatProp?.value != nil ? Int(repeatProp!.value) : nil

        // Parse based on ACTION property
        let alarmType: ICalAlarmType
        switch actionProp?.value.uppercased() {
        case "DISPLAY":
            let displayAlarm: DisplayAlarm
            if let duration = duration, let repeatCount = repeatCount {
                displayAlarm = DisplayAlarm(
                    trigger: trigger,
                    description: descriptionProp?.value ?? "Reminder",
                    duration: duration,
                    repeatCount: repeatCount
                )
            } else {
                displayAlarm = DisplayAlarm(
                    trigger: trigger,
                    description: descriptionProp?.value ?? "Reminder"
                )
            }
            alarmType = .display(displayAlarm)

        case "EMAIL":
            let attendees: [ICalAttendee] = attendeeProps.compactMap { prop in
                // Parse MAILTO: format
                let email = prop.value.hasPrefix("mailto:") ? String(prop.value.dropFirst(7)) : prop.value
                let commonName = prop.parameters["CN"]
                return ICalAttendee(email: email, commonName: commonName)
            }

            if !attendees.isEmpty {
                do {
                    // Use primary array-based initializer with all attendees
                    let emailAlarm = try EmailAlarm(
                        trigger: trigger,
                        description: descriptionProp?.value ?? "Reminder",
                        summary: summaryProp?.value ?? "Event Reminder",
                        attendees: attendees,
                        attachments: attachProps.compactMap { prop in
                            ICalAttachment(uri: prop.value, mediaType: prop.parameters[ICalParameterName.formatType])
                        },
                        duration: duration,
                        repeatCount: repeatCount
                    )
                    alarmType = .email(emailAlarm)
                } catch {
                    // Fallback if email alarm creation fails during parsing
                    alarmType = .audio(AudioAlarm(trigger: trigger))
                }
            } else {
                // Fallback if no valid attendees found
                alarmType = .audio(AudioAlarm(trigger: trigger))
            }

        case "PROXIMITY":
            let proximityTrigger = ICalProximityTrigger(latitude: 0.0, longitude: 0.0, radius: 100.0, entering: true)
            let proximityAlarm: ProximityAlarm
            if let duration = duration, let repeatCount = repeatCount {
                proximityAlarm = ProximityAlarm(
                    proximityTrigger: proximityTrigger,
                    description: descriptionProp?.value,
                    duration: duration,
                    repeatCount: repeatCount
                )
            } else {
                proximityAlarm = ProximityAlarm(
                    proximityTrigger: proximityTrigger,
                    description: descriptionProp?.value
                )
            }
            alarmType = .proximity(proximityAlarm)

        case "AUDIO":
            let attachment = attachProps.first.flatMap { prop in
                ICalAttachment(uri: prop.value, mediaType: prop.parameters[ICalParameterName.formatType])
            }
            let audioAlarm: AudioAlarm
            if let duration = duration, let repeatCount = repeatCount {
                audioAlarm = AudioAlarm(trigger: trigger, attachment: attachment, duration: duration, repeatCount: repeatCount)
            } else {
                audioAlarm = AudioAlarm(trigger: trigger, attachment: attachment)
            }
            alarmType = .audio(audioAlarm)

        case .none:
            let attachment = attachProps.first.flatMap { prop in
                ICalAttachment(uri: prop.value, mediaType: prop.parameters[ICalParameterName.formatType])
            }
            let audioAlarm = AudioAlarm(trigger: trigger, attachment: attachment)
            alarmType = .audio(audioAlarm)

        default:
            // Unknown action, fallback to audio
            let audioAlarm = AudioAlarm(trigger: trigger)
            alarmType = .audio(audioAlarm)
        }

        // Extract additional metadata
        let uid = properties.first { $0.name == "UID" }?.value
        let acknowledgedProp = properties.first { $0.name == "ACKNOWLEDGED" }
        let acknowledgedByProp = properties.first { $0.name == "ACKNOWLEDGED-BY" }
        let relatedProps = properties.filter { $0.name == "RELATED-TO" }

        let acknowledgment: ICalAlarmAcknowledgment?
        if let ackValue = acknowledgedProp?.value, let dateTime = ackValue.asICalDateTime {
            acknowledgment = ICalAlarmAcknowledgment(
                acknowledgedAt: dateTime,
                acknowledgedBy: acknowledgedByProp?.value
            )
        } else {
            acknowledgment = nil
        }

        self.init(
            type: alarmType,
            uid: uid,
            acknowledgment: acknowledgment,
            relatedAlarms: relatedProps.map { $0.value }
        )
    }

    /// Generate properties based on the alarm type
    private func generateProperties() -> [ICalendarProperty] {
        var props: [ICalendarProperty] = []

        // Add UID if present
        if let uid = uid {
            props.append(ICalProperty(name: "UID", value: uid))
        }

        // Add acknowledgment if present
        if let ack = acknowledgment {
            props.append(ICalProperty(name: "ACKNOWLEDGED", value: ICalendarFormatter.format(dateTime: ack.acknowledgedAt)))
            if let acknowledgedBy = ack.acknowledgedBy {
                props.append(ICalProperty(name: "ACKNOWLEDGED-BY", value: acknowledgedBy))
            }
        }

        // Add related alarms
        for relatedUID in relatedAlarms {
            props.append(ICalProperty(name: "RELATED-TO", value: relatedUID))
        }

        // Add type-specific properties
        switch type {
        case .audio(let audio):
            props.append(ICalProperty(name: ICalPropertyName.action, value: "AUDIO"))
            props.append(ICalProperty(name: ICalPropertyName.trigger, value: audio.trigger))

            if let attachment = audio.attachment {
                props.append(contentsOf: attachment.properties)
            }

            if let duration = audio.duration {
                props.append(ICalProperty(name: ICalPropertyName.duration, value: duration.formatForProperty()))
            }

            if let repeatCount = audio.repeatCount {
                props.append(ICalProperty(name: ICalPropertyName.repeatCount, value: String(repeatCount)))
            }

        case .display(let display):
            props.append(ICalProperty(name: ICalPropertyName.action, value: "DISPLAY"))
            props.append(ICalProperty(name: ICalPropertyName.trigger, value: display.trigger))
            props.append(ICalProperty(name: ICalPropertyName.description, value: display.description))

            if let duration = display.duration {
                props.append(ICalProperty(name: ICalPropertyName.duration, value: duration.formatForProperty()))
            }

            if let repeatCount = display.repeatCount {
                props.append(ICalProperty(name: ICalPropertyName.repeatCount, value: String(repeatCount)))
            }

        case .email(let email):
            props.append(ICalProperty(name: ICalPropertyName.action, value: "EMAIL"))
            props.append(ICalProperty(name: ICalPropertyName.trigger, value: email.trigger))
            props.append(ICalProperty(name: ICalPropertyName.description, value: email.description))
            props.append(ICalProperty(name: ICalPropertyName.summary, value: email.summary))

            // Add all attendees (guaranteed to have at least one)
            for attendee in email.attendees {
                var parameters: [String: String] = [:]
                if let commonName = attendee.commonName {
                    parameters["CN"] = commonName
                }
                if let role = attendee.role {
                    parameters["ROLE"] = role.rawValue
                }
                if let status = attendee.participationStatus {
                    parameters["PARTSTAT"] = status.rawValue
                }
                if let rsvp = attendee.rsvp {
                    parameters["RSVP"] = rsvp ? "TRUE" : "FALSE"
                }

                props.append(
                    ICalProperty(
                        name: ICalPropertyName.attendee,
                        value: "mailto:\(attendee.email)",
                        parameters: parameters
                    )
                )
            }

            // Add attachments
            for attachment in email.attachments {
                props.append(contentsOf: attachment.properties)
            }

            if let duration = email.duration {
                props.append(ICalProperty(name: ICalPropertyName.duration, value: duration.formatForProperty()))
            }

            if let repeatCount = email.repeatCount {
                props.append(ICalProperty(name: ICalPropertyName.repeatCount, value: String(repeatCount)))
            }

        case .proximity(let proximity):
            props.append(ICalProperty(name: ICalPropertyName.action, value: "PROXIMITY"))
            props.append(ICalProperty(name: ICalPropertyName.proximityTrigger, value: proximity.proximityTrigger.stringValue))
            props.append(ICalProperty(name: ICalPropertyName.trigger, value: "PT0S"))  // Dummy trigger for RFC compliance

            if let description = proximity.description {
                props.append(ICalProperty(name: ICalPropertyName.description, value: description))
            }

            if let duration = proximity.duration {
                props.append(ICalProperty(name: ICalPropertyName.duration, value: duration.formatForProperty()))
            }

            if let repeatCount = proximity.repeatCount {
                props.append(ICalProperty(name: ICalPropertyName.repeatCount, value: String(repeatCount)))
            }
        }

        return props
    }
}

// MARK: - ICalAttachment Extensions

extension ICalAttachment {
    /// Convert attachment to properties
    var properties: [ICalendarProperty] {
        var parameters: [String: String] = [:]

        if let mediaType = mediaType {
            parameters[ICalParameterName.formatType] = mediaType
        }

        switch type {
        case .uri:
            return [ICalProperty(name: ICalPropertyName.attach, value: value, parameters: parameters)]

        case .binary:
            parameters[ICalParameterName.encoding] = "BASE64"
            parameters[ICalParameterName.valueType] = "BINARY"
            return [ICalProperty(name: ICalPropertyName.attach, value: value, parameters: parameters)]
        }
    }
}
/// Represents a time zone (VTIMEZONE)
public struct ICalTimeZone: ICalendarComponent, Sendable {
    public static let componentName = "VTIMEZONE"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Time zone identifier
    public var timeZoneId: String? {
        get { getPropertyValue(ICalPropertyName.timeZoneId) }
        set { setPropertyValue(ICalPropertyName.timeZoneId, value: newValue) }
    }

    /// Time zone URL
    public var timeZoneUrl: String? {
        get { getPropertyValue(ICalPropertyName.timeZoneUrl) }
        set { setPropertyValue(ICalPropertyName.timeZoneUrl, value: newValue) }
    }

    /// X-LIC-LOCATION (Lotus Notes compatibility)
    public var xLicLocation: String? {
        get { getPropertyValue(ICalPropertyName.xLicLocation) }
        set { setPropertyValue(ICalPropertyName.xLicLocation, value: newValue) }
    }

    /// Get Foundation TimeZone from timezone identifier (if available on current system)
    public var foundationTimeZone: TimeZone? {
        guard let identifier = timeZoneId else { return nil }
        return TimeZone(identifier: identifier)
    }

    /// Last modified
    public var lastModified: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.lastModified) }
        set { setDateTimeProperty(ICalPropertyName.lastModified, value: newValue) }
    }

    /// Standard time components
    public var standardTimes: [ICalTimeZoneComponent] {
        components.compactMap { $0 as? ICalTimeZoneComponent }.filter { $0.isStandard }
    }

    /// Daylight time components
    public var daylightTimes: [ICalTimeZoneComponent] {
        components.compactMap { $0 as? ICalTimeZoneComponent }.filter { !$0.isStandard }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components
    }

    public init(timeZoneId: String) {
        self.properties = [
            ICalProperty(name: ICalPropertyName.timeZoneId, value: timeZoneId)
        ]
        self.components = []
    }

}

// MARK: - Time Zone Sub-Component

/// Represents a time zone sub-component (STANDARD or DAYLIGHT)
public struct ICalTimeZoneComponent: ICalendarComponent, Sendable {
    public let isStandard: Bool

    public static var componentName: String { "STANDARD" }  // Or "DAYLIGHT"

    /// Override instance component name to return STANDARD or DAYLIGHT based on isStandard flag
    public var instanceComponentName: String {
        isStandard ? "STANDARD" : "DAYLIGHT"
    }

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Start date and time
    public var dateTimeStart: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStart) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStart, value: newValue) }
    }

    /// Offset from UTC
    public var offsetFrom: String? {
        get { getPropertyValue(ICalPropertyName.timeZoneOffsetFrom) }
        set { setPropertyValue(ICalPropertyName.timeZoneOffsetFrom, value: newValue) }
    }

    /// Offset to UTC
    public var offsetTo: String? {
        get { getPropertyValue(ICalPropertyName.timeZoneOffsetTo) }
        set { setPropertyValue(ICalPropertyName.timeZoneOffsetTo, value: newValue) }
    }

    /// Time zone name
    public var timeZoneName: String? {
        get { getPropertyValue(ICalPropertyName.timeZoneName) }
        set { setPropertyValue(ICalPropertyName.timeZoneName, value: newValue) }
    }

    /// Recurrence rule
    public var recurrenceRule: ICalRecurrenceRule? {
        get { getRecurrenceRuleProperty(ICalPropertyName.recurrenceRule) }
        set { setRecurrenceRuleProperty(ICalPropertyName.recurrenceRule, value: newValue) }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = [], isStandard: Bool = true) {
        self.properties = properties
        self.components = components
        self.isStandard = isStandard
    }

    public init(properties: [ICalendarProperty], components: [any ICalendarComponent]) {
        self.properties = properties
        self.components = components
        self.isStandard = true
    }
}

// MARK: - Attendee/Organizer

/// Represents an attendee or organizer
public struct ICalAttendee: Sendable, Codable, Hashable {
    public let email: String
    public let commonName: String?
    public let role: ICalRole?
    public let participationStatus: ICalParticipationStatus?
    public let userType: ICalUserType?
    public let rsvp: Bool?
    public let delegatedFrom: String?
    public let delegatedTo: String?
    public let sentBy: String?
    public let directory: String?
    public let member: [String]?

    public init(
        email: String,
        commonName: String? = nil,
        role: ICalRole? = nil,
        participationStatus: ICalParticipationStatus? = nil,
        userType: ICalUserType? = nil,
        rsvp: Bool? = nil,
        delegatedFrom: String? = nil,
        delegatedTo: String? = nil,
        sentBy: String? = nil,
        directory: String? = nil,
        member: [String]? = nil
    ) {
        self.email = email
        self.commonName = commonName
        self.role = role
        self.participationStatus = participationStatus
        self.userType = userType
        self.rsvp = rsvp
        self.delegatedFrom = delegatedFrom
        self.delegatedTo = delegatedTo
        self.sentBy = sentBy
        self.directory = directory
        self.member = member
    }
}

// MARK: - Component Extensions for Property Access

// MARK: - RFC 9073 Event Publishing Components

/// VVENUE component for structured venue information (RFC 9073)
public struct ICalVenue: ICalendarComponent, Sendable {
    public static let componentName = "VVENUE"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Venue name
    public var name: String? {
        get { getPropertyValue("NAME") }
        set { setPropertyValue("NAME", value: newValue) }
    }

    /// Venue description
    public var description: String? {
        get { getPropertyValue(ICalPropertyName.description) }
        set { setPropertyValue(ICalPropertyName.description, value: newValue) }
    }

    /// Venue address
    public var address: String? {
        get { getPropertyValue("ADDRESS") }
        set { setPropertyValue("ADDRESS", value: newValue) }
    }

    /// Street address
    public var streetAddress: String? {
        get { getPropertyValue("STREET-ADDRESS") }
        set { setPropertyValue("STREET-ADDRESS", value: newValue) }
    }

    /// City/locality
    public var locality: String? {
        get { getPropertyValue("LOCALITY") }
        set { setPropertyValue("LOCALITY", value: newValue) }
    }

    /// State/region
    public var region: String? {
        get { getPropertyValue("REGION") }
        set { setPropertyValue("REGION", value: newValue) }
    }

    /// Country
    public var country: String? {
        get { getPropertyValue("COUNTRY") }
        set { setPropertyValue("COUNTRY", value: newValue) }
    }

    /// Postal code
    public var postalCode: String? {
        get { getPropertyValue("POSTALCODE") }
        set { setPropertyValue("POSTALCODE", value: newValue) }
    }

    /// Venue geographic coordinates
    public var geo: ICalGeoCoordinate? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.geo) else { return nil }
            return ICalGeoCoordinate(from: value)
        }
        set {
            setPropertyValue(ICalPropertyName.geo, value: newValue?.stringValue)
        }
    }

    /// Location types
    public var locationTypes: [String] {
        get {
            properties
                .filter { $0.name == "LOCATION-TYPE" }
                .flatMap { $0.value.components(separatedBy: ",") }
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            properties.removeAll { $0.name == "LOCATION-TYPE" }
            if !newValue.isEmpty {
                let property = ICalProperty(name: "LOCATION-TYPE", value: newValue.joined(separator: ","))
                properties.append(property)
            }
        }
    }

    /// Categories
    public var categories: [String] {
        get {
            properties
                .filter { $0.name == ICalPropertyName.categories }
                .flatMap { $0.value.components(separatedBy: ",") }
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            properties.removeAll { $0.name == ICalPropertyName.categories }
            if !newValue.isEmpty {
                let property = ICalProperty(name: ICalPropertyName.categories, value: newValue.joined(separator: ","))
                properties.append(property)
            }
        }
    }

    /// Venue URL
    public var url: String? {
        get { getPropertyValue(ICalPropertyName.url) }
        set { setPropertyValue(ICalPropertyName.url, value: newValue) }
    }

    /// Venue capacity
    public var capacity: Int? {
        get {
            guard let value = getPropertyValue("CAPACITY") else { return nil }
            return Int(value)
        }
        set { setPropertyValue("CAPACITY", value: newValue?.description) }
    }

    /// Accessibility features
    public var accessibilityFeatures: [String] {
        get {
            properties
                .filter { $0.name == "ACCESSIBILITY" }
                .flatMap { $0.value.components(separatedBy: ",") }
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            properties.removeAll { $0.name == "ACCESSIBILITY" }
            if !newValue.isEmpty {
                let property = ICalProperty(name: "ACCESSIBILITY", value: newValue.joined(separator: ","))
                properties.append(property)
            }
        }
    }

    /// Structured data
    public var structuredData: ICalStructuredData? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.structuredData),
                let type = getPropertyValue("STRUCTURED-DATA-TYPE"),
                let dataType = ICalStructuredDataType(rawValue: type)
            else { return nil }
            let schema = getPropertyValue("SCHEMA")
            return ICalStructuredData(type: dataType, data: value, schema: schema)
        }
        set {
            setPropertyValue(ICalPropertyName.structuredData, value: newValue?.data)
            setPropertyValue("STRUCTURED-DATA-TYPE", value: newValue?.type.rawValue)
            setPropertyValue("SCHEMA", value: newValue?.schema)
        }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components
    }

    public init(name: String) {
        self.properties = []
        self.components = []
        self.name = name
    }
}

/// VLOCATION component for enhanced location information (RFC 9073)
public struct ICalLocationComponent: ICalendarComponent, Sendable {
    public static let componentName = "VLOCATION"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Location name
    public var name: String? {
        get { getPropertyValue("NAME") }
        set { setPropertyValue("NAME", value: newValue) }
    }

    /// Location description
    public var description: String? {
        get { getPropertyValue(ICalPropertyName.description) }
        set { setPropertyValue(ICalPropertyName.description, value: newValue) }
    }

    /// Location geographic coordinates
    public var geo: ICalGeoCoordinate? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.geo) else { return nil }
            return ICalGeoCoordinate(from: value)
        }
        set {
            setPropertyValue(ICalPropertyName.geo, value: newValue?.stringValue)
        }
    }

    /// Location types
    public var locationTypes: [String] {
        get {
            properties
                .filter { $0.name == "LOCATION-TYPE" }
                .flatMap { $0.value.components(separatedBy: ",") }
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            properties.removeAll { $0.name == "LOCATION-TYPE" }
            if !newValue.isEmpty {
                let property = ICalProperty(name: "LOCATION-TYPE", value: newValue.joined(separator: ","))
                properties.append(property)
            }
        }
    }

    /// Capacity
    public var capacity: Int? {
        get {
            guard let value = getPropertyValue("CAPACITY") else { return nil }
            return Int(value)
        }
        set { setPropertyValue("CAPACITY", value: newValue?.description) }
    }

    /// Location address
    public var address: String? {
        get { getPropertyValue("ADDRESS") }
        set { setPropertyValue("ADDRESS", value: newValue) }
    }

    /// Location URL
    public var url: String? {
        get { getPropertyValue(ICalPropertyName.url) }
        set { setPropertyValue(ICalPropertyName.url, value: newValue) }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components
    }

    public init(name: String) {
        self.properties = []
        self.components = []
        self.name = name
    }
}

/// VRESOURCE component for resource management (RFC 9073)
public struct ICalResourceComponent: ICalendarComponent, Sendable {
    public static let componentName = "VRESOURCE"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Resource name
    public var name: String? {
        get { getPropertyValue("NAME") }
        set { setPropertyValue("NAME", value: newValue) }
    }

    /// Resource description
    public var description: String? {
        get { getPropertyValue(ICalPropertyName.description) }
        set { setPropertyValue(ICalPropertyName.description, value: newValue) }
    }

    /// Resource type
    public var resourceType: String? {
        get { getPropertyValue("RESOURCE-TYPE") }
        set { setPropertyValue("RESOURCE-TYPE", value: newValue) }
    }

    /// Resource capacity
    public var capacity: Int? {
        get {
            guard let value = getPropertyValue("CAPACITY") else { return nil }
            return Int(value)
        }
        set { setPropertyValue("CAPACITY", value: newValue?.description) }
    }

    /// Categories
    public var categories: [String] {
        get {
            properties
                .filter { $0.name == ICalPropertyName.categories }
                .flatMap { $0.value.components(separatedBy: ",") }
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            properties.removeAll { $0.name == ICalPropertyName.categories }
            if !newValue.isEmpty {
                let property = ICalProperty(name: ICalPropertyName.categories, value: newValue.joined(separator: ","))
                properties.append(property)
            }
        }
    }

    /// Resource features
    public var features: [String] {
        get {
            properties
                .filter { $0.name == "FEATURES" }
                .flatMap { $0.value.components(separatedBy: ",") }
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            properties.removeAll { $0.name == "FEATURES" }
            if !newValue.isEmpty {
                let property = ICalProperty(name: "FEATURES", value: newValue.joined(separator: ","))
                properties.append(property)
            }
        }
    }

    /// Resource contact information
    public var contact: String? {
        get { getPropertyValue(ICalPropertyName.contact) }
        set { setPropertyValue(ICalPropertyName.contact, value: newValue) }
    }

    /// Booking URL
    public var bookingUrl: String? {
        get { getPropertyValue("BOOKING-URL") }
        set { setPropertyValue("BOOKING-URL", value: newValue) }
    }

    /// Resource cost
    public var cost: String? {
        get { getPropertyValue("COST") }
        set { setPropertyValue("COST", value: newValue) }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components
    }

    public init(name: String, resourceType: String) {
        self.properties = []
        self.components = []
        self.name = name
        self.resourceType = resourceType
    }
}

// MARK: - RFC 7953 Availability Components

/// VAVAILABILITY component for calendar availability (RFC 7953)
public struct ICalAvailabilityComponent: ICalendarComponent, Sendable {
    public static let componentName = "VAVAILABILITY"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Start time for availability period
    public var dateTimeStart: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStart) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStart, value: newValue) }
    }

    /// End time for availability period
    public var dateTimeEnd: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeEnd) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeEnd, value: newValue) }
    }

    /// Duration of availability
    public var duration: ICalDuration? {
        get { getDurationProperty(ICalPropertyName.duration) }
        set { setDurationProperty(ICalPropertyName.duration, value: newValue) }
    }

    /// Summary of availability
    public var summary: String? {
        get { getPropertyValue(ICalPropertyName.summary) }
        set { setPropertyValue(ICalPropertyName.summary, value: newValue) }
    }

    /// Description of availability
    public var description: String? {
        get { getPropertyValue(ICalPropertyName.description) }
        set { setPropertyValue(ICalPropertyName.description, value: newValue) }
    }

    /// Available periods
    public var availablePeriods: [ICalAvailability] {
        get { getAvailabilityPeriods(type: .free) }
        set { setAvailabilityPeriods(newValue, type: .free) }
    }

    /// Busy periods
    public var busyPeriods: [ICalAvailability] {
        get { getAvailabilityPeriods(type: .busy) }
        set { setAvailabilityPeriods(newValue, type: .busy) }
    }

    private func getAvailabilityPeriods(type: ICalBusyType) -> [ICalAvailability] {
        let componentName = type == .free ? "AVAILABLE" : "BUSY"
        return components.compactMap { component in
            guard Swift.type(of: component).componentName == componentName else { return nil }

            let start = component.getDateTimeProperty(ICalPropertyName.dateTimeStart)
            let end = component.getDateTimeProperty(ICalPropertyName.dateTimeEnd)
            let duration = component.getDurationProperty(ICalPropertyName.duration)
            let summary = component.getPropertyValue(ICalPropertyName.summary)
            let description = component.getPropertyValue(ICalPropertyName.description)
            let location = component.getPropertyValue(ICalPropertyName.location)

            guard let startTime = start else { return nil }

            return ICalAvailability(
                start: startTime,
                end: end,
                duration: duration,
                busyType: type,
                summary: summary,
                description: description,
                location: location
            )
        }
    }

    private mutating func setAvailabilityPeriods(_ periods: [ICalAvailability], type: ICalBusyType) {
        let componentName = type == .free ? "AVAILABLE" : "BUSY"

        // Remove existing components of this type
        components.removeAll { Swift.type(of: $0).componentName == componentName }

        // Add new components
        for period in periods {
            let component: any ICalendarComponent
            if type == .free {
                var available = ICalAvailableComponent()
                available.dateTimeStart = period.start
                available.dateTimeEnd = period.end
                available.duration = period.duration
                available.summary = period.summary
                available.location = period.location
                component = available
            } else {
                // Create BUSY component (similar to AVAILABLE)
                var busy = ICalBusyComponent()
                busy.dateTimeStart = period.start
                busy.dateTimeEnd = period.end
                busy.duration = period.duration
                busy.summary = period.summary
                busy.location = period.location
                component = busy
            }
            components.append(component)
        }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components
    }
}

/// AVAILABLE component for free time slots (RFC 7953)
public struct ICalAvailableComponent: ICalendarComponent, Sendable {
    public static let componentName = "AVAILABLE"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Start time
    public var dateTimeStart: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStart) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStart, value: newValue) }
    }

    /// End time
    public var dateTimeEnd: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeEnd) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeEnd, value: newValue) }
    }

    /// Duration
    public var duration: ICalDuration? {
        get { getDurationProperty(ICalPropertyName.duration) }
        set { setDurationProperty(ICalPropertyName.duration, value: newValue) }
    }

    /// Summary
    public var summary: String? {
        get { getPropertyValue(ICalPropertyName.summary) }
        set { setPropertyValue(ICalPropertyName.summary, value: newValue) }
    }

    /// Location
    public var location: String? {
        get { getPropertyValue(ICalPropertyName.location) }
        set { setPropertyValue(ICalPropertyName.location, value: newValue) }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components
    }
}

/// BUSY component for busy time slots (RFC 7953)
public struct ICalBusyComponent: ICalendarComponent, Sendable {
    public static let componentName = "BUSY"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Start time
    public var dateTimeStart: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStart) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStart, value: newValue) }
    }

    /// End time
    public var dateTimeEnd: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeEnd) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeEnd, value: newValue) }
    }

    /// Duration
    public var duration: ICalDuration? {
        get { getDurationProperty(ICalPropertyName.duration) }
        set { setDurationProperty(ICalPropertyName.duration, value: newValue) }
    }

    /// Summary
    public var summary: String? {
        get { getPropertyValue(ICalPropertyName.summary) }
        set { setPropertyValue(ICalPropertyName.summary, value: newValue) }
    }

    /// Location
    public var location: String? {
        get { getPropertyValue(ICalPropertyName.location) }
        set { setPropertyValue(ICalPropertyName.location, value: newValue) }
    }

    /// Busy type
    public var busyType: ICalBusyType? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.busyType) else { return nil }
            return ICalBusyType(rawValue: value)
        }
        set { setPropertyValue(ICalPropertyName.busyType, value: newValue?.rawValue) }
    }

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components
    }
}

// MARK: - RFC 9073 Participant Component

/// PARTICIPANT component for event/task participants (RFC 9073)
public struct ICalParticipant: ICalendarComponent, Sendable {
    public static let componentName = "PARTICIPANT"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    /// Unique identifier (required)
    public var uid: String {
        get { getPropertyValue(ICalPropertyName.uid) ?? UUID().uuidString }
        set { setPropertyValue(ICalPropertyName.uid, value: newValue) }
    }

    /// Participant type (required)
    public var participantType: ICalParticipantType? {
        get {
            guard let value = getPropertyValue("PARTICIPANT-TYPE") else { return nil }
            return ICalParticipantType(rawValue: value)
        }
        set { setPropertyValue("PARTICIPANT-TYPE", value: newValue?.rawValue) }
    }

    /// Calendar address
    public var calendarAddress: String? {
        get { getPropertyValue("CALENDAR-ADDRESS") }
        set { setPropertyValue("CALENDAR-ADDRESS", value: newValue) }
    }

    /// Date-time stamp
    public var dateTimeStamp: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.dateTimeStamp) }
        set { setDateTimeProperty(ICalPropertyName.dateTimeStamp, value: newValue) }
    }

    /// Created date
    public var created: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.created) }
        set { setDateTimeProperty(ICalPropertyName.created, value: newValue) }
    }

    /// Last modified date
    public var lastModified: ICalDateTime? {
        get { getDateTimeProperty(ICalPropertyName.lastModified) }
        set { setDateTimeProperty(ICalPropertyName.lastModified, value: newValue) }
    }

    /// Description
    public var description: String? {
        get { getPropertyValue(ICalPropertyName.description) }
        set { setPropertyValue(ICalPropertyName.description, value: newValue) }
    }

    /// Summary
    public var summary: String? {
        get { getPropertyValue(ICalPropertyName.summary) }
        set { setPropertyValue(ICalPropertyName.summary, value: newValue) }
    }

    /// Geographic position
    public var geo: ICalGeoCoordinate? {
        get {
            guard let value = getPropertyValue("GEO") else { return nil }
            return ICalGeoCoordinate(from: value)
        }
        set {
            setPropertyValue("GEO", value: newValue?.stringValue)
        }
    }

    /// Priority
    public var priority: Int? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.priority) else { return nil }
            return Int(value)
        }
        set { setPropertyValue(ICalPropertyName.priority, value: newValue?.description) }
    }

    /// Sequence number
    public var sequence: Int? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.sequence) else { return nil }
            return Int(value)
        }
        set { setPropertyValue(ICalPropertyName.sequence, value: newValue?.description) }
    }

    /// Status
    public var status: ICalEventStatus? {
        get {
            guard let value = getPropertyValue(ICalPropertyName.status) else { return nil }
            return ICalEventStatus(rawValue: value)
        }
        set { setPropertyValue(ICalPropertyName.status, value: newValue?.rawValue) }
    }

    /// URL
    public var url: String? {
        get { getPropertyValue(ICalPropertyName.url) }
        set { setPropertyValue(ICalPropertyName.url, value: newValue) }
    }

    /// Categories (multiple)
    public var categories: [String] {
        get {
            properties.filter { $0.name == ICalPropertyName.categories }
                .compactMap { $0.value }
                .flatMap { $0.split(separator: ",").map(String.init) }
        }
        set {
            properties.removeAll { $0.name == ICalPropertyName.categories }
            if !newValue.isEmpty {
                let categoriesString = newValue.joined(separator: ",")
                properties.append(ICalProperty(name: ICalPropertyName.categories, value: categoriesString))
            }
        }
    }

    /// Comments (multiple)
    public var comments: [String] {
        get { properties.filter { $0.name == "COMMENT" }.compactMap { $0.value } }
        set {
            properties.removeAll { $0.name == "COMMENT" }
            for comment in newValue {
                properties.append(ICalProperty(name: "COMMENT", value: comment))
            }
        }
    }

    /// Contacts (multiple)
    public var contacts: [String] {
        get { properties.filter { $0.name == "CONTACT" }.compactMap { $0.value } }
        set {
            properties.removeAll { $0.name == "CONTACT" }
            for contact in newValue {
                properties.append(ICalProperty(name: "CONTACT", value: contact))
            }
        }
    }

    /// Locations (VLOCATION sub-components)
    public var locations: [ICalLocationComponent] {
        get { components.compactMap { $0 as? ICalLocationComponent } }
        set {
            components.removeAll { $0 is ICalLocationComponent }
            components.append(contentsOf: newValue)
        }
    }

    /// Resources (VRESOURCE sub-components)
    public var resources: [ICalResourceComponent] {
        get { components.compactMap { $0 as? ICalResourceComponent } }
        set {
            components.removeAll { $0 is ICalResourceComponent }
            components.append(contentsOf: newValue)
        }
    }

    public init(
        uid: String = UUID().uuidString,
        participantType: ICalParticipantType,
        properties: [ICalendarProperty] = [],
        components: [any ICalendarComponent] = []
    ) {
        self.properties = properties
        self.components = components
        self.uid = uid
        self.participantType = participantType

        // Set default timestamp
        if dateTimeStamp == nil {
            self.dateTimeStamp = ICalDateTime(date: Date())
        }
    }

    public init(properties: [ICalendarProperty], components: [any ICalendarComponent]) {
        self.properties = properties
        self.components = components
    }
}

/// Participant type enumeration
public enum ICalParticipantType: String, CaseIterable, Sendable {
    case active = "ACTIVE"
    case inactive = "INACTIVE"
    case sponsor = "SPONSOR"
    case contact = "CONTACT"
    case booking_contact = "BOOKING-CONTACT"
    case emergency_contact = "EMERGENCY-CONTACT"
    case publicity_contact = "PUBLICITY-CONTACT"
    case planner_contact = "PLANNER-CONTACT"
    case performer = "PERFORMER"
    case speaker = "SPEAKER"
}

// MARK: - Component Extensions for Property Access
extension ICalendarComponent {
    /// Get a property value by name
    @inline(__always)
    public func getPropertyValue(_ name: String) -> String? {
        properties.first { $0.name == name }?.value
    }

    /// Set a property value
    @inline(__always)
    public mutating func setPropertyValue(_ name: String, value: String?) {
        properties.removeAll { $0.name == name }
        if let value = value {
            properties.append(ICalProperty(name: name, value: value))
        }
    }

    /// Get a date-time property
    @inline(__always)
    public func getDateTimeProperty(_ name: String) -> ICalDateTime? {
        guard let property = properties.first(where: { $0.name == name }) else { return nil }

        // Check for TZID parameter to determine timezone
        let timeZone: TimeZone
        if let tzid = property.parameters["TZID"] {
            timeZone = TimeZone(identifier: tzid) ?? .current
        } else {
            // For properties without TZID, preserve timezone from the value format
            timeZone = .current
        }

        return ICalendarFormatter.parseDateTime(property.value, timeZone: timeZone)
    }

    /// Set a date-time property
    @inline(__always)
    public mutating func setDateTimeProperty(_ name: String, value: ICalDateTime?) {
        // Remove existing property
        properties.removeAll { $0.name == name }

        guard let value = value else { return }

        // Create property with appropriate parameters
        var parameters: [String: String] = [:]

        if value.isDateOnly {
            // For date-only events (all-day events), use VALUE=DATE and no timezone
            // RFC 5545: All-day events must use VALUE=DATE format, e.g., DTSTART;VALUE=DATE:20250715
            parameters["VALUE"] = "DATE"
        } else {
            // For timed events, add timezone parameter if needed
            // RFC 5545: UTC and GMT times use 'Z' suffix (handled by formatter), not TZID parameter
            // - UTC/GMT: DTSTART:20260106T143000Z (no TZID, formatter adds Z)
            // - Regular timezones: DTSTART;TZID=America/New_York:20260106T143000 (with TZID)
            // - Floating time: DTSTART:20260106T143000 (no TZID, no Z)
            if let timeZone = value.timeZone,
                timeZone.identifier != "UTC" && timeZone.identifier != "GMT"
            {
                parameters["TZID"] = timeZone.identifier
            }
        }

        let property = ICalProperty(
            name: name,
            value: ICalendarFormatter.format(dateTime: value),
            parameters: parameters
        )
        properties.append(property)
    }

    /// Get a duration property
    public func getDurationProperty(_ name: String) -> ICalDuration? {
        guard let value = getPropertyValue(name) else { return nil }
        return ICalendarFormatter.parseDuration(value)
    }

    /// Set a duration property
    public mutating func setDurationProperty(_ name: String, value: ICalDuration?) {
        guard let value = value else {
            setPropertyValue(name, value: nil)
            return
        }
        setPropertyValue(name, value: ICalendarFormatter.format(duration: value))
    }

    /// Get a recurrence rule property
    public func getRecurrenceRuleProperty(_ name: String) -> ICalRecurrenceRule? {
        guard let value = getPropertyValue(name) else { return nil }
        return ICalendarFormatter.parseRecurrenceRule(value)
    }

    /// Set a recurrence rule property
    public mutating func setRecurrenceRuleProperty(_ name: String, value: ICalRecurrenceRule?) {
        guard let value = value else {
            setPropertyValue(name, value: nil)
            return
        }
        setPropertyValue(name, value: ICalendarFormatter.format(recurrenceRule: value))
    }

    /// Get an attendee property
    public func getAttendeeProperty(_ name: String) -> ICalAttendee? {
        guard let property = properties.first(where: { $0.name == name }) else { return nil }
        return ICalendarFormatter.parseAttendee(property.value, parameters: property.parameters)
    }

    /// Set an attendee property
    public mutating func setAttendeeProperty(_ name: String, value: ICalAttendee?) {
        properties.removeAll { $0.name == name }
        if let value = value {
            let (valueString, parameters) = ICalendarFormatter.format(attendee: value)
            properties.append(ICalProperty(name: name, value: valueString, parameters: parameters))
        }
    }

    /// Get attendees properties
    public func getAttendeesProperty(_ name: String) -> [ICalAttendee] {
        properties.filter { $0.name == name }.compactMap { property in
            ICalendarFormatter.parseAttendee(property.value, parameters: property.parameters)
        }
    }

    /// Set attendees properties
    public mutating func setAttendeesProperty(_ name: String, values: [ICalAttendee]) {
        properties.removeAll { $0.name == name }
        for value in values {
            let (valueString, parameters) = ICalendarFormatter.format(attendee: value)
            properties.append(ICalProperty(name: name, value: valueString, parameters: parameters))
        }
    }

    /// Get categories property
    public func getCategoriesProperty() -> [String] {
        guard let value = getPropertyValue(ICalPropertyName.categories) else { return [] }
        return value.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    }

    /// Set categories property
    public mutating func setCategoriesProperty(_ categories: [String]) {
        if categories.isEmpty {
            setPropertyValue(ICalPropertyName.categories, value: nil)
        } else {
            setPropertyValue(ICalPropertyName.categories, value: categories.joined(separator: ","))
        }
    }

    /// Get a date list property (for EXDATE, RDATE)
    public func getDateListProperty(_ name: String) -> [ICalDateTime] {
        guard let property = properties.first(where: { $0.name == name }) else { return [] }
        return ICalendarFormatter.parseDateList(property.value)
    }

    /// Set a date list property (for EXDATE, RDATE)
    public mutating func setDateListProperty(_ name: String, values: [ICalDateTime]) {
        // Remove existing property
        properties.removeAll { $0.name == name }

        if !values.isEmpty {
            let dateListValue = ICalendarFormatter.format(dateList: values)
            properties.append(ICalProperty(name: name, value: dateListValue))
        }
    }
}
