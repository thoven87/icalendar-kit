import Foundation

// MARK: - RFC 9253/9074/9073 Advanced Features

/// Advanced iCalendar features from recent RFCs
/// RFC 9253: JSCalendar Internet Calendaring and Scheduling Core Object Specification
/// RFC 9074: "VALARM" Extensions for iCalendar
/// RFC 9073: Event Publishing Extensions to iCalendar
public struct ICalAdvancedRFCFeatures: Sendable {

    // MARK: - RFC 9253 JSCalendar Integration

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

    // MARK: - RFC 9074 VALARM Extensions

    /// Enhanced alarm with RFC 9074 features
    public struct EnhancedAlarm: Codable, Sendable {
        public let uid: String
        public let action: AlarmAction
        public let trigger: AlarmTrigger
        public let proximity: ProximityAlarm?
        public let acknowledged: Date?
        public let relatedTo: String?
        public let defaultAlarm: Bool
        public let alarmAgent: AlarmAgent?
        public let snooze: SnoozeConfiguration?

        public enum AlarmAction: String, CaseIterable, Codable, Sendable {
            case audio = "AUDIO"
            case display = "DISPLAY"
            case email = "EMAIL"
            case procedure = "PROCEDURE"
            case uri = "URI"
        }

        public struct AlarmTrigger: Codable, Sendable {
            public let type: TriggerType
            public let value: String
            public let related: TriggerRelation?

            public enum TriggerType: String, CaseIterable, Codable, Sendable {
                case duration = "DURATION"
                case dateTime = "DATE-TIME"
                case proximity = "PROXIMITY"
            }

            public enum TriggerRelation: String, CaseIterable, Codable, Sendable {
                case start = "START"
                case end = "END"
            }

            public init(type: TriggerType, value: String, related: TriggerRelation? = nil) {
                self.type = type
                self.value = value
                self.related = related
            }
        }

        public struct ProximityAlarm: Codable, Sendable {
            public let region: String
            public let proximity: ProximityType
            public let locationId: String?

            public enum ProximityType: String, CaseIterable, Codable, Sendable {
                case arrive = "ARRIVE"
                case depart = "DEPART"
                case connect = "CONNECT"
                case disconnect = "DISCONNECT"
            }

            public init(region: String, proximity: ProximityType, locationId: String? = nil) {
                self.region = region
                self.proximity = proximity
                self.locationId = locationId
            }
        }

        public struct AlarmAgent: Codable, Sendable {
            public let uri: String
            public let id: String?

            public init(uri: String, id: String? = nil) {
                self.uri = uri
                self.id = id
            }
        }

        public struct SnoozeConfiguration: Codable, Sendable {
            public let duration: String
            public let `repeat`: Int?

            public init(duration: String, repeat: Int? = nil) {
                self.duration = duration
                self.`repeat` = `repeat`
            }
        }

        public init(
            uid: String = UUID().uuidString,
            action: AlarmAction,
            trigger: AlarmTrigger,
            proximity: ProximityAlarm? = nil,
            acknowledged: Date? = nil,
            relatedTo: String? = nil,
            defaultAlarm: Bool = false,
            alarmAgent: AlarmAgent? = nil,
            snooze: SnoozeConfiguration? = nil
        ) {
            self.uid = uid
            self.action = action
            self.trigger = trigger
            self.proximity = proximity
            self.acknowledged = acknowledged
            self.relatedTo = relatedTo
            self.defaultAlarm = defaultAlarm
            self.alarmAgent = alarmAgent
            self.snooze = snooze
        }
    }

    // MARK: - RFC 9073 Event Publishing Extensions

    /// Event publishing metadata
    public struct EventPublishingInfo: Codable, Sendable {
        public let publicEvent: Bool
        public let categories: [PublishingCategory]
        public let audience: EventAudience?
        public let accessibility: AccessibilityInfo?
        public let registrationInfo: RegistrationInfo?
        public let costInfo: CostInfo?
        public let contactInfo: ContactInfo?

        public enum PublishingCategory: String, CaseIterable, Codable, Sendable {
            case anniversary = "ANNIVERSARY"
            case appointment = "APPOINTMENT"
            case business = "BUSINESS"
            case education = "EDUCATION"
            case holiday = "HOLIDAY"
            case meeting = "MEETING"
            case miscellaneous = "MISCELLANEOUS"
            case personal = "PERSONAL"
            case phoneCall = "PHONE-CALL"
            case sickDay = "SICK-DAY"
            case specialOccasion = "SPECIAL-OCCASION"
            case travel = "TRAVEL"
            case vacation = "VACATION"
        }

