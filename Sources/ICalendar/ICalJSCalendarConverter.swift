import Foundation

// MARK: - JSCalendar Conversion Support (RFC 9253)

/// JSCalendar conversion utilities for iCalendar
/// RFC 9253: JSCalendar: A JSON Representation of Calendar Data
public struct ICalJSCalendarConverter: Sendable {

    // MARK: - JSCalendar Object Types

    /// JSCalendar object representation
    public struct JSCalendarObject: Codable, Sendable {
        public let type: JSCalendarType
        public let uid: String
        public let title: String?
        public let description: String?
        public let start: JSCalendarDateTime?
        public let duration: String?
        public let timeZone: String?
        public let participants: [String: JSCalendarParticipant]
        public let locations: [String: JSCalendarLocation]
        public let virtualLocations: [String: JSCalendarVirtualLocation]
        public let categories: [String: Bool]
        public let keywords: [String: Bool]
        public let links: [String: JSCalendarLink]
        public let locale: String?
        public let prodId: String?

        public enum JSCalendarType: String, CaseIterable, Codable, Sendable {
            case event = "Event"
            case task = "Task"
            case group = "Group"
            case participantReply = "ParticipantReply"
        }

        public init(
            type: JSCalendarType,
            uid: String,
            title: String? = nil,
            description: String? = nil,
            start: JSCalendarDateTime? = nil,
            duration: String? = nil,
            timeZone: String? = nil,
            participants: [String: JSCalendarParticipant] = [:],
            locations: [String: JSCalendarLocation] = [:],
            virtualLocations: [String: JSCalendarVirtualLocation] = [:],
            categories: [String: Bool] = [:],
            keywords: [String: Bool] = [:],
            links: [String: JSCalendarLink] = [:],
            locale: String? = nil,
            prodId: String? = nil
        ) {
            self.type = type
            self.uid = uid
            self.title = title
            self.description = description
            self.start = start
            self.duration = duration
            self.timeZone = timeZone
            self.participants = participants
            self.locations = locations
            self.virtualLocations = virtualLocations
            self.categories = categories
            self.keywords = keywords
            self.links = links
            self.locale = locale
            self.prodId = prodId
        }
    }

    /// JSCalendar DateTime representation
    public struct JSCalendarDateTime: Codable, Sendable {
        public let dateTime: String
        public let timeZone: String?

        public init(dateTime: String, timeZone: String? = nil) {
            self.dateTime = dateTime
            self.timeZone = timeZone
        }
    }

    /// JSCalendar Participant
    public struct JSCalendarParticipant: Codable, Sendable {
        public let name: String?
        public let email: String?
        public let kind: ParticipantKind?
        public let roles: [ParticipantRole]
        public let participationStatus: ParticipationStatus?
        public let expectReply: Bool?
        public let language: String?

        public enum ParticipantKind: String, CaseIterable, Codable, Sendable {
            case individual = "individual"
            case group = "group"
            case resource = "resource"
            case location = "location"
        }

        public enum ParticipantRole: String, CaseIterable, Codable, Sendable {
            case owner = "owner"
            case attendee = "attendee"
            case optional = "optional"
            case informational = "informational"
            case chair = "chair"
        }

        public enum ParticipationStatus: String, CaseIterable, Codable, Sendable {
            case needsAction = "needs-action"
            case accepted = "accepted"
            case declined = "declined"
            case tentative = "tentative"
            case delegated = "delegated"
        }

        public init(
            name: String? = nil,
            email: String? = nil,
            kind: ParticipantKind? = nil,
            roles: [ParticipantRole] = [],
            participationStatus: ParticipationStatus? = nil,
            expectReply: Bool? = nil,
            language: String? = nil
        ) {
            self.name = name
            self.email = email
            self.kind = kind
            self.roles = roles
            self.participationStatus = participationStatus
            self.expectReply = expectReply
            self.language = language
        }
    }

    /// JSCalendar Location
    public struct JSCalendarLocation: Codable, Sendable {
        public let type: String
        public let name: String?
        public let description: String?
        public let locationTypes: [LocationType]
        public let coordinates: String?
        public let timeZone: String?

        public enum LocationType: String, CaseIterable, Codable, Sendable {
            case physical = "physical"
            case virtual = "virtual"
        }

