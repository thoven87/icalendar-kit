import Foundation

/// Serializer for iCalendar content following RFC 5545 specifications with Swift 6 structured concurrency
public struct ICalendarSerializer: Sendable {

    // MARK: - Serialization Options

    public struct SerializationOptions: Sendable {
        public let lineLength: Int
        public let sortProperties: Bool
        public let includeOptionalProperties: Bool
        public let validateBeforeSerializing: Bool

        public init(
            lineLength: Int = 75,
            sortProperties: Bool = true,
            includeOptionalProperties: Bool = true,
            validateBeforeSerializing: Bool = true
        ) {
            self.lineLength = lineLength
            self.sortProperties = sortProperties
            self.includeOptionalProperties = includeOptionalProperties
            self.validateBeforeSerializing = validateBeforeSerializing
        }

        public static let `default` = SerializationOptions()
        public static let compact = SerializationOptions(
            lineLength: 75,
            sortProperties: false,
            includeOptionalProperties: false,
            validateBeforeSerializing: false
        )
    }

    private let options: SerializationOptions

    public init(options: SerializationOptions = .default) {
        self.options = options
    }

    // MARK: - Public Interface

    /// Serialize calendar to string
    public func serialize(_ calendar: ICalendar) throws -> String {
        if options.validateBeforeSerializing {
            let parser = ICalendarParser()
            try parser.validate(calendar)
        }

        return serializeComponent(calendar)
    }

    /// Serialize calendar to data
    public func serializeToData(_ calendar: ICalendar) throws -> Data {
        let content = try serialize(calendar)
        guard let data = content.data(using: String.Encoding.utf8) else {
            throw ICalendarError.encodingError("Failed to encode calendar as UTF-8")
        }
        return data
    }

    /// Serialize calendar to file
    public func serializeToFile(_ calendar: ICalendar, url: URL) throws {
        let data = try serializeToData(calendar)
        try data.write(to: url)
    }

    /// Serialize multiple calendars
    public func serialize(_ calendars: [ICalendar]) throws -> String {
        var results: [String] = []

        for calendar in calendars {
            let serialized = try serialize(calendar)
            results.append(serialized)
        }

        return results.joined(separator: "\r\n")
    }

    // MARK: - Component Serialization

    private func serializeComponent(_ component: any ICalendarComponent) -> String {
        var lines: [String] = []

        // BEGIN line
        lines.append("BEGIN:\(component.instanceComponentName)")

        // Properties
        let properties =
            options.sortProperties
            ? component.properties.sorted { $0.name < $1.name }
            : component.properties

        for property in properties {
            if options.includeOptionalProperties || isRequiredProperty(property.name, for: component) {
                lines.append(formatProperty(property))
            }
        }

        // Sub-components
        for subComponent in component.components {
            let subComponentString = serializeComponent(subComponent)
            lines.append(subComponentString)
        }

        // END line
        lines.append("END:\(component.instanceComponentName)")

        return lines.joined(separator: "\r\n")
    }

    // MARK: - Property Formatting

    private func formatProperty(_ property: ICalendarProperty) -> String {
        var line = property.name

        // Add parameters
        let parameters =
            options.sortProperties
            ? property.parameters.sorted { $0.key < $1.key }
            : Array(property.parameters)

        for (key, value) in parameters {
            let escapedValue = ICalendarFormatter.escapeParameterValue(value)
            if needsQuoting(escapedValue) {
                line += ";\(key)=\"\(escapedValue)\""
            } else {
                line += ";\(key)=\(escapedValue)"
            }
        }

        line += ":\(formatPropertyValue(property))"

        return ICalendarFormatter.foldLine(line, maxLength: options.lineLength)
    }

    /// Format property value with appropriate escaping based on property type
    private func formatPropertyValue(_ property: ICalendarProperty) -> String {
        // Structured properties that should not be escaped
        let structuredProperties = ["RRULE", "RDATE", "EXDATE", "TRIGGER"]

        if structuredProperties.contains(property.name) {
            // Return raw value without escaping for structured properties
            return property.value
        } else {
            // Apply normal text escaping for other properties
            return ICalendarFormatter.escapeText(property.value)
        }
    }

    private func needsQuoting(_ value: String) -> Bool {
        value.contains(" ") || value.contains(":") || value.contains(";") || value.contains(",") || value.contains("\"")
    }

    // MARK: - Required Property Checking

