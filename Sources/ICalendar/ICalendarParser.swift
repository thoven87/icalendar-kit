import Foundation

/// Parser for iCalendar content following RFC 5545 specifications with Swift 6 structured concurrency
public struct ICalendarParser: Sendable {

    // MARK: - Parsing State

    private enum ParsingState {
        case idle
        case inComponent(String, depth: Int)
    }

    // MARK: - Public Interface

    /// Parse iCalendar content from string
    public func parse(_ content: String) throws -> ICalendar {
        let lines = preprocessLines(content)
        return try parseLines(lines)
    }

    /// Parse iCalendar content from data
    public func parse(_ data: Data) throws -> ICalendar {
        guard let content = String(data: data, encoding: .utf8) else {
            throw ICalendarError.decodingError("Unable to decode data as UTF-8")
        }
        return try parse(content)
    }

    /// Parse iCalendar file from URL
    public func parseFile(at url: URL) throws -> ICalendar {
        let data = try Data(contentsOf: url)
        return try parse(data)
    }

    // MARK: - Line Preprocessing

    private func preprocessLines(_ content: String) -> [String] {
        // Unfold lines according to RFC 5545 Section 3.1
        let unfolded = ICalendarFormatter.unfoldLines(content)

        // Split into lines using CRLF first, then LF as fallback
        let lines: [String]
        if unfolded.contains("\r\n") {
            lines = unfolded.components(separatedBy: "\r\n")
        } else {
            lines = unfolded.components(separatedBy: "\n")
        }

        return
            lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Core Parsing Logic

    private func parseLines(_ lines: [String]) throws -> ICalendar {
        var calendar: ICalendar?
        var componentStack: [(properties: [ICalendarProperty], components: [any ICalendarComponent], name: String)] = []
        var currentProperties: [ICalendarProperty] = []
        var currentComponents: [any ICalendarComponent] = []
        var state: ParsingState = .idle

        for line in lines {
            if line.hasPrefix("BEGIN:") {
                let componentName = String(line.dropFirst(6))

                // Save current component state
                if case .inComponent(let parentName, let depth) = state {
                    // We're entering a sub-component - save current state without creating component
                    componentStack.append((properties: currentProperties, components: currentComponents, name: parentName))
                    currentProperties = []
                    currentComponents = []
                    state = .inComponent(componentName, depth: depth + 1)
                } else {
                    // Starting a new top-level component
                    state = .inComponent(componentName, depth: 0)
                }

            } else if line.hasPrefix("END:") {
                let componentName = String(line.dropFirst(4))

                switch state {
                case .inComponent(let name, let depth):
                    guard name == componentName else {
                        throw ICalendarError.invalidFormat("Mismatched component end: expected \(name), got \(componentName)")
                    }

                    if componentName == "VCALENDAR" && depth == 0 {
                        calendar = ICalendar(properties: currentProperties, components: currentComponents)
                        currentProperties = []
                        currentComponents = []
                        state = .idle
                    } else {
                        let component = try createComponent(
                            name: componentName,
                            properties: currentProperties,
                            components: currentComponents
                        )

                        // Restore parent component state if we have a parent
                        if let parentState = componentStack.popLast() {
                            currentProperties = parentState.properties
                            currentComponents = parentState.components
                            currentComponents.append(component)
                            state = .inComponent(parentState.name, depth: depth - 1)
                        } else {
                            // This is a top-level component (not VCALENDAR)
                            currentComponents.append(component)
                            currentProperties = []
                            currentComponents = []
                            state = .idle
                        }
                    }

                case .idle:
                    throw ICalendarError.invalidFormat("Unexpected END without matching BEGIN")
                }

            } else {
                // Parse property
                guard let property = ICalendarFormatter.parseProperty(line) else {
                    throw ICalendarError.invalidFormat("Invalid property format: \(line)")
                }
                currentProperties.append(property)
            }
        }

        guard let result = calendar else {
            throw ICalendarError.invalidFormat("No VCALENDAR component found")
        }

        return result
    }

    // MARK: - Component Creation

    private func createComponent(
        name: String,
        properties: [ICalendarProperty],
        components: [any ICalendarComponent]
    ) throws -> any ICalendarComponent {
        switch name {
        case "VCALENDAR":
            return ICalendar(properties: properties, components: components)
        case "VEVENT":
            return ICalEvent(properties: properties, components: components)
        case "VTODO":
            return ICalTodo(properties: properties, components: components)
        case "VJOURNAL":
            return ICalJournal(properties: properties, components: components)
        case "VALARM":
            return ICalAlarm(properties: properties, components: components)
        case "VTIMEZONE":
            return ICalTimeZone(properties: properties, components: components)
        case "STANDARD":
            return ICalTimeZoneComponent(properties: properties, components: components, isStandard: true)
        case "DAYLIGHT":
            return ICalTimeZoneComponent(properties: properties, components: components, isStandard: false)
        case "VVENUE":
            return ICalVenue(properties: properties, components: components)
        case "VLOCATION":
            return ICalLocationComponent(properties: properties, components: components)
        case "VRESOURCE":
            return ICalResourceComponent(properties: properties, components: components)
        case "VAVAILABILITY":
            return ICalAvailabilityComponent(properties: properties, components: components)
        case "AVAILABLE":
            return ICalAvailableComponent(properties: properties, components: components)
        case "BUSY":
            return ICalBusyComponent(properties: properties, components: components)
        default:
            throw ICalendarError.unsupportedComponent(name)
        }
    }

    // MARK: - Validation

    /// Validate parsed calendar for RFC compliance
    public func validate(_ calendar: ICalendar) throws {
        // Check required properties
        guard calendar.version == "2.0" else {
            throw ICalendarError.invalidPropertyValue(property: "VERSION", value: calendar.version)
        }

        guard !calendar.productId.isEmpty else {
            throw ICalendarError.missingRequiredProperty("PRODID")
        }

        // Validate components
        for component in calendar.components {
            try validateComponent(component)
        }
    }

    private func validateComponent(_ component: any ICalendarComponent) throws {
        switch component {
        case let event as ICalEvent:
            try validateEvent(event)
        case let todo as ICalTodo:
            try validateTodo(todo)
        case let journal as ICalJournal:
            try validateJournal(journal)
        case let alarm as ICalAlarm:
            try validateAlarm(alarm)
        case let timeZone as ICalTimeZone:
            try validateTimeZone(timeZone)
        default:
            break
        }
    }

    private func validateEvent(_ event: ICalEvent) throws {
        // UID is required
        if event.uid.isEmpty {
            throw ICalendarError.missingRequiredProperty("UID")
        }

        // DTSTAMP is required (now automatically guaranteed by type system)
        // No need to check since dateTimeStamp is non-optional

        // Either DTEND or DURATION must be present if DTSTART is present
        if event.dateTimeStart != nil {
            if event.dateTimeEnd == nil && event.duration == nil {
                // This is allowed for all-day events or events with no duration
            }
        }

        // Validate sub-components
        for subComponent in event.components {
            try validateComponent(subComponent)
        }
    }

    private func validateTodo(_ todo: ICalTodo) throws {
        // UID is required
        if todo.uid.isEmpty {
            throw ICalendarError.missingRequiredProperty("UID")
        }

        // DTSTAMP is required (now automatically guaranteed by type system)
        // No need to check since dateTimeStamp is non-optional

        // Validate sub-components
        for subComponent in todo.components {
            try validateComponent(subComponent)
        }
    }

    private func validateJournal(_ journal: ICalJournal) throws {
        // UID is required
        if journal.uid.isEmpty {
            throw ICalendarError.missingRequiredProperty("UID")
        }

        // DTSTAMP is required (now automatically guaranteed by type system)
        // No need to check since dateTimeStamp is non-optional
    }

    private func validateAlarm(_ alarm: ICalAlarm) throws {
        // ACTION is required
        guard alarm.action != nil else {
            throw ICalendarError.missingRequiredProperty("ACTION")
        }

        // TRIGGER is required
        guard alarm.trigger != nil else {
            throw ICalendarError.missingRequiredProperty("TRIGGER")
        }

        // Validate action-specific requirements
        if let action = alarm.action {
            switch action {
            case .display:
                // DESCRIPTION is required for display alarms
                guard alarm.description != nil else {
                    throw ICalendarError.missingRequiredProperty("DESCRIPTION")
                }
            case .proximity:
                // PROXIMITY-TRIGGER is required for proximity alarms
                guard alarm.proximityTrigger != nil else {
                    throw ICalendarError.missingRequiredProperty("PROXIMITY-TRIGGER")
                }
            case .email:
                // DESCRIPTION and SUMMARY are required for email alarms
                guard alarm.description != nil else {
                    throw ICalendarError.missingRequiredProperty("DESCRIPTION")
                }
                guard alarm.summary != nil else {
                    throw ICalendarError.missingRequiredProperty("SUMMARY")
                }
                // At least one attendee is required
                guard !alarm.attendees.isEmpty else {
                    throw ICalendarError.missingRequiredProperty("ATTENDEE")
                }
            case .audio:
                // ATTACH is optional for audio alarms
                break
            case .procedure:
                // ATTACH is required for procedure alarms
                guard alarm.attach != nil else {
                    throw ICalendarError.missingRequiredProperty("ATTACH")
                }
            }
        }
    }

    private func validateTimeZone(_ timeZone: ICalTimeZone) throws {
        // TZID is required
        guard timeZone.timeZoneId != nil else {
            throw ICalendarError.missingRequiredProperty("TZID")
        }

        // At least one STANDARD or DAYLIGHT component is required
        let hasStandardOrDaylight = timeZone.components.contains { component in
            component is ICalTimeZoneComponent
        }

        guard hasStandardOrDaylight else {
            throw ICalendarError.invalidFormat("VTIMEZONE must contain at least one STANDARD or DAYLIGHT component")
        }

        // Validate sub-components
        for subComponent in timeZone.components {
            try validateComponent(subComponent)
        }
    }
}

// MARK: - Convenience Extensions

extension ICalendarParser {

