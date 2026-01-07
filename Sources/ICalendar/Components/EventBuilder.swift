import Foundation

/// User-friendly event builder for those not familiar with iCalendar internals
/// Also serves as a result builder for creating multiple events
@resultBuilder
public struct EventBuilder: Sendable, ICalendarBuildable {
    private var event: ICalEvent

    // MARK: - Result Builder Methods

    public static func buildBlock(_ events: EventBuilder...) -> [EventBuilder] {
        Array(events)
    }

    public static func buildBlock(_ events: [EventBuilder]...) -> [EventBuilder] {
        events.flatMap { $0 }
    }

    public static func buildArray(_ events: [EventBuilder]) -> [EventBuilder] {
        events
    }

    public static func buildOptional(_ event: EventBuilder?) -> [EventBuilder] {
        [event].compactMap { $0 }
    }

    public static func buildEither(first event: EventBuilder) -> EventBuilder {
        event
    }

    public static func buildEither(second event: EventBuilder) -> EventBuilder {
        event
    }

    public static func buildEither(first events: [EventBuilder]) -> [EventBuilder] {
        events
    }

    public static func buildEither(second events: [EventBuilder]) -> [EventBuilder] {
        events
    }

    public static func buildExpression(_ expression: EventBuilder) -> EventBuilder {
        expression
    }

    public static func buildForLoopExpression(_ expression: EventBuilder) -> EventBuilder {
        expression
    }

    public static func buildFinalResult(_ events: [EventBuilder]) -> [ICalEvent] {
        events.map { $0.buildEvent() }
    }

    // MARK: - Single Event Initializers

    public init(summary: String, uid: String = UUID().uuidString) {
        self.event = ICalEvent(uid: uid, summary: summary)
        self.event.dateTimeStamp = ICalDateTime(date: Date())
    }

    // MARK: - User-Friendly Property Setters

    /// Sets the event title/summary
    public func title(_ title: String) -> EventBuilder {
        var builder = self
        builder.event.summary = title
        return builder
    }

    /// Sets the event description
    public func description(_ description: String) -> EventBuilder {
        var builder = self
        builder.event.description = description
        return builder
    }

    /// Sets the HTML description (automatically sets FMTTYPE=text/html)
    public func htmlDescription(_ htmlDescription: String) -> EventBuilder {
        var builder = self
        builder.event.htmlDescription = htmlDescription
        return builder
    }

    /// Sets alternative description with custom format type
    public func alternativeDescription(_ description: String, formatType: String) -> EventBuilder {
        var builder = self
        builder.event.setAlternativeDescription(description, formatType: formatType)
        return builder
    }

    /// Sets the event location
    public func location(_ location: String) -> EventBuilder {
        var builder = self
        builder.event.location = location
        return builder
    }

    /// Sets the start time with timezone
    public func starts(at date: Date, timeZone: TimeZone = .current) -> EventBuilder {
        var builder = self
        builder.event.dateTimeStart = ICalDateTime(date: date, timeZone: timeZone)
        return builder
    }

    /// Sets the end time with timezone
    public func ends(at date: Date, timeZone: TimeZone = .current) -> EventBuilder {
        var builder = self
        builder.event.dateTimeEnd = ICalDateTime(date: date, timeZone: timeZone)
        return builder
    }

    /// Sets duration instead of end time
    public func duration(_ duration: TimeInterval) -> EventBuilder {
        var builder = self
        builder.event.duration = ICalDuration(timeInterval: duration)
        builder.event.dateTimeEnd = nil  // Clear end time since duration is mutually exclusive
        return builder
    }

