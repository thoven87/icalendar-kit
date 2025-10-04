import Foundation

/// Result builder for declarative calendar creation
@resultBuilder
public struct CalendarBuilder: Sendable {

    // MARK: - Result Builder Methods

    public static func buildBlock(_ components: CalendarComponent...) -> [CalendarComponent] {
        components
    }

    public static func buildArray(_ components: [CalendarComponent]) -> [CalendarComponent] {
        components
    }

    public static func buildOptional(_ component: CalendarComponent?) -> [CalendarComponent] {
        if let component = component {
            return [component]
        }
        return []
    }

    public static func buildEither(first component: CalendarComponent) -> CalendarComponent {
        component
    }

    public static func buildEither(second component: CalendarComponent) -> CalendarComponent {
        component
    }

    public static func buildExpression(_ expression: CalendarComponent) -> CalendarComponent {
        expression
    }

    public static func buildExpression(_ expression: ICalEvent) -> CalendarComponent {
        .event(expression)
    }

    public static func buildExpression(_ expression: ICalTodo) -> CalendarComponent {
        .todo(expression)
    }

    public static func buildExpression(_ expression: ICalJournal) -> CalendarComponent {
        .journal(expression)
    }

    public static func buildExpression(_ expression: ICalTimeZone) -> CalendarComponent {
        .timezone(expression)
    }

    public static func buildExpression<T: Sequence>(_ expression: T) -> [CalendarComponent]
    where T.Element == CalendarComponent {
        Array(expression)
    }

    public static func buildFinalResult(_ components: [CalendarComponent]) -> [CalendarComponent] {
        components.flatMap { component in
            switch component {
            case .multiple(let items):
                return items
            default:
                return [component]
            }
        }
    }
}

// MARK: - Calendar Component Wrapper

public enum CalendarComponent: Sendable, ICalendarBuildable {
    case event(ICalEvent)
    case todo(ICalTodo)
    case journal(ICalJournal)
    case timezone(ICalTimeZone)
    case property(CalendarProperty)
    case multiple([CalendarComponent])

    /// ICalendarBuildable conformance
    public func build() -> BuildResult {
        switch self {
        case .event(let event):
            return .single(ComponentBuildable(component: event))
        case .todo(let todo):
            return .single(ComponentBuildable(component: todo))
        case .journal(let journal):
            return .single(ComponentBuildable(component: journal))
        case .timezone(let timezone):
            return .single(ComponentBuildable(component: timezone))
        case .property(let property):
            return .single(PropertyBuildable(property: ICalProperty(name: property.name, value: property.value, parameters: property.parameters)))
        case .multiple(let components):
            return .multiple(components.map { $0 })
        }
    }
}

// MARK: - Calendar Property Support

public struct CalendarProperty: Sendable {
    let name: String
    let value: String
    let parameters: [String: String]

    public init(name: String, value: String, parameters: [String: String] = [:]) {
        self.name = name
        self.value = value
        self.parameters = parameters
    }
}

// MARK: - Calendar Configuration Functions

/// Sets the calendar name
public func CalendarName(_ name: String) -> CalendarComponent {
    .property(CalendarProperty(name: "X-WR-CALNAME", value: name))
}

/// Sets the calendar description
public func CalendarDescription(_ description: String) -> CalendarComponent {
    .property(CalendarProperty(name: "X-WR-CALDESC", value: description))
}

/// Sets the calendar color (RFC 7986)
public func CalendarColor(_ color: String) -> CalendarComponent {
    .property(CalendarProperty(name: "COLOR", value: color))
}

/// Sets the calendar method (PUBLISH, REQUEST, etc.)
public func CalendarMethod(_ method: String) -> CalendarComponent {
    .property(CalendarProperty(name: "METHOD", value: method))
}

/// Sets the calendar scale (default: GREGORIAN)
public func CalendarScale(_ scale: String) -> CalendarComponent {
    .property(CalendarProperty(name: "CALSCALE", value: scale))
}

/// Sets the calendar UID (RFC 7986)
public func CalendarUID(_ uid: String) -> CalendarComponent {
    .property(CalendarProperty(name: "UID", value: uid))
}

/// Sets the calendar URL
public func CalendarURL(_ url: String) -> CalendarComponent {
    .property(CalendarProperty(name: "URL", value: url))
}

/// Sets the calendar URL from URL object
public func CalendarURL(_ url: URL) -> CalendarComponent {
    .property(CalendarProperty(name: "URL", value: url.absoluteString))
}

/// Sets the calendar image
public func CalendarImage(_ imageURL: String) -> CalendarComponent {
    .property(CalendarProperty(name: "IMAGE", value: imageURL))
}

/// Sets the refresh interval
public func RefreshInterval(_ duration: ICalDuration) -> CalendarComponent {
    .property(CalendarProperty(name: "REFRESH-INTERVAL", value: ICalendarFormatter.format(duration: duration)))
}

/// Sets refresh interval with convenient time units
public func RefreshInterval(hours: Int) -> CalendarComponent {
    RefreshInterval(ICalendarFactory.createDuration(hours: hours))
}

/// Sets refresh interval with convenient time units
public func RefreshInterval(days: Int) -> CalendarComponent {
    RefreshInterval(ICalendarFactory.createDuration(days: days))
}

/// Sets the source URL
public func CalendarSource(_ sourceURL: String) -> CalendarComponent {
    .property(CalendarProperty(name: "SOURCE", value: sourceURL))
}