        public init(
            type: String = "Location",
            name: String? = nil,
            description: String? = nil,
            locationTypes: [LocationType] = [],
            coordinates: String? = nil,
            timeZone: String? = nil
        ) {
            self.type = type
            self.name = name
            self.description = description
            self.locationTypes = locationTypes
            self.coordinates = coordinates
            self.timeZone = timeZone
        }
    }

    /// JSCalendar Virtual Location
    public struct JSCalendarVirtualLocation: Codable, Sendable {
        public let type: String
        public let name: String?
        public let description: String?
        public let uri: String?
        public let features: [VirtualLocationFeature]

        public enum VirtualLocationFeature: String, CaseIterable, Codable, Sendable {
            case audio = "audio"
            case chat = "chat"
            case feed = "feed"
            case moderator = "moderator"
            case phone = "phone"
            case screen = "screen"
            case video = "video"
        }

        public init(
            type: String = "VirtualLocation",
            name: String? = nil,
            description: String? = nil,
            uri: String? = nil,
            features: [VirtualLocationFeature] = []
        ) {
            self.type = type
            self.name = name
            self.description = description
            self.uri = uri
            self.features = features
        }
    }

    /// JSCalendar Link
    public struct JSCalendarLink: Codable, Sendable {
        public let type: String
        public let href: String
        public let cid: String?
        public let contentType: String?
        public let size: Int?
        public let rel: String?
        public let display: String?

        public init(
            type: String = "Link",
            href: String,
            cid: String? = nil,
            contentType: String? = nil,
            size: Int? = nil,
            rel: String? = nil,
            display: String? = nil
        ) {
            self.type = type
            self.href = href
            self.cid = cid
            self.contentType = contentType
            self.size = size
            self.rel = rel
            self.display = display
        }
    }

    // MARK: - Conversion Methods

    /// Convert iCalendar event to JSCalendar object
    public static func convertToJSCalendar(_ event: ICalEvent) -> JSCalendarObject {
        var participants: [String: JSCalendarParticipant] = [:]

        // Convert attendees to participants
        for (index, attendee) in event.attendees.enumerated() {
            let participant = JSCalendarParticipant(
                name: attendee.commonName,
                email: attendee.email,
                kind: .individual,
                roles: convertAttendeeRole(attendee.role),
                participationStatus: convertParticipationStatus(attendee.participationStatus),
                expectReply: attendee.rsvp
            )
            participants["participant-\(index)"] = participant
        }

        // Add organizer as a participant
        if let organizer = event.organizer {
            let organizerParticipant = JSCalendarParticipant(
                name: organizer.commonName,
                email: organizer.email,
                kind: .individual,
                roles: [.owner, .chair],
                participationStatus: .accepted,
                expectReply: false
            )
            participants["organizer"] = organizerParticipant
        }

        // Convert locations
        var locations: [String: JSCalendarLocation] = [:]
        if let locationText = event.location {
            let location = JSCalendarLocation(
                name: locationText,
                locationTypes: [.physical]
            )
            locations["location-1"] = location
        }

        // Convert virtual locations from event URLs
        var virtualLocations: [String: JSCalendarVirtualLocation] = [:]
        if let eventURL = event.url {
            // Check if this looks like a virtual meeting URL
            if isVirtualMeetingURL(eventURL) {
                let virtualLocation = JSCalendarVirtualLocation(
                    name: "Virtual Meeting",
                    uri: eventURL,
                    features: inferVirtualFeatures(from: eventURL)
                )
                virtualLocations["virtual-1"] = virtualLocation
            }
        }

        // Convert start time
        let start = event.dateTimeStart.map { dt in
            JSCalendarDateTime(
                dateTime: formatJSCalendarDateTime(dt),
                timeZone: dt.timeZone?.identifier
            )
        }

        // Convert duration
        let duration = calculateDuration(start: event.dateTimeStart, end: event.dateTimeEnd)

        // Convert categories
        var categories: [String: Bool] = [:]
        for category in event.categories {
            categories[category] = true
        }

        // Convert attachments to links
        var links: [String: JSCalendarLink] = [:]
        for (index, attachment) in event.attachments.enumerated() {
            let uri = attachment.value
            let link = JSCalendarLink(
                href: uri,
                contentType: nil,
                display: nil
            )
            links["attachment-\(index)"] = link
        }

        return JSCalendarObject(
            type: .event,
            uid: event.uid,
            title: event.summary,
            description: event.description,
            start: start,
            duration: duration,
            timeZone: event.dateTimeStart?.timeZone?.identifier,
            participants: participants,
            locations: locations,
            virtualLocations: virtualLocations,
            categories: categories,
            links: links,
            prodId: event.getPropertyValue("PRODID")
        )
    }