    /// Sets as all-day event
    public func allDay(on date: Date, timeZone: TimeZone = .current) -> EventBuilder {
        var builder = self
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: date)
        builder.event.dateTimeStart = ICalDateTime(date: startOfDay, timeZone: timeZone, isDateOnly: true)
        builder.event.dateTimeEnd = nil
        return builder
    }

    /// Sets event as confirmed
    public func confirmed() -> EventBuilder {
        var builder = self
        builder.event.status = .confirmed
        return builder
    }

    /// Sets event as tentative
    public func tentative() -> EventBuilder {
        var builder = self
        builder.event.status = .tentative
        return builder
    }

    /// Sets event as cancelled
    public func cancelled() -> EventBuilder {
        var builder = self
        builder.event.status = .cancelled
        return builder
    }

    /// Sets event priority (0-9, where 0 is undefined, 1 is highest priority, 9 is lowest)
    public func priority(_ priority: Int) -> EventBuilder {
        var builder = self
        builder.event.priority = max(0, min(9, priority))
        return builder
    }

    /// Sets event as high priority (priority 1)
    public func highPriority() -> EventBuilder {
        priority(1)
    }

    /// Sets event as normal priority (priority 5)
    public func normalPriority() -> EventBuilder {
        priority(5)
    }

    /// Sets event as low priority (priority 9)
    public func lowPriority() -> EventBuilder {
        priority(9)
    }

    /// Sets event as public
    public func publicEvent() -> EventBuilder {
        var builder = self
        builder.event.classification = .publicAccess
        return builder
    }

    /// Sets event as private
    public func privateEvent() -> EventBuilder {
        var builder = self
        builder.event.classification = .privateAccess
        return builder
    }

    /// Sets event as confidential
    public func confidential() -> EventBuilder {
        var builder = self
        builder.event.classification = .confidential
        return builder
    }

    /// Sets event transparency (whether it blocks calendar time)
    public func transparency(_ transparency: ICalTransparency) -> EventBuilder {
        var builder = self
        builder.event.transparency = transparency
        return builder
    }

    /// Sets event as transparent (available/free time - doesn't block other events)
    public func transparent() -> EventBuilder {
        transparency(.transparent)
    }

    /// Sets event as opaque (busy/blocked time - blocks other events)
    public func opaque() -> EventBuilder {
        transparency(.opaque)
    }

    /// Sets the event sequence number for versioning
    public func sequence(_ sequence: Int) -> EventBuilder {
        var builder = self
        builder.event.sequence = sequence
        return builder
    }

    /// Sets geographic coordinates for the event location
    public func geoCoordinates(latitude: Double, longitude: Double) -> EventBuilder {
        var builder = self
        builder.event.geo = ICalGeoCoordinate(latitude: latitude, longitude: longitude)
        return builder
    }

    /// Sets the event color for calendar theming
    public func color(_ color: String) -> EventBuilder {
        var builder = self
        builder.event.color = color
        return builder
    }

    /// Sets the event color using hex format
    public func color(hex: String) -> EventBuilder {
        let cleanHex = hex.hasPrefix("#") ? hex : "#\(hex)"
        return color(cleanHex)
    }

    /// Adds a conference/meeting URL (RFC 7986)
    public func conference(_ conferenceUrl: String) -> EventBuilder {
        var builder = self
        builder.event.conferences.append(conferenceUrl)
        return builder
    }

    /// Adds an image URL to the event (RFC 7986)
    public func image(_ imageUrl: String) -> EventBuilder {
        var builder = self
        builder.event.image = imageUrl
        return builder
    }

    /// Adds multiple image URLs to the event
    public func addImage(_ imageUrl: String) -> EventBuilder {
        var builder = self
        builder.event.images.append(imageUrl)
        return builder
    }

    /// Adds a file attachment to the event
    public func attachment(_ url: String, mediaType: String? = nil) -> EventBuilder {
        var builder = self
        let attachment = ICalAttachment(uri: url, mediaType: mediaType)
        builder.event.attachments.append(attachment)
        return builder
    }

    // MARK: - RFC 9073 Components

    /// Adds a venue component to the event (RFC 9073)
    public func venue(name: String, description: String? = nil, address: String? = nil) -> EventBuilder {
        var builder = self
        var venue = ICalVenue()
        venue.name = name
        venue.description = description
        venue.address = address
        builder.event.venues.append(venue)
        return builder
    }

    /// Adds a structured venue with detailed address information
    public func venue(
        name: String,
        description: String? = nil,
        streetAddress: String? = nil,
        locality: String? = nil,
        region: String? = nil,
        postalCode: String? = nil,
        country: String? = nil
    ) -> EventBuilder {
        var builder = self
        var venue = ICalVenue()
        venue.name = name
        venue.description = description
        venue.streetAddress = streetAddress
        venue.locality = locality
        venue.region = region
        venue.postalCode = postalCode
        venue.country = country
        builder.event.venues.append(venue)
        return builder
    }

    /// Adds a custom venue component
    public func addVenue(_ venue: ICalVenue) -> EventBuilder {
        var builder = self
        builder.event.venues.append(venue)
        return builder
    }

    /// Adds a location component to the event (RFC 9073)
    public func locationComponent(
        name: String,
        description: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        types: [String] = []
    ) -> EventBuilder {
        var builder = self
        var location = ICalLocationComponent()
        location.name = name
        location.description = description
        if let lat = latitude, let lng = longitude {
            location.geo = ICalGeoCoordinate(latitude: lat, longitude: lng)
        }
        location.locationTypes = types
        builder.event.locations.append(location)
        return builder
    }

    /// Adds a custom location component
    public func addLocationComponent(_ location: ICalLocationComponent) -> EventBuilder {
        var builder = self
        builder.event.locations.append(location)
        return builder
    }

    /// Adds a resource component to the event (RFC 9073)
    public func resource(
        name: String,
        description: String? = nil,
        type: String? = nil,
        capacity: Int? = nil,
        features: [String] = [],
        categories: [String] = []
    ) -> EventBuilder {
        var builder = self
        var resource = ICalResourceComponent()
        resource.name = name
        resource.description = description
        resource.resourceType = type
        resource.capacity = capacity
        resource.features = features
        resource.categories = categories
        builder.event.resources.append(resource)
        return builder
    }

    /// Adds a custom resource component
    public func addResource(_ resource: ICalResourceComponent) -> EventBuilder {
        var builder = self
        builder.event.resources.append(resource)
        return builder
    }

    /// Sets the organizer of the event
    public func organizer(email: String, name: String? = nil) -> EventBuilder {
        var builder = self
        builder.event.organizer = ICalAttendee(
            email: email,
            commonName: name,
            role: .chair
        )
        return builder
    }

    /// Adds an attendee to the event with full RFC 5545 support
    public func addAttendee(
        email: String,
        name: String? = nil,
        role: ICalRole = .requiredParticipant,
        status: ICalParticipationStatus = .needsAction,
        userType: ICalUserType = .individual,
        rsvp: Bool = true,
        delegatedFrom: String? = nil,
        delegatedTo: String? = nil,
        sentBy: String? = nil,
        directory: String? = nil,
        member: [String]? = nil
    ) -> EventBuilder {
        var builder = self
        let attendee = ICalAttendee(
            email: email,
            commonName: name,
            role: role,
            participationStatus: status,
            userType: userType,
            rsvp: rsvp,
            delegatedFrom: delegatedFrom,
            delegatedTo: delegatedTo,
            sentBy: sentBy,
            directory: directory,
            member: member
        )
        builder.event.attendees.append(attendee)
        return builder
    }

    /// Adds multiple attendees to the event
    public func addAttendees(_ attendees: [ICalAttendee]) -> EventBuilder {
        var builder = self
        for attendee in attendees {
            builder.event.attendees.append(attendee)
        }
        return builder
    }

    /// Sets event URL
    public func url(_ url: String) -> EventBuilder {
        var builder = self
        builder.event.url = url
        return builder
    }

    /// Sets event URL from URL object
    public func url(_ url: URL) -> EventBuilder {
        self.url(url.absoluteString)
    }

    /// Adds categories to the event
    public func categories(_ categories: String...) -> EventBuilder {
        var builder = self
        builder.event.categories = Array(categories)
        return builder
    }

    /// Makes the event repeat daily
    public func repeats(every days: Int = 1, until endDate: Date? = nil, count: Int? = nil) -> EventBuilder {
        var builder = self
        builder.event.recurrenceRule = ICalRecurrenceRule(
            frequency: .daily,
            until: endDate.map { ICalDateTime(date: $0) },
            count: count,
            interval: days
        )
        return builder
    }

    /// Makes the event repeat weekly
    public func repeatsWeekly(every weeks: Int = 1, on weekdays: [ICalWeekday] = [], until endDate: Date? = nil, count: Int? = nil) -> EventBuilder {
        var builder = self
        builder.event.recurrenceRule = ICalRecurrenceRule(
            frequency: .weekly,
            until: endDate.map { ICalDateTime(date: $0) },
            count: count,
            interval: weeks,
            byWeekday: weekdays
        )
        return builder
    }

    /// Makes the event repeat monthly
    public func repeatsMonthly(every months: Int = 1, until endDate: Date? = nil, count: Int? = nil) -> EventBuilder {
        var builder = self
        builder.event.recurrenceRule = ICalRecurrenceRule(
            frequency: .monthly,
            until: endDate.map { ICalDateTime(date: $0) },
            count: count,
            interval: months
        )
        return builder
    }

    /// Makes the event repeat weekly on weekdays only
    public func repeatsMonthlyWeekdays(every weeks: Int = 1, until endDate: Date? = nil, count: Int? = nil) -> EventBuilder {
        var builder = self
        builder.event.recurrenceRule = ICalRecurrenceRule(
            frequency: .weekly,
            until: endDate.map { ICalDateTime(date: $0) },
            count: count,
            interval: weeks,
            byWeekday: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        return builder
    }

    /// Makes the event repeat monthly on specific weekdays
    public func repeatsMonthly(every months: Int = 1, on weekdays: [ICalWeekday], until endDate: Date? = nil, count: Int? = nil) -> EventBuilder {
        var builder = self
        builder.event.recurrenceRule = ICalRecurrenceRule(
            frequency: .monthly,
            until: endDate.map { ICalDateTime(date: $0) },
            count: count,
            interval: months,
            byWeekday: weekdays
        )
        return builder
    }

    /// Makes the event repeat on first weekday of each month (PROPER monthly weekday implementation)
    public func repeatsFirstWeekdayOfMonth(weekday: ICalWeekday, every months: Int = 1, until endDate: Date? = nil, count: Int? = nil) -> EventBuilder
    {
        var builder = self
        builder.event.recurrenceRule = ICalRecurrenceRule(
            frequency: .monthly,
            until: endDate.map { ICalDateTime(date: $0) },
            count: count,
            interval: months,
            byWeekday: [weekday],
            bySetpos: [1]  // First occurrence of the weekday
        )
        return builder
    }

    /// Makes the event repeat yearly
    public func repeatsYearly(every years: Int = 1, until endDate: Date? = nil, count: Int? = nil) -> EventBuilder {
        var builder = self
        builder.event.recurrenceRule = ICalRecurrenceRule(
            frequency: .yearly,
            until: endDate.map { ICalDateTime(date: $0) },
            count: count,
            interval: years
        )
        return builder
    }

    /// Adds a reminder before the event
    public func reminderBefore(minutes: Int) -> EventBuilder {
        let displayAlarm = DisplayAlarm(trigger: "-PT\(minutes)M", description: event.summary ?? "Reminder")
        return addAlarm(.display(description: displayAlarm.description), trigger: .minutesBefore(minutes))
    }

    /// Adds exception dates (dates when recurring event should not occur)
    public func except(on dates: Date..., timeZone: TimeZone = .current) -> EventBuilder {
        var builder = self
        let exceptionDates = dates.map { ICalDateTime(date: $0, timeZone: timeZone) }
        builder.event.exceptionDates.append(contentsOf: exceptionDates)
        return builder
    }

    /// Sets the recurrence ID for this event instance
    /// Used when modifying a single occurrence of a recurring event
    public func recurrenceId(_ date: Date, timeZone: TimeZone = .current) -> EventBuilder {
        var builder = self
        builder.event.recurrenceId = ICalDateTime(date: date, timeZone: timeZone)
        return builder
    }

    /// Creates timestamp properties
    public func createdNow() -> EventBuilder {
        var builder = self
        builder.event.created = ICalDateTime(date: Date())
        return builder
    }

    /// Alarm trigger timing options
    public enum AlarmTrigger {
        case minutesBefore(Int)
        case duration(ICalDuration)
        case absoluteTime(Date, timeZone: TimeZone = .current)
        case eventStart

        internal var triggerString: String {
            switch self {
            case .minutesBefore(let minutes):
                return "-PT\(minutes)M"
            case .duration(let duration):
                return "-\(duration.description)"
            case .absoluteTime(let date, let timeZone):
                let dateTime = ICalDateTime(date: date, timeZone: timeZone)
                return ICalendarFormatter.format(dateTime: dateTime)
            case .eventStart:
                return "PT0M"
            }
        }
    }

    /// Alarm action with explicit requirements
    public enum AlarmAction {
        case display(description: String)
        case audio(attachment: ICalAttachment? = nil)
        case email(description: String, summary: String, to: ICalAttendee)
        case procedure(attachment: ICalAttachment)
        case proximity(description: String? = nil)
    }

    /// Creates an alarm with explicit action requirements
    public func addAlarm(_ action: AlarmAction, trigger: AlarmTrigger) -> EventBuilder {
        var builder = self

        let alarm: ICalAlarm
        switch action {
        case .display(let description):
            let displayAlarm = DisplayAlarm(trigger: trigger.triggerString, description: description)
            alarm = ICalAlarm(display: displayAlarm)

        case .audio(let attachment):
            let audioAlarm = AudioAlarm(trigger: trigger.triggerString, attachment: attachment)
            alarm = ICalAlarm(audio: audioAlarm)

        case .email(let description, let summary, let attendee):
            do {
                let emailAlarm = try EmailAlarm(
                    trigger: trigger.triggerString,
                    description: description,
                    summary: summary,
                    attendees: attendee
                )
                alarm = ICalAlarm(email: emailAlarm)
            } catch {
                // Fallback to display alarm if email alarm creation fails
                let displayAlarm = DisplayAlarm(trigger: trigger.triggerString, description: description)
                alarm = ICalAlarm(display: displayAlarm)
            }

        case .procedure(let attachment):
            // Procedure alarms are deprecated but still supported via properties
            alarm = ICalAlarm(
                properties: [
                    ICalProperty(name: ICalPropertyName.action, value: ICalAlarmAction.procedure.rawValue),
                    ICalProperty(name: ICalPropertyName.trigger, value: trigger.triggerString),
                    ICalProperty(name: ICalPropertyName.attach, value: attachment.value),
                ],
                components: []
            )

        case .proximity(let description):
            let proximityTrigger = ICalProximityTrigger(latitude: 0.0, longitude: 0.0, radius: 100.0, entering: true)
            let proximityAlarm = ProximityAlarm(
                proximityTrigger: proximityTrigger,
                description: description
            )
            alarm = ICalAlarm(proximity: proximityAlarm)
        }

        builder.event.addAlarm(alarm)
        return builder
    }

    /// Adds multiple alarms with their respective triggers
    public func addAlarms(_ actions: [AlarmAction], triggers: [AlarmTrigger]) -> EventBuilder {
        guard actions.count == triggers.count else {
            fatalError("Number of actions (\(actions.count)) must match number of triggers (\(triggers.count))")
        }

        var builder = self
        for (action, trigger) in zip(actions, triggers) {
            builder = builder.addAlarm(action, trigger: trigger)
        }
        return builder
    }
    /// Sets created timestamp
    public func created(at date: Date) -> EventBuilder {
        var builder = self
        builder.event.created = ICalDateTime(date: date)
        return builder
    }

    /// Updates last modified timestamp to now
    public func lastModifiedNow() -> EventBuilder {
        var builder = self
        builder.event.lastModified = ICalDateTime(date: Date())
        return builder
    }

    // MARK: - Advanced Setters

    /// Sets custom properties for power users
    public func customProperty(name: String, value: String, parameters: [String: String] = [:]) -> EventBuilder {
        var builder = self
        builder.event.properties.append(ICalProperty(name: name, value: value, parameters: parameters))
        return builder
    }

    /// Applies a custom modification
    public func modify(_ modification: (inout ICalEvent) -> Void) -> EventBuilder {
        var builder = self
        modification(&builder.event)
        return builder
    }

    // MARK: - Build

    /// Builds the final ICalEvent (for direct use and testing)
    public func buildEvent() -> ICalEvent {
        var finalEvent = event
        finalEvent.applyCompliance()  // Ensure RFC compliance
        return finalEvent
    }

    /// ICalendarBuildable conformance - builds for use in ICalendar result builder
    public func build() -> BuildResult {
        .single(buildEvent())
    }
}

