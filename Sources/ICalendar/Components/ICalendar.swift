import Foundation

/// Main iCalendar calendar component with result builder support
public struct ICalendar: ICalendarComponent, Sendable {
    public static let componentName = "VCALENDAR"

    public var properties: [ICalendarProperty]
    public var components: [any ICalendarComponent]

    // MARK: - Required Properties

    /// Product identifier (RFC 5545 3.7.3) - REQUIRED
    public var productId: String {
        get { getPropertyValue("PRODID") ?? "" }
        set { setPropertyValue("PRODID", value: newValue) }
    }

    /// Calendar version (RFC 5545 3.7.4) - REQUIRED
    public var version: String {
        get { getPropertyValue("VERSION") ?? "2.0" }
        set { setPropertyValue("VERSION", value: newValue) }
    }

    // MARK: - Optional Properties

    /// Calendar scale (RFC 5545 3.7.1)
    public var calendarScale: String? {
        get { getPropertyValue("CALSCALE") }
        set { setPropertyValue("CALSCALE", value: newValue) }
    }

    /// Calendar method (RFC 5545 3.7.2)
    public var method: String? {
        get { getPropertyValue("METHOD") }
        set { setPropertyValue("METHOD", value: newValue) }
    }

    /// Calendar name (RFC 7986 5.1) - also sets X-WR-CALNAME for maximum compatibility
    public var name: String? {
        get { getPropertyValue("NAME") ?? getPropertyValue("X-WR-CALNAME") }
        set {
            setPropertyValue("NAME", value: newValue)
            setPropertyValue("X-WR-CALNAME", value: newValue)  // Also set legacy property for maximum compatibility
        }
    }

    /// Calendar description (RFC 7986 5.2) - serializes as X-WR-CALDESC for Apple compatibility
    public var calendarDescription: String? {
        get { getPropertyValue("X-WR-CALDESC") ?? getPropertyValue("DESCRIPTION") }
        set {
            setPropertyValue("X-WR-CALDESC", value: newValue)
            setPropertyValue("DESCRIPTION", value: newValue)  // Also set RFC 7986 standard property for maximum compatibility
        }
    }

    /// Calendar UID (RFC 7986 5.3)
    public var calendarUID: String? {
        get { getPropertyValue("UID") }
        set { setPropertyValue("UID", value: newValue) }
    }

    /// Calendar URL (RFC 7986 5.5)
    public var url: String? {
        get { getPropertyValue("URL") }
        set { setPropertyValue("URL", value: newValue) }
    }

    /// Calendar color (RFC 7986 5.9)
    public var color: String? {
        get { getPropertyValue("COLOR") }
        set { setPropertyValue("COLOR", value: newValue) }
    }

    /// Calendar image (RFC 7986 5.10)
    public var image: String? {
        get { getPropertyValue("IMAGE") }
        set { setPropertyValue("IMAGE", value: newValue) }
    }

    /// Refresh interval (RFC 7986 5.7) - also sets X-PUBLISHED-TTL for maximum compatibility
    public var refreshInterval: ICalDuration? {
        get {
            if let value = getPropertyValue("REFRESH-INTERVAL") {
                return ICalDurationParser.parse(value)
            }
            if let value = getPropertyValue("X-PUBLISHED-TTL") {
                return ICalDurationParser.parse(value)
            }
            return nil
        }
        set {
            setPropertyValue("REFRESH-INTERVAL", value: newValue?.description)
            setPropertyValue("X-PUBLISHED-TTL", value: newValue?.description)  // Also set legacy property for maximum compatibility
        }
    }

    /// Source (RFC 7986 5.8)
    public var source: String? {
        get { getPropertyValue("SOURCE") }
        set { setPropertyValue("SOURCE", value: newValue) }
    }

    // MARK: - X-WR Extension Properties

    /// Calendar display name (X-WR-CALNAME) - fallback to NAME if not set
    public var displayName: String? {
        get { getPropertyValue("X-WR-CALNAME") ?? getPropertyValue("NAME") }
        set { setPropertyValue("X-WR-CALNAME", value: newValue) }
    }