    /// Convert JSCalendar object back to iCalendar event
    public static func convertFromJSCalendar(_ jsCalendar: JSCalendarObject) -> ICalEvent {
        var event = ICalEvent()

        event.uid = jsCalendar.uid
        event.summary = jsCalendar.title
        event.description = jsCalendar.description

        // Convert start time
        if let start = jsCalendar.start {
            event.dateTimeStart = parseJSCalendarDateTime(start)
        }

        // Convert duration to end time
        if let duration = jsCalendar.duration,
            let startTime = event.dateTimeStart
        {
            let durationInterval = parseISO8601Duration(duration)
            let endDate = startTime.date.addingTimeInterval(durationInterval)
            event.dateTimeEnd = ICalDateTime(date: endDate, timeZone: startTime.timeZone)
        }

        // Convert participants to attendees
        var attendees: [ICalAttendee] = []
        var organizer: ICalAttendee?

        for (_, participant) in jsCalendar.participants {
            if participant.roles.contains(.owner) || participant.roles.contains(.chair) {
                // This is the organizer
                organizer = ICalAttendee(
                    email: participant.email ?? "",
                    commonName: participant.name,
                    role: .chair
                )
            } else if let email = participant.email {
                // This is an attendee
                let attendee = ICalAttendee(
                    email: email,
                    commonName: participant.name,
                    role: convertFromJSCalendarRole(participant.roles.first),
                    participationStatus: convertFromJSCalendarStatus(participant.participationStatus),
                    rsvp: participant.expectReply ?? false
                )
                attendees.append(attendee)
            }
        }

        event.organizer = organizer
        event.attendees = attendees

        // Convert locations
        if let location = jsCalendar.locations.values.first {
            event.location = location.name
        }

        // Convert virtual locations to URL
        if let virtualLocation = jsCalendar.virtualLocations.values.first,
            let uri = virtualLocation.uri
        {
            event.url = uri
        }

        // Convert categories
        event.categories = Array(jsCalendar.categories.keys)

        // Convert links to attachments
        var attachments: [ICalAttachment] = []
        for link in jsCalendar.links.values {
            let attachment = ICalAttachment(
                uri: link.href,
                mediaType: link.contentType
            )
            attachments.append(attachment)
        }
        event.attachments = attachments

        return event
    }

    // MARK: - Helper Methods

    private static func convertAttendeeRole(_ role: ICalRole?) -> [JSCalendarParticipant.ParticipantRole] {
        switch role {
        case .chair: return [.chair]
        case .requiredParticipant: return [.attendee]
        case .optionalParticipant: return [.optional]
        case .nonParticipant: return [.informational]
        default: return [.attendee]
        }
    }

    private static func convertParticipationStatus(_ status: ICalParticipationStatus?) -> JSCalendarParticipant.ParticipationStatus? {
        switch status {
        case .needsAction: return .needsAction
        case .accepted: return .accepted
        case .declined: return .declined
        case .tentative: return .tentative
        case .delegated: return .delegated
        default: return nil
        }
    }

    private static func convertFromJSCalendarRole(_ role: JSCalendarParticipant.ParticipantRole?) -> ICalRole {
        switch role {
        case .chair: return .chair
        case .attendee: return .requiredParticipant
        case .optional: return .optionalParticipant
        case .informational: return .nonParticipant
        default: return .requiredParticipant
        }
    }

    private static func convertFromJSCalendarStatus(_ status: JSCalendarParticipant.ParticipationStatus?) -> ICalParticipationStatus {
        switch status {
        case .needsAction: return .needsAction
        case .accepted: return .accepted
        case .declined: return .declined
        case .tentative: return .tentative
        case .delegated: return .delegated
        default: return .needsAction
        }
    }