/// Sets the default timezone
public func DefaultTimeZone(_ timeZone: TimeZone) -> CalendarComponent {
    .property(CalendarProperty(name: "X-WR-TIMEZONE", value: timeZone.identifier))
}

/// Sets the default timezone with string identifier
public func DefaultTimeZone(_ identifier: String) -> CalendarComponent {
    .property(CalendarProperty(name: "X-WR-TIMEZONE", value: identifier))
}

/// Adds a custom property to the calendar
public func CustomProperty(name: String, value: String, parameters: [String: String] = [:]) -> CalendarComponent {
    .property(CalendarProperty(name: name, value: value, parameters: parameters))
}

// MARK: - Convenience Functions

/// Pre-configured calendar for publishing
public func PublishingCalendar() -> [CalendarComponent] {
    [
        CalendarMethod("PUBLISH"),
        CalendarScale("GREGORIAN"),
    ]
}

/// Pre-configured calendar for requests (meeting invitations)
public func RequestCalendar() -> [CalendarComponent] {
    [
        CalendarMethod("REQUEST"),
        CalendarScale("GREGORIAN"),
    ]
}

/// Sets up calendar with branding
public func BrandedCalendar(
    organizationName: String,
    organizationURL: String? = nil,
    brandColor: String? = nil
) -> [CalendarComponent] {
    var components: [CalendarComponent] = [
        CalendarName("\(organizationName) Calendar"),
        CustomProperty(name: "X-ORGANIZATION", value: organizationName),
    ]

    if let url = organizationURL {
        components.append(CalendarURL(url))
    }

    if let color = brandColor {
        components.append(CalendarColor(color))
    }

    return components
}

/// Sets up calendar for healthcare/HIPAA compliance
public func HealthcareCalendar(organizationName: String, workspaceName: String) -> [CalendarComponent] {
    [
        CalendarName("\(organizationName) - \(workspaceName)"),
        CalendarDescription("HIPAA-compliant healthcare calendar"),
        CalendarMethod("PUBLISH"),
        RefreshInterval(hours: 6),
        CustomProperty(name: "X-HEALTHCARE-COMPLIANT", value: "true"),
        CustomProperty(name: "X-ORGANIZATION", value: organizationName),
        CustomProperty(name: "X-WORKSPACE", value: workspaceName),
    ]
}

/// Sets up calendar for team/workplace scenarios
public func TeamCalendar(teamName: String, organization: String? = nil) -> [CalendarComponent] {
    var components: [CalendarComponent] = [
        CalendarName("\(teamName) Team Calendar"),
        CalendarDescription("Team calendar for \(teamName)"),
        CalendarMethod("PUBLISH"),
        RefreshInterval(hours: 2),
        CustomProperty(name: "X-TEAM", value: teamName),
    ]

    if let org = organization {
        components.append(CustomProperty(name: "X-ORGANIZATION", value: org))
    }

    return components
}

// MARK: - ICalendar Extension

extension ICalendar {
    /// Creates a calendar using CalendarBuilder result builder syntax
    public static func calendar(
        productId: String = "iCalendar-Kit//iCalendar-Kit//EN",
        version: String = "2.0",
        @CalendarBuilder _ builder: () -> [CalendarComponent]
    ) -> ICalendar {
        var calendar = ICalendar(productId: productId, version: version)
        let components = builder()

        // Process all components
        for component in components {
            switch component {
            case .event(let event):
                calendar.addEvent(event)
            case .todo(let todo):
                calendar.addTodo(todo)
            case .journal(let journal):
                calendar.addJournal(journal)
            case .timezone(let timezone):
                calendar.addTimeZone(timezone)
            case .property(let property):
                applyProperty(property, to: &calendar)
            case .multiple(let items):
                // Handle nested components
                for item in items {
                    switch item {
                    case .event(let event):
                        calendar.addEvent(event)
                    case .todo(let todo):
                        calendar.addTodo(todo)
                    case .journal(let journal):
                        calendar.addJournal(journal)
                    case .timezone(let timezone):
                        calendar.addTimeZone(timezone)
                    case .property(let property):
                        applyProperty(property, to: &calendar)
                    case .multiple:
                        break  // Avoid infinite recursion
                    }
                }
            }
        }

        calendar.applyCompliance()
        return calendar
    }

    private static func applyProperty(_ property: CalendarProperty, to calendar: inout ICalendar) {
        switch property.name {
        case "X-WR-CALNAME":
            calendar.name = property.value
        case "X-WR-CALDESC":
            calendar.calendarDescription = property.value
        case "COLOR":
            calendar.color = property.value
        case "METHOD":
            calendar.method = property.value
        case "CALSCALE":
            calendar.calendarScale = property.value
        case "UID":
            calendar.calendarUID = property.value
        case "URL":
            calendar.url = property.value
        case "IMAGE":
            calendar.image = property.value
        case "SOURCE":
            calendar.source = property.value
        case "REFRESH-INTERVAL":
            if let duration = ICalDuration.from(property.value) {
                calendar.refreshInterval = duration
            }
        default:
            // Add as custom property
            calendar.properties.removeAll { $0.name == property.name }
            calendar.properties.append(
                ICalProperty(name: property.name, value: property.value, parameters: property.parameters)
            )
        }
    }
}

// MARK: - Array Extensions for Builder Pattern

extension Array where Element == CalendarComponent {
    /// Convenience method to convert array to multiple component
    public func asComponents() -> CalendarComponent {
        .multiple(self)
    }
}