    private func isRequiredProperty(_ propertyName: String, for component: any ICalendarComponent) -> Bool {
        switch component {
        case is ICalendar:
            return ["VERSION", "PRODID"].contains(propertyName)
        case is ICalEvent:
            return ["UID", "DTSTAMP"].contains(propertyName)
        case is ICalTodo:
            return ["UID", "DTSTAMP"].contains(propertyName)
        case is ICalJournal:
            return ["UID", "DTSTAMP"].contains(propertyName)
        case is ICalAlarm:
            return ["ACTION", "TRIGGER"].contains(propertyName)
        case is ICalTimeZone:
            return ["TZID"].contains(propertyName)
        case _ as ICalTimeZoneComponent:
            return ["DTSTART", "TZOFFSETFROM", "TZOFFSETTO"].contains(propertyName)
        default:
            return true  // Unknown components - include all properties
        }
    }

    // MARK: - Specialized Serialization Methods

    /// Serialize only events from a calendar
    public func serializeEvents(_ calendar: ICalendar) throws -> String {
        var eventLines: [String] = []

        // Calendar header
        eventLines.append("BEGIN:VCALENDAR")
        eventLines.append("VERSION:2.0")
        eventLines.append("PRODID:\(calendar.productId)")

        if let calendarScale = calendar.calendarScale {
            eventLines.append("CALSCALE:\(calendarScale)")
        }

        if let method = calendar.method {
            eventLines.append("METHOD:\(method)")
        }

        // Events only
        for event in calendar.events {
            let eventString = serializeComponent(event)
            eventLines.append(eventString)
        }

        eventLines.append("END:VCALENDAR")

        return eventLines.joined(separator: "\r\n")
    }

    /// Serialize with timezone information
    public func serializeWithTimeZones(_ calendar: ICalendar) throws -> String {
        var lines: [String] = []

        // BEGIN VCALENDAR
        lines.append("BEGIN:VCALENDAR")

        // Calendar properties
        let calendarProps =
            options.sortProperties
            ? calendar.properties.sorted { $0.name < $1.name }
            : calendar.properties

        for property in calendarProps {
            lines.append(formatProperty(property))
        }

        // Time zones first
        for timeZone in calendar.timeZones {
            let tzString = serializeComponent(timeZone)
            lines.append(tzString)
        }

        // Then other components
        for component in calendar.components {
            if !(component is ICalTimeZone) {
                let componentString = serializeComponent(component)
                lines.append(componentString)
            }
        }

        lines.append("END:VCALENDAR")

        return lines.joined(separator: "\r\n")
    }

    /// Create minimal valid calendar
    public func serializeMinimal(_ calendar: ICalendar) throws -> String {
        let minimalOptions = SerializationOptions(
            lineLength: options.lineLength,
            sortProperties: options.sortProperties,
            includeOptionalProperties: false,
            validateBeforeSerializing: false
        )

        let minimalSerializer = ICalendarSerializer(options: minimalOptions)
        return try minimalSerializer.serialize(calendar)
    }

    // MARK: - Format-Specific Serialization

    /// Serialize for Outlook compatibility
    public func serializeForOutlook(_ calendar: ICalendar) -> String {
        var lines: [String] = []

        lines.append("BEGIN:VCALENDAR")
        lines.append("VERSION:2.0")
        lines.append("PRODID:\(calendar.productId)")
        lines.append("CALSCALE:GREGORIAN")
        lines.append("METHOD:PUBLISH")

        // Serialize components with Outlook-specific formatting
        for component in calendar.components {
            if let event = component as? ICalEvent {
                let eventString = serializeEventForOutlook(event)
                lines.append(eventString)
            } else {
                let componentString = serializeComponent(component)
                lines.append(componentString)
            }
        }

        lines.append("END:VCALENDAR")

        return lines.joined(separator: "\r\n")
    }

    private func serializeEventForOutlook(_ event: ICalEvent) -> String {
        var lines: [String] = []

        lines.append("BEGIN:VEVENT")

        // Required properties in Outlook-preferred order
        lines.append("UID:\(event.uid)")

        // DTSTAMP is now required and non-optional
        lines.append("DTSTAMP:\(ICalendarFormatter.format(dateTime: event.dateTimeStamp))")

        if let dtstart = event.dateTimeStart {
            lines.append("DTSTART:\(ICalendarFormatter.format(dateTime: dtstart))")
        }

        if let dtend = event.dateTimeEnd {
            lines.append("DTEND:\(ICalendarFormatter.format(dateTime: dtend))")
        }

        if let summary = event.summary {
            lines.append("SUMMARY:\(ICalendarFormatter.escapeText(summary))")
        }

        if let description = event.description {
            lines.append("DESCRIPTION:\(ICalendarFormatter.escapeText(description))")
        }

        if let location = event.location {
            lines.append("LOCATION:\(ICalendarFormatter.escapeText(location))")
        }

        // Add other properties
        for property in event.properties {
            let requiredProps = ["UID", "DTSTAMP", "DTSTART", "DTEND", "SUMMARY", "DESCRIPTION", "LOCATION"]
            if !requiredProps.contains(property.name) {
                lines.append(formatProperty(property))
            }
        }

        // Sub-components
        for subComponent in event.components {
            let subString = serializeComponent(subComponent)
            lines.append(subString)
        }

        lines.append("END:VEVENT")

        return lines.joined(separator: "\r\n")
    }