    /// Calendar description (X-WR-CALDESC)
    public var xwrDescription: String? {
        get { getPropertyValue("X-WR-CALDESC") }
        set { setPropertyValue("X-WR-CALDESC", value: newValue) }
    }

    /// Related calendar ID (X-WR-RELCALID)
    public var relatedCalendarId: String? {
        get { getPropertyValue("X-WR-RELCALID") }
        set { setPropertyValue("X-WR-RELCALID", value: newValue) }
    }

    /// Calendar time zone (X-WR-TIMEZONE)
    public var xwrTimeZone: String? {
        get { getPropertyValue("X-WR-TIMEZONE") }
        set { setPropertyValue("X-WR-TIMEZONE", value: newValue) }
    }

    /// Set calendar time zone from Foundation TimeZone
    public mutating func setXwrTimeZone(_ timeZone: TimeZone) {
        self.xwrTimeZone = timeZone.identifier
    }

    /// Get Foundation TimeZone from X-WR-TIMEZONE (if available on current system)
    public var xwrFoundationTimeZone: TimeZone? {
        guard let identifier = xwrTimeZone else { return nil }
        return TimeZone(identifier: identifier)
    }

    /// Published TTL (X-PUBLISHED-TTL) - fallback to REFRESH-INTERVAL if not set
    public var publishedTTL: String? {
        get { getPropertyValue("X-PUBLISHED-TTL") ?? getPropertyValue("REFRESH-INTERVAL") }
        set { setPropertyValue("X-PUBLISHED-TTL", value: newValue) }
    }

    // MARK: - Component Collections

    /// All events in this calendar
    public var events: [ICalEvent] {
        get { components.compactMap { $0 as? ICalEvent } }
        set {
            components = components.filter { !($0 is ICalEvent) } + newValue
        }
    }

    /// All todos in this calendar
    public var todos: [ICalTodo] {
        get { components.compactMap { $0 as? ICalTodo } }
        set {
            components = components.filter { !($0 is ICalTodo) } + newValue
        }
    }

    /// All journal entries in this calendar
    public var journals: [ICalJournal] {
        get { components.compactMap { $0 as? ICalJournal } }
        set {
            components = components.filter { !($0 is ICalJournal) } + newValue
        }
    }

    /// All timezone definitions in this calendar
    public var timeZones: [ICalTimeZone] {
        get { components.compactMap { $0 as? ICalTimeZone } }
        set {
            components = components.filter { !($0 is ICalTimeZone) } + newValue
        }
    }

    // Note: ICalFreeBusy components removed - not currently implemented

    // MARK: - Initializers

    public init(properties: [ICalendarProperty] = [], components: [any ICalendarComponent] = []) {
        self.properties = properties
        self.components = components
    }

    /// Creates a new calendar with required properties
    public init(productId: String, version: String = "2.0") {
        self.init(properties: [
            ICalProperty(name: "PRODID", value: productId),
            ICalProperty(name: "VERSION", value: version),
        ])
    }