// MARK: - Convenience Extensions

extension EventBuilder {
    /// Common meeting builder
    public static func meeting(
        title: String,
        startTime: Date,
        duration: TimeInterval,
        location: String? = nil,
        organizer: (email: String, name: String?)? = nil
    ) -> EventBuilder {
        var builder = EventBuilder(summary: title)
            .starts(at: startTime)
            .duration(duration)
            .confirmed()
            .createdNow()

        if let location = location {
            builder = builder.location(location)
        }

        if let organizer = organizer {
            builder = builder.organizer(email: organizer.email, name: organizer.name)
        }

        return builder
    }

    /// Common appointment builder
    public static func appointment(
        title: String,
        startTime: Date,
        endTime: Date,
        location: String? = nil
    ) -> EventBuilder {
        var builder = EventBuilder(summary: title)
            .starts(at: startTime)
            .ends(at: endTime)
            .confirmed()
            .privateEvent()
            .createdNow()

        if let location = location {
            builder = builder.location(location)
        }

        return builder
    }

    /// Birthday event builder
    public static func birthday(
        name: String,
        date: Date
    ) -> EventBuilder {
        EventBuilder(summary: "\(name)'s Birthday")
            .allDay(on: date)
            .repeatsYearly()
            .categories("Birthday", "Personal")
            .confirmed()
            .createdNow()
    }