        public enum EventAudience: String, CaseIterable, Codable, Sendable {
            case `public` = "PUBLIC"
            case `private` = "PRIVATE"
            case confidential = "CONFIDENTIAL"
            case restricted = "RESTRICTED"
        }

        public struct AccessibilityInfo: Codable, Sendable {
            public let wheelchairAccessible: Bool?
            public let assistiveListening: Bool?
            public let signLanguage: Bool?
            public let closedCaptions: Bool?
            public let audioDescription: Bool?
            public let accessibilityNotes: String?

            public init(
                wheelchairAccessible: Bool? = nil,
                assistiveListening: Bool? = nil,
                signLanguage: Bool? = nil,
                closedCaptions: Bool? = nil,
                audioDescription: Bool? = nil,
                accessibilityNotes: String? = nil
            ) {
                self.wheelchairAccessible = wheelchairAccessible
                self.assistiveListening = assistiveListening
                self.signLanguage = signLanguage
                self.closedCaptions = closedCaptions
                self.audioDescription = audioDescription
                self.accessibilityNotes = accessibilityNotes
            }
        }

        public struct RegistrationInfo: Codable, Sendable {
            public let required: Bool
            public let url: String?
            public let deadline: Date?
            public let capacity: Int?
            public let currentAttendance: Int?

            public init(
                required: Bool = false,
                url: String? = nil,
                deadline: Date? = nil,
                capacity: Int? = nil,
                currentAttendance: Int? = nil
            ) {
                self.required = required
                self.url = url
                self.deadline = deadline
                self.capacity = capacity
                self.currentAttendance = currentAttendance
            }
        }

        public struct CostInfo: Codable, Sendable {
            public let free: Bool
            public let price: String?
            public let currency: String?
            public let paymentMethods: [PaymentMethod]

            public enum PaymentMethod: String, CaseIterable, Codable, Sendable {
                case cash = "CASH"
                case check = "CHECK"
                case creditCard = "CREDIT-CARD"
                case debitCard = "DEBIT-CARD"
                case bankTransfer = "BANK-TRANSFER"
                case paypal = "PAYPAL"
                case venmo = "VENMO"
                case applePay = "APPLE-PAY"
                case googlePay = "GOOGLE-PAY"
            }

            public init(
                free: Bool = true,
                price: String? = nil,
                currency: String? = nil,
                paymentMethods: [PaymentMethod] = []
            ) {
                self.free = free
                self.price = price
                self.currency = currency
                self.paymentMethods = paymentMethods
            }
        }

        public struct ContactInfo: Codable, Sendable {
            public let name: String?
            public let email: String?
            public let phone: String?
            public let website: String?
            public let socialMedia: [String: String]

            public init(
                name: String? = nil,
                email: String? = nil,
                phone: String? = nil,
                website: String? = nil,
                socialMedia: [String: String] = [:]
            ) {
                self.name = name
                self.email = email
                self.phone = phone
                self.website = website
                self.socialMedia = socialMedia
            }
        }

        public init(
            publicEvent: Bool = false,
            categories: [PublishingCategory] = [],
            audience: EventAudience? = nil,
            accessibility: AccessibilityInfo? = nil,
            registrationInfo: RegistrationInfo? = nil,
            costInfo: CostInfo? = nil,
            contactInfo: ContactInfo? = nil
        ) {
            self.publicEvent = publicEvent
            self.categories = categories
            self.audience = audience
            self.accessibility = accessibility
            self.registrationInfo = registrationInfo
            self.costInfo = costInfo
            self.contactInfo = contactInfo
        }
    }

    // MARK: - Structured Data Properties

    /// Structured data representation (RFC 9074)
    public struct StructuredData: Codable, Sendable {
        public let contentType: String
        public let href: String?
        public let inline: String?
        public let encoding: DataEncoding?
        public let schema: String?
        public let metadata: [String: String]

        public enum DataEncoding: String, CaseIterable, Codable, Sendable {
            case base64 = "BASE64"
            case quotedPrintable = "QUOTED-PRINTABLE"
            case eightBit = "8BIT"
            case binary = "BINARY"
        }