    /// Parse multiple calendars from a string containing multiple VCALENDAR objects
    public func parseMultiple(_ content: String) throws -> [ICalendar] {
        let lines = preprocessLines(content)
        var calendars: [ICalendar] = []
        var currentCalendarLines: [String] = []
        var inCalendar = false
        var nestingLevel = 0

        for line in lines {
            if line.hasPrefix("BEGIN:VCALENDAR") {
                if inCalendar {
                    nestingLevel += 1
                } else {
                    inCalendar = true
                    nestingLevel = 1
                }
                currentCalendarLines.append(line)
            } else if line.hasPrefix("END:VCALENDAR") {
                currentCalendarLines.append(line)
                nestingLevel -= 1

                if nestingLevel == 0 {
                    let calendar = try parseLines(currentCalendarLines)
                    calendars.append(calendar)
                    currentCalendarLines = []
                    inCalendar = false
                }
            } else if inCalendar {
                currentCalendarLines.append(line)
            }
        }

        if inCalendar {
            throw ICalendarError.invalidFormat("Incomplete VCALENDAR component")
        }

        return calendars
    }

    /// Parse and validate in one operation
    public func parseAndValidate(_ content: String) throws -> ICalendar {
        let calendar = try parse(content)
        try validate(calendar)
        return calendar
    }

    /// Parse with custom validation
    public func parse(_ content: String, customValidation: @Sendable (ICalendar) throws -> Void) throws -> ICalendar {
        let calendar = try parse(content)
        try customValidation(calendar)
        return calendar
    }
}