    /// Holiday event builder
    public static func holiday(
        name: String,
        date: Date
    ) -> EventBuilder {
        EventBuilder(summary: name)
            .allDay(on: date)
            .publicEvent()
            .categories("Holiday")
            .confirmed()
            .createdNow()
    }

    /// Reminder event builder
    public static func reminder(
        title: String,
        date: Date,
        duration: TimeInterval = 0
    ) -> EventBuilder {
        var builder = EventBuilder(summary: title)
            .starts(at: date)
            .privateEvent()
            .categories("Reminder")
            .confirmed()
            .createdNow()

        if duration > 0 {
            builder = builder.duration(duration)
        }

        return builder
    }
}

// MARK: - ICalendar Extension for User-Friendly API

extension ICalendar {
    /// Creates a calendar with user-friendly event builders using result builder syntax
    public static func create(
        productId: String = ICalendarDefaults.productId,
        name: String? = nil,
        description: String? = nil,
        @EventBuilder events: () -> [ICalEvent]
    ) -> ICalendar {
        var calendar = ICalendar(productId: productId)

        if let name = name {
            calendar.name = name
        }

        if let description = description {
            calendar.calendarDescription = description
        }

        let calendarEvents = events()
        for event in calendarEvents {
            calendar.addEvent(event)
        }

        calendar.applyCompliance()
        return calendar
    }