        public init(
            contentType: String,
            href: String? = nil,
            inline: String? = nil,
            encoding: DataEncoding? = nil,
            schema: String? = nil,
            metadata: [String: String] = [:]
        ) {
            self.contentType = contentType
            self.href = href
            self.inline = inline
            self.encoding = encoding
            self.schema = schema
            self.metadata = metadata
        }
    }

    /// Styled description with markup support
    public struct StyledDescription: Codable, Sendable {
        public let text: String
        public let markup: MarkupType
        public let language: String?
        public let alternatives: [AlternativeDescription]

        public enum MarkupType: String, CaseIterable, Codable, Sendable {
            case text = "TEXT"
            case html = "HTML"
            case markdown = "MARKDOWN"
            case rtf = "RTF"
        }

        public struct AlternativeDescription: Codable, Sendable {
            public let text: String
            public let markup: MarkupType
            public let language: String?

            public init(text: String, markup: MarkupType, language: String? = nil) {
                self.text = text
                self.markup = markup
                self.language = language
            }
        }

        public init(
            text: String,
            markup: MarkupType = .text,
            language: String? = nil,
            alternatives: [AlternativeDescription] = []
        ) {
            self.text = text
            self.markup = markup
            self.language = language
            self.alternatives = alternatives
        }
    }

    // MARK: - Advanced Recurrence Patterns

    /// Enhanced recurrence with RFC extensions
    public struct EnhancedRecurrence: Codable, Sendable {
        public let frequency: RecurrenceFrequency
        public let interval: Int
        public let count: Int?
        public let until: Date?
        public let byRules: ByRules
        public let workweekStart: Weekday
        public let skip: SkipBehavior?
        public let rscale: String?  // Non-Gregorian calendar scale

        public enum RecurrenceFrequency: String, CaseIterable, Codable, Sendable {
            case secondly = "SECONDLY"
            case minutely = "MINUTELY"
            case hourly = "HOURLY"
            case daily = "DAILY"
            case weekly = "WEEKLY"
            case monthly = "MONTHLY"
            case yearly = "YEARLY"
        }

        public enum Weekday: String, CaseIterable, Codable, Sendable {
            case sunday = "SU"
            case monday = "MO"
            case tuesday = "TU"
            case wednesday = "WE"
            case thursday = "TH"
            case friday = "FR"
            case saturday = "SA"
        }

        public enum SkipBehavior: String, CaseIterable, Codable, Sendable {
            case omit = "OMIT"
            case backward = "BACKWARD"
            case forward = "FORWARD"
        }

        public struct ByRules: Codable, Sendable {
            public let bySecond: [Int]
            public let byMinute: [Int]
            public let byHour: [Int]
            public let byDay: [String]
            public let byMonthDay: [Int]
            public let byYearDay: [Int]
            public let byWeekNo: [Int]
            public let byMonth: [Int]
            public let bySetPos: [Int]

            public init(
                bySecond: [Int] = [],
                byMinute: [Int] = [],
                byHour: [Int] = [],
                byDay: [String] = [],
                byMonthDay: [Int] = [],
                byYearDay: [Int] = [],
                byWeekNo: [Int] = [],
                byMonth: [Int] = [],
                bySetPos: [Int] = []
            ) {
                self.bySecond = bySecond
                self.byMinute = byMinute
                self.byHour = byHour
                self.byDay = byDay
                self.byMonthDay = byMonthDay
                self.byYearDay = byYearDay
                self.byWeekNo = byWeekNo
                self.byMonth = byMonth
                self.bySetPos = bySetPos
            }
        }

        public init(
            frequency: RecurrenceFrequency,
            interval: Int = 1,
            count: Int? = nil,
            until: Date? = nil,
            byRules: ByRules = ByRules(),
            workweekStart: Weekday = .monday,
            skip: SkipBehavior? = nil,
            rscale: String? = nil
        ) {
            self.frequency = frequency
            self.interval = interval
            self.count = count
            self.until = until
            self.byRules = byRules
            self.workweekStart = workweekStart
            self.skip = skip
            self.rscale = rscale
        }
    }
}

// MARK: - Advanced RFC Features Manager

/// Manager for advanced RFC features
public struct ICalAdvancedRFCManager: Sendable {