    /// Creates a calendar using result builder syntax
    public init(
        productId: String,
        version: String = "2.0",
        @ICalendarBuilder content: () -> [any ICalendarBuildable]
    ) {
        self.init(productId: productId, version: version)

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

    // MARK: - Component Management

    /// Adds an event to the calendar
    public mutating func addEvent(_ event: ICalEvent) {
        components.append(event)
    }

    /// Adds an event with floating time (no timezone) so it appears at the same local time for all users
    public mutating func addFloatingTimeEvent(_ event: ICalEvent) {
        var floatingEvent = event
        // Remove timezone from datetime properties to make them "floating"
        if let dtstart = floatingEvent.dateTimeStart {
            floatingEvent.dateTimeStart = ICalDateTime(
                date: dtstart.date,
                timeZone: nil,
                isDateOnly: dtstart.isDateOnly
            )
        }
        if let dtend = floatingEvent.dateTimeEnd {
            floatingEvent.dateTimeEnd = ICalDateTime(
                date: dtend.date,
                timeZone: nil,
                isDateOnly: dtend.isDateOnly
            )
        }
        components.append(floatingEvent)
    }

    /// Adds an event to the calendar and automatically includes any required VTIMEZONE components
    public mutating func addEventWithAutoTimezone(_ event: ICalEvent) {
        addEvent(event)
        addRequiredTimeZonesForEvent(event)
    }

    /// Adds multiple events to the calendar
    public mutating func addEvents(_ events: [ICalEvent]) {
        components.append(contentsOf: events)
    }

    /// Adds multiple events to the calendar and automatically includes any required VTIMEZONE components
    public mutating func addEventsWithAutoTimezone(_ events: [ICalEvent]) {
        addEvents(events)
        for event in events {
            addRequiredTimeZonesForEvent(event)
        }
    }

    /// Adds a todo to the calendar
    public mutating func addTodo(_ todo: ICalTodo) {
        components.append(todo)
    }

    /// Adds multiple todos to the calendar
    public mutating func addTodos(_ todos: [ICalTodo]) {
        components.append(contentsOf: todos)
    }

    /// Adds a journal entry to the calendar
    public mutating func addJournal(_ journal: ICalJournal) {
        components.append(journal)
    }

    /// Adds a timezone definition to the calendar
    public mutating func addTimeZone(_ timeZone: ICalTimeZone) {
        components.append(timeZone)
    }

    /// Automatically adds all required VTIMEZONE components for events already in the calendar
    public mutating func addRequiredTimeZones() {
        let usedTimeZoneIds = extractUsedTimezoneIds()
        let existingTimeZoneIds = Set(timeZones.map { $0.timeZoneId })

        for tzid in usedTimeZoneIds {
            if !existingTimeZoneIds.contains(tzid) {
                if let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: tzid) {
                    addTimeZone(vtimezone)
                }
            }
        }
    }

    /// Adds required VTIMEZONE components for a specific event
    private mutating func addRequiredTimeZonesForEvent(_ event: ICalEvent) {
        let existingTimeZoneIds = Set(timeZones.map { $0.timeZoneId })

        // Check dateTimeStart
        if let tzid = event.dateTimeStart?.timeZone?.identifier, !existingTimeZoneIds.contains(tzid) {
            if let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: tzid) {
                addTimeZone(vtimezone)
            }
        }