    private static func formatJSCalendarDateTime(_ dateTime: ICalDateTime) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        return formatter.string(from: dateTime.date)
    }

    private static func parseJSCalendarDateTime(_ jsDateTime: JSCalendarDateTime) -> ICalDateTime? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]

        guard let date = formatter.date(from: jsDateTime.dateTime) else { return nil }

        let timeZone: TimeZone
        if let tzId = jsDateTime.timeZone {
            timeZone = TimeZone(identifier: tzId) ?? .current
        } else {
            timeZone = .current
        }

        return ICalDateTime(date: date, timeZone: timeZone)
    }

    private static func calculateDuration(start: ICalDateTime?, end: ICalDateTime?) -> String? {
        guard let start = start, let end = end else { return nil }

        let duration = end.date.timeIntervalSince(start.date)
        return formatISO8601Duration(duration)
    }

    private static func formatISO8601Duration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))

        var result = "PT"
        if hours > 0 { result += "\(hours)H" }
        if minutes > 0 { result += "\(minutes)M" }
        if seconds > 0 { result += "\(seconds)S" }

        return result.isEmpty ? "PT0S" : result
    }

    private static func parseISO8601Duration(_ duration: String) -> TimeInterval {
        // Simple parser for PT1H30M format
        let scanner = Scanner(string: duration)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "PT")

        var totalSeconds: TimeInterval = 0

        while !scanner.isAtEnd {
            if let value = scanner.scanInt() {
                if scanner.scanString("H") != nil {
                    totalSeconds += TimeInterval(value * 3600)
                } else if scanner.scanString("M") != nil {
                    totalSeconds += TimeInterval(value * 60)
                } else if scanner.scanString("S") != nil {
                    totalSeconds += TimeInterval(value)
                }
            } else {
                scanner.currentIndex = scanner.string.index(after: scanner.currentIndex)
            }
        }

        return totalSeconds
    }

    private static func isVirtualMeetingURL(_ url: String) -> Bool {
        let virtualMeetingDomains = [
            "zoom.us", "meet.google.com", "teams.microsoft.com",
            "webex.com", "gotomeeting.com", "bluejeans.com",
        ]

        return virtualMeetingDomains.contains { url.contains($0) }
    }

    private static func inferVirtualFeatures(from url: String) -> [JSCalendarVirtualLocation.VirtualLocationFeature] {
        var features: [JSCalendarVirtualLocation.VirtualLocationFeature] = [.audio, .video]

        // Most modern platforms support these
        if url.contains("zoom.us") || url.contains("meet.google.com") || url.contains("teams.microsoft.com") {
            features.append(contentsOf: [.chat, .screen])
        }

        return features
    }
}

// MARK: - Extensions

extension ICalEvent {
    /// Convert this event to JSCalendar format
    public func toJSCalendar() -> ICalJSCalendarConverter.JSCalendarObject {
        ICalJSCalendarConverter.convertToJSCalendar(self)
    }

    /// Create event from JSCalendar object
    public static func fromJSCalendar(_ jsCalendar: ICalJSCalendarConverter.JSCalendarObject) -> ICalEvent {
        ICalJSCalendarConverter.convertFromJSCalendar(jsCalendar)
    }

    /// Add JSCalendar metadata to the event
    public mutating func addJSCalendarMetadata(_ jsCalendar: ICalJSCalendarConverter.JSCalendarObject) {
        setPropertyValue("X-JSCALENDAR-TYPE", value: jsCalendar.type.rawValue)

        if let locale = jsCalendar.locale {
            setPropertyValue("X-JSCALENDAR-LOCALE", value: locale)
        }

        // Store virtual location features
        for (id, virtualLocation) in jsCalendar.virtualLocations {
            let featuresString = virtualLocation.features.map { $0.rawValue }.joined(separator: ",")
            setPropertyValue("X-VIRTUAL-LOCATION-\(id.uppercased())-FEATURES", value: featuresString)
        }

        // Store participant kinds
        for (id, participant) in jsCalendar.participants {
            if let kind = participant.kind {
                setPropertyValue("X-PARTICIPANT-\(id.uppercased())-KIND", value: kind.rawValue)
            }

            if !participant.roles.isEmpty {
                let rolesString = participant.roles.map { $0.rawValue }.joined(separator: ",")
                setPropertyValue("X-PARTICIPANT-\(id.uppercased())-ROLES", value: rolesString)
            }
        }
    }
}

extension ICalendar {
    /// Convert this calendar to JSCalendar format
    public func toJSCalendar() -> [ICalJSCalendarConverter.JSCalendarObject] {
        events.map { $0.toJSCalendar() }
    }
}