    /// Convert iCalendar event to JSCalendar
    public static func convertToJSCalendar(_ event: ICalEvent) -> ICalAdvancedRFCFeatures.JSCalendarObject {
        var participants: [String: ICalAdvancedRFCFeatures.JSCalendarParticipant] = [:]

        for (index, attendee) in event.attendees.enumerated() {
            let participant = ICalAdvancedRFCFeatures.JSCalendarParticipant(
                name: attendee.commonName,
                email: attendee.email,
                kind: .individual,
                roles: [.attendee],
                participationStatus: jsCalendarStatus(from: attendee.participationStatus)
            )
            participants["participant-\(index)"] = participant
        }

        var locations: [String: ICalAdvancedRFCFeatures.JSCalendarLocation] = [:]
        if let locationText = event.location {
            let location = ICalAdvancedRFCFeatures.JSCalendarLocation(
                name: locationText,
                locationTypes: [.physical]
            )
            locations["location-1"] = location
        }

        let start = event.dateTimeStart.map { dt in
            ICalAdvancedRFCFeatures.JSCalendarDateTime(
                dateTime: ICalendarFormatter.format(dateTime: dt),
                timeZone: dt.timeZone?.identifier
            )
        }

        return ICalAdvancedRFCFeatures.JSCalendarObject(
            type: .event,
            uid: event.uid,
            title: event.summary,
            description: event.description,
            start: start,
            timeZone: event.dateTimeStart?.timeZone?.identifier,
            participants: participants,
            locations: locations
        )
    }

    /// Convert JSCalendar participation status
    private static func jsCalendarStatus(
        from icalStatus: ICalParticipationStatus?
    ) -> ICalAdvancedRFCFeatures.JSCalendarParticipant.ParticipationStatus? {
        switch icalStatus {
        case .needsAction: return .needsAction
        case .accepted: return .accepted
        case .declined: return .declined
        case .tentative: return .tentative
        case .delegated: return .delegated
        default: return nil
        }
    }

    /// Create enhanced alarm with RFC 9074 features
    public static func createEnhancedAlarm(
        action: ICalAdvancedRFCFeatures.EnhancedAlarm.AlarmAction,
        trigger: String,
        proximity: ICalAdvancedRFCFeatures.EnhancedAlarm.ProximityAlarm? = nil
    ) -> ICalAdvancedRFCFeatures.EnhancedAlarm {
        let alarmTrigger = ICalAdvancedRFCFeatures.EnhancedAlarm.AlarmTrigger(
            type: proximity != nil ? .proximity : .duration,
            value: trigger
        )

        return ICalAdvancedRFCFeatures.EnhancedAlarm(
            action: action,
            trigger: alarmTrigger,
            proximity: proximity
        )
    }

    /// Add structured data to event
    public static func addStructuredData(
        to event: inout ICalEvent,
        data: ICalAdvancedRFCFeatures.StructuredData
    ) {
        event.setPropertyValue("STRUCTURED-DATA", value: data.contentType)

        if let href = data.href {
            event.setPropertyValue("X-STRUCTURED-DATA-HREF", value: href)
        }

        if let inline = data.inline {
            event.setPropertyValue("X-STRUCTURED-DATA-INLINE", value: inline)
        }

        if let encoding = data.encoding {
            event.setPropertyValue("X-STRUCTURED-DATA-ENCODING", value: encoding.rawValue)
        }

        if let schema = data.schema {
            event.setPropertyValue("X-STRUCTURED-DATA-SCHEMA", value: schema)
        }

        for (key, value) in data.metadata {
            event.setPropertyValue("X-STRUCTURED-DATA-\(key.uppercased())", value: value)
        }
    }

    /// Add styled description
    public static func addStyledDescription(
        to event: inout ICalEvent,
        description: ICalAdvancedRFCFeatures.StyledDescription
    ) {
        event.description = description.text
        event.setPropertyValue("X-STYLED-DESCRIPTION-MARKUP", value: description.markup.rawValue)

        if let language = description.language {
            event.setPropertyValue("X-STYLED-DESCRIPTION-LANG", value: language)
        }

        for (index, alternative) in description.alternatives.enumerated() {
            let prefix = "X-STYLED-DESCRIPTION-ALT-\(index)"
            event.setPropertyValue("\(prefix)-TEXT", value: alternative.text)
            event.setPropertyValue("\(prefix)-MARKUP", value: alternative.markup.rawValue)

            if let language = alternative.language {
                event.setPropertyValue("\(prefix)-LANG", value: language)
            }
        }
    }