    /// Serialize for Google Calendar compatibility
    public func serializeForGoogle(_ calendar: ICalendar) -> String {
        var lines: [String] = []

        lines.append("BEGIN:VCALENDAR")
        lines.append("VERSION:2.0")
        lines.append("PRODID:\(calendar.productId)")
        lines.append("CALSCALE:GREGORIAN")

        // Google prefers timezone components first
        for timeZone in calendar.timeZones {
            let tzString = serializeComponent(timeZone)
            lines.append(tzString)
        }

        for component in calendar.components {
            if !(component is ICalTimeZone) {
                let componentString = serializeComponent(component)
                lines.append(componentString)
            }
        }

        lines.append("END:VCALENDAR")

        return lines.joined(separator: "\r\n")
    }

    // MARK: - Pretty Printing

    /// Serialize with human-readable formatting
    public func serializePretty(_ calendar: ICalendar) -> String {
        let prettyOptions = SerializationOptions(
            lineLength: 120,  // Longer lines for readability
            sortProperties: true,
            includeOptionalProperties: true,
            validateBeforeSerializing: false
        )

        let prettySerializer = ICalendarSerializer(options: prettyOptions)
        let content = try! prettySerializer.serialize(calendar)

        // Add extra spacing between components
        return
            content
            .replacingOccurrences(of: "\r\nBEGIN:", with: "\r\n\r\nBEGIN:")
            .replacingOccurrences(of: "\r\nEND:", with: "\r\nEND:\r\n")
    }

    // MARK: - Statistics and Analysis

    /// Get serialization statistics
    public func getStatistics(_ calendar: ICalendar) -> SerializationStatistics {
        let content = try! serialize(calendar)
        let lines = content.components(separatedBy: CharacterSet.newlines)

        return SerializationStatistics(
            totalLines: lines.count,
            totalCharacters: content.count,
            componentCount: calendar.components.count,
            eventCount: calendar.events.count,
            todoCount: calendar.todos.count,
            journalCount: calendar.journals.count,
            alarmCount: calendar.events.reduce(0) { $0 + $1.alarms.count },
            timeZoneCount: calendar.timeZones.count,
            averageLineLength: lines.isEmpty ? 0 : content.count / lines.count
        )
    }
}

// MARK: - Serialization Statistics

public struct SerializationStatistics: Sendable {
    public let totalLines: Int
    public let totalCharacters: Int
    public let componentCount: Int
    public let eventCount: Int
    public let todoCount: Int
    public let journalCount: Int
    public let alarmCount: Int
    public let timeZoneCount: Int
    public let averageLineLength: Int

    public var description: String {
        """
        Serialization Statistics:
        - Total Lines: \(totalLines)
        - Total Characters: \(totalCharacters)
        - Components: \(componentCount)
        - Events: \(eventCount)
        - Todos: \(todoCount)
        - Journals: \(journalCount)
        - Alarms: \(alarmCount)
        - Time Zones: \(timeZoneCount)
        - Average Line Length: \(averageLineLength)
        """
    }
}

// MARK: - Convenience Extensions

extension ICalendarSerializer {

    /// Quick serialize to string
    public static func serialize(_ calendar: ICalendar) throws -> String {
        let serializer = ICalendarSerializer()
        return try serializer.serialize(calendar)
    }

    /// Quick serialize to data
    public static func serializeToData(_ calendar: ICalendar) throws -> Data {
        let serializer = ICalendarSerializer()
        return try serializer.serializeToData(calendar)
    }

    /// Serialize with custom line ending
    public func serialize(_ calendar: ICalendar, lineEnding: String) throws -> String {
        let content = try serialize(calendar)
        return content.replacingOccurrences(of: "\r\n", with: lineEnding)
    }
}