        // Check dateTimeEnd
        if let tzid = event.dateTimeEnd?.timeZone?.identifier, !existingTimeZoneIds.contains(tzid) {
            if let vtimezone = TimeZoneRegistry.shared.getTimeZone(for: tzid) {
                addTimeZone(vtimezone)
            }
        }
    }

    /// Adds a location component to the calendar
    public mutating func addLocationComponent(_ location: ICalLocationComponent) {
        components.append(location)
    }

    /// Adds a resource component to the calendar
    public mutating func addResourceComponent(_ resource: ICalResourceComponent) {
        components.append(resource)
    }

    /// Location components in this calendar
    public var locationComponents: [ICalLocationComponent] {
        get { components.compactMap { $0 as? ICalLocationComponent } }
        set {
            components = components.filter { !($0 is ICalLocationComponent) } + newValue
        }
    }

    /// Resource components in this calendar
    public var resourceComponents: [ICalResourceComponent] {
        get { components.compactMap { $0 as? ICalResourceComponent } }
        set {
            components = components.filter { !($0 is ICalResourceComponent) } + newValue
        }
    }

    // Note: addFreeBusy method removed - ICalFreeBusy not currently implemented

    // MARK: - Event Update Methods

    /// Update an event in the calendar
    public mutating func updateEvent(withUID uid: String, updater: (inout ICalEvent) -> Void) {
        var updatedEvents = events
        if let index = updatedEvents.firstIndex(where: { $0.uid == uid }) {
            updater(&updatedEvents[index])
            self.events = updatedEvents
        }
    }

    /// Replace an event in the calendar
    public mutating func replaceEvent(_ event: ICalEvent) {
        var updatedEvents = events
        if let index = updatedEvents.firstIndex(where: { $0.uid == event.uid }) {
            updatedEvents[index] = event
            self.events = updatedEvents
        } else {
            addEvent(event)
        }
    }

    // MARK: - Validation

    /// Validates this calendar against RFC 5545 rules
    public func validate() -> ICalValidationResult {
        var errors: [ICalValidationError] = []
        var warnings: [ICalValidationWarning] = []

        // Validate required properties
        if productId.isEmpty {
            errors.append(
                ICalValidationError(
                    message: "PRODID property is REQUIRED",
                    property: "PRODID",
                    component: "VCALENDAR",
                    rfc5545Section: "3.7.3",
                    severity: .critical
                )
            )
        }

        if version.isEmpty {
            errors.append(
                ICalValidationError(
                    message: "VERSION property is REQUIRED",
                    property: "VERSION",
                    component: "VCALENDAR",
                    rfc5545Section: "3.7.4",
                    severity: .critical
                )
            )
        }

        // Validate version value
        if !version.isEmpty && version != "2.0" {
            warnings.append(
                ICalValidationWarning(
                    message: "VERSION should be '2.0' for RFC 5545 compliance",
                    property: "VERSION",
                    component: "VCALENDAR",
                    rfc5545Section: "3.7.4"
                )
            )
        }

        // Validate calendar scale
        if let scale = calendarScale, scale != "GREGORIAN" {
            warnings.append(
                ICalValidationWarning(
                    message: "Non-GREGORIAN calendar scales may have limited interoperability",
                    property: "CALSCALE",
                    component: "VCALENDAR",
                    rfc5545Section: "3.7.1"
                )
            )
        }

        // Validate component relationships (timezone references)
        let usedTimezoneIds = extractUsedTimezoneIds()
        let definedTimezoneIds = Set(
            timeZones.compactMap { tz in
                tz.timeZoneId
            }
        )

        let missingTimezones = usedTimezoneIds.subtracting(definedTimezoneIds)
            .subtracting(["UTC"])  // UTC doesn't require VTIMEZONE

        for missingTzid in missingTimezones {
            if !isStandardTimezone(missingTzid) {
                errors.append(
                    ICalValidationError(
                        message: "Missing VTIMEZONE component for timezone: \(missingTzid)",
                        property: "TZID",
                        component: "VCALENDAR",
                        rfc5545Section: "3.6.5",
                        severity: .error
                    )
                )
            }
        }

        // Validate all components
        let componentResults = components.map { $0.validate() }
        let combinedComponentResult = ICalValidationResult.combine(componentResults)

        switch combinedComponentResult {
        case .success:
            break
        case .warnings(let componentWarnings):
            warnings.append(contentsOf: componentWarnings)
        case .errors(let componentErrors):
            errors.append(contentsOf: componentErrors)
        case .mixed(let componentWarnings, let componentErrors):
            warnings.append(contentsOf: componentWarnings)
            errors.append(contentsOf: componentErrors)
        }

        // Return combined result
        switch (warnings.isEmpty, errors.isEmpty) {
        case (true, true): return .success
        case (false, true): return .warnings(warnings)
        case (true, false): return .errors(errors)
        case (false, false): return .mixed(warnings, errors)
        }
    }

    /// Applies RFC 5545 compliance rules to this calendar
    public mutating func applyCompliance() {
        // Ensure required calendar properties have defaults
        if productId.isEmpty {
            productId = "github.com/thoven87/icalendar-kit//NONSGML icalendar-kit 2.0//EN"
        }

        if version.isEmpty {
            version = "2.0"
        }

        if calendarScale == nil {
            calendarScale = "GREGORIAN"
        }

        // Apply compliance to all components (events, todos, etc.)
        for index in components.indices {
            components[index].applyCompliance()
        }

        // Validate that components have required properties
        for index in components.indices {
            if var event = components[index] as? ICalEvent {
                // Ensure events have UID (RFC 5545 requirement)
                if event.getPropertyValue(ICalPropertyName.uid) == nil {
                    event.uid = UUID().uuidString
                }

                // DTSTAMP is now automatically set by constructors

                // Also fix alarms within events
                var fixedAlarms: [ICalAlarm] = []
                for var alarm in event.alarms {
                    if alarm.action == .display && alarm.description == nil {
                        alarm.description = event.summary ?? "Reminder"
                    } else if alarm.action == .email {
                        if alarm.description == nil {
                            alarm.description = event.summary ?? "Reminder"
                        }
                        if alarm.summary == nil {
                            alarm.summary = event.summary ?? "Event Reminder"
                        }
                        if alarm.attendees.isEmpty {
                            if let organizer = event.organizer {
                                let attendee = ICalAttendee(email: organizer.email, commonName: organizer.commonName)
                                alarm.attendees = [attendee]
                            } else {
                                let attendee = ICalAttendee(email: "noreply@example.com", commonName: "Event Notification")
                                alarm.attendees = [attendee]
                            }
                        }
                    }
                    fixedAlarms.append(alarm)
                }
                event.alarms = fixedAlarms

                components[index] = event
            } else if var todo = components[index] as? ICalTodo {
                // Ensure todos have UID (RFC 5545 requirement)
                if todo.getPropertyValue(ICalPropertyName.uid) == nil {
                    todo.uid = UUID().uuidString
                }

                // DTSTAMP is now automatically set by constructors

                components[index] = todo
            } else if var journal = components[index] as? ICalJournal {
                // Ensure journals have UID (RFC 5545 requirement)
                if journal.getPropertyValue(ICalPropertyName.uid) == nil {
                    journal.uid = UUID().uuidString
                }

                // DTSTAMP is now automatically set by constructors

                components[index] = journal
            }
        }
    }

    // MARK: - Private Helpers

    private func getPropertyValue(_ name: String) -> String? {
        properties.first { $0.name == name }?.value
    }

    private mutating func setPropertyValue(_ name: String, value: String?) {
        properties.removeAll { $0.name == name }
        if let value = value {
            properties.append(ICalProperty(name: name, value: value))
        }
    }

    /// Extracts all timezone IDs referenced in events, todos, and journals
    public func extractUsedTimezoneIds() -> Set<String> {
        var timezoneIds: Set<String> = []

        // Extract from events
        for event in events {
            if let tzid = event.dateTimeStart?.timeZone?.identifier {
                timezoneIds.insert(tzid)
            }
            if let tzid = event.dateTimeEnd?.timeZone?.identifier {
                timezoneIds.insert(tzid)
            }
        }

        // Extract from todos
        for todo in todos {
            if let tzid = todo.dateTimeStart?.timeZone?.identifier {
                timezoneIds.insert(tzid)
            }
            if let tzid = todo.dueDate?.timeZone?.identifier {
                timezoneIds.insert(tzid)
            }
        }

        // Extract from journals
        for journal in journals {
            if let tzid = journal.dateTimeStart?.timeZone?.identifier {
                timezoneIds.insert(tzid)
            }
        }

        return timezoneIds
    }

    /// Checks if a timezone identifier is a standard Foundation TimeZone
    public func isStandardTimezone(_ identifier: String) -> Bool {
        TimeZone(identifier: identifier) != nil
    }

    /// Creates a floating time event from a date and time components
    /// Floating time events appear at the same local time regardless of user's timezone
    public static func createFloatingTimeEvent(
        from date: Date,
        at hour: Int,
        minute: Int = 0,
        summary: String,
        description: String? = nil,
        duration: TimeInterval = 3600  // 1 hour default
    ) -> ICalEvent {
        // Create date components without timezone
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)

        let startDate = calendar.date(
            from: DateComponents(
                year: dateComponents.year,
                month: dateComponents.month,
                day: dateComponents.day,
                hour: hour,
                minute: minute
            )
        )!

        return EventBuilder(summary: summary)
            .starts(at: startDate)  // No timezone = floating time
            .duration(duration)
            .description(description ?? "")
            .createdNow()
            .buildEvent()
    }
}

// MARK: - Convenience Extensions

extension ICalendar {
    /// Creates a calendar with a single event using result builder
    public static func withEvent(
        productId: String = "github.com/thoven87/icalendar-kit//NONSGML icalendar-kit 2.0//EN",
        event: () -> ICalEvent
    ) -> ICalendar {
        var calendar = ICalendar(productId: productId)
        calendar.addEvent(event())
        return calendar
    }

    /// Creates a calendar with multiple events
    public static func withEvents(
        _ events: [ICalEvent],
        productId: String = "github.com/thoven87/icalendar-kit//NONSGML icalendar-kit 2.0//EN"
    ) -> ICalendar {
        var calendar = ICalendar(productId: productId)
        calendar.addEvents(events)
        return calendar
    }
}

extension ICalDuration {
    var description: String {
        formatForProperty()
    }
}