    /// Add publishing information
    public static func addPublishingInfo(
        to event: inout ICalEvent,
        publishingInfo: ICalAdvancedRFCFeatures.EventPublishingInfo
    ) {
        event.setPropertyValue("X-PUBLIC-EVENT", value: publishingInfo.publicEvent ? "TRUE" : "FALSE")

        if let audience = publishingInfo.audience {
            event.classification = ICalClassification(rawValue: audience.rawValue.lowercased())
        }

        // Add categories
        let categoryStrings = publishingInfo.categories.map { $0.rawValue }
        if !categoryStrings.isEmpty {
            event.categories = categoryStrings
        }

        // Add accessibility info
        if let accessibility = publishingInfo.accessibility {
            if let wheelchairAccessible = accessibility.wheelchairAccessible {
                event.setPropertyValue("X-WHEELCHAIR-ACCESSIBLE", value: wheelchairAccessible ? "TRUE" : "FALSE")
            }

            if let assistiveListening = accessibility.assistiveListening {
                event.setPropertyValue("X-ASSISTIVE-LISTENING", value: assistiveListening ? "TRUE" : "FALSE")
            }

            if let signLanguage = accessibility.signLanguage {
                event.setPropertyValue("X-SIGN-LANGUAGE", value: signLanguage ? "TRUE" : "FALSE")
            }

            if let accessibilityNotes = accessibility.accessibilityNotes {
                event.setPropertyValue("X-ACCESSIBILITY-NOTES", value: accessibilityNotes)
            }
        }

        // Add registration info
        if let registration = publishingInfo.registrationInfo {
            event.setPropertyValue("X-REGISTRATION-REQUIRED", value: registration.required ? "TRUE" : "FALSE")

            if let url = registration.url {
                event.setPropertyValue("X-REGISTRATION-URL", value: url)
            }

            if let deadline = registration.deadline {
                event.setPropertyValue("X-REGISTRATION-DEADLINE", value: ICalendarFormatter.format(dateTime: ICalDateTime(date: deadline)))
            }

            if let capacity = registration.capacity {
                event.setPropertyValue("X-EVENT-CAPACITY", value: String(capacity))
            }
        }

        // Add cost info
        if let cost = publishingInfo.costInfo {
            event.setPropertyValue("X-EVENT-FREE", value: cost.free ? "TRUE" : "FALSE")

            if let price = cost.price {
                event.setPropertyValue("X-EVENT-PRICE", value: price)
            }

            if let currency = cost.currency {
                event.setPropertyValue("X-EVENT-CURRENCY", value: currency)
            }

            if !cost.paymentMethods.isEmpty {
                let paymentMethodsString = cost.paymentMethods.map { $0.rawValue }.joined(separator: ",")
                event.setPropertyValue("X-PAYMENT-METHODS", value: paymentMethodsString)
            }
        }

        // Add contact info
        if let contact = publishingInfo.contactInfo {
            if let name = contact.name {
                event.setPropertyValue("X-CONTACT-NAME", value: name)
            }

            if let email = contact.email {
                event.setPropertyValue("X-CONTACT-EMAIL", value: email)
            }

            if let phone = contact.phone {
                event.setPropertyValue("X-CONTACT-PHONE", value: phone)
            }

            if let website = contact.website {
                event.setPropertyValue("X-CONTACT-WEBSITE", value: website)
            }

            for (platform, handle) in contact.socialMedia {
                event.setPropertyValue("X-CONTACT-SOCIAL-\(platform.uppercased())", value: handle)
            }
        }
    }

    /// Create enhanced recurrence
    public static func createEnhancedRecurrence(
        frequency: ICalAdvancedRFCFeatures.EnhancedRecurrence.RecurrenceFrequency,
        interval: Int = 1,
        count: Int? = nil,
        rscale: String? = nil
    ) -> ICalAdvancedRFCFeatures.EnhancedRecurrence {
        ICalAdvancedRFCFeatures.EnhancedRecurrence(
            frequency: frequency,
            interval: interval,
            count: count,
            rscale: rscale
        )
    }
}

// MARK: - Extensions for Advanced RFC Features

extension ICalEvent {
    /// Add JSCalendar metadata
    public mutating func addJSCalendarMetadata(_ jsCalendar: ICalAdvancedRFCFeatures.JSCalendarObject) {
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