    /// Creates a calendar with a single event
    public static func withEvent(
        productId: String = ICalendarDefaults.productId,
        event: EventBuilder
    ) -> ICalendar {
        var calendar = ICalendar(productId: productId)
        calendar.addEvent(event.buildEvent())
        calendar.applyCompliance()
        return calendar
    }

    /// Creates a calendar with multiple events from an array
    public static func withEvents(
        _ events: [EventBuilder],
        productId: String = ICalendarDefaults.productId
    ) -> ICalendar {
        var calendar = ICalendar(productId: productId)
        for eventBuilder in events {
            calendar.addEvent(eventBuilder.buildEvent())
        }
        calendar.applyCompliance()
        return calendar
    }
}

// MARK: - Weekday Extensions for User-Friendliness

extension ICalWeekday {
    public static let mon = ICalWeekday.monday
    public static let tue = ICalWeekday.tuesday
    public static let wed = ICalWeekday.wednesday
    public static let thu = ICalWeekday.thursday
    public static let fri = ICalWeekday.friday
    public static let sat = ICalWeekday.saturday
    public static let sun = ICalWeekday.sunday

    public static let weekdays: [ICalWeekday] = [.mon, .tue, .wed, .thu, .fri]
    public static let weekends: [ICalWeekday] = [.sat, .sun]
}
