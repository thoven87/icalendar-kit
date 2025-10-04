import Foundation

// MARK: - Result Builder

/// Result builder for constructing iCalendar components declaratively
@resultBuilder
public struct ICalendarBuilder {

    public static func buildBlock(_ components: ICalendarBuildable...) -> [any ICalendarBuildable] {
        components
    }

    public static func buildArray(_ components: [any ICalendarBuildable]) -> [any ICalendarBuildable] {
        components
    }

    public static func buildOptional(_ component: [any ICalendarBuildable]?) -> [any ICalendarBuildable] {
        component ?? []
    }

    public static func buildEither(first component: [any ICalendarBuildable]) -> [any ICalendarBuildable] {
        component
    }

    public static func buildEither(second component: [any ICalendarBuildable]) -> [any ICalendarBuildable] {
        component
    }

    public static func buildLimitedAvailability(_ component: [any ICalendarBuildable]) -> [any ICalendarBuildable] {
        component
    }

    public static func buildExpression(_ expression: ICalendarBuildable) -> ICalendarBuildable {
        expression
    }

    public static func buildExpression<T: Sequence>(_ expression: T) -> [any ICalendarBuildable] where T.Element == ICalendarBuildable {
        Array(expression)
    }

    public static func buildFinalResult(_ components: [any ICalendarBuildable]) -> [any ICalendarBuildable] {
        components.flatMap { component in
            switch component.build() {
            case .single(let item):
                return [item]
            case .multiple(let items):
                return items
            }
        }
    }
}

// MARK: - Buildable Protocol and Types

/// Protocol for items that can be built in the result builder
public protocol ICalendarBuildable: Sendable {
    func build() -> BuildResult
}

public enum BuildResult: Sendable {
    case single(ICalendarBuildable)
    case multiple([ICalendarBuildable])
}

internal struct ComponentBuildable: ICalendarBuildable {
    let component: any ICalendarComponent

    func build() -> BuildResult {
        .single(self)
    }
}

internal struct PropertyBuildable: ICalendarBuildable {
    let property: ICalendarProperty

    func build() -> BuildResult {
        .single(self)
    }
}

// MARK: - Builder Extensions

extension ICalendarBuildable {
    /// Conditionally include this buildable based on a condition
    public func `if`(_ condition: Bool) -> ConditionalBuildable {
        ConditionalBuildable(buildable: self, condition: condition)
    }
}

public struct ConditionalBuildable: ICalendarBuildable {
    let buildable: ICalendarBuildable
    let condition: Bool

    public func build() -> BuildResult {
        condition ? buildable.build() : .multiple([])
    }
}

// MARK: - Collection Support

// MARK: - Array Support

extension Array: ICalendarBuildable where Element == ICalendarBuildable {
    public func build() -> BuildResult {
        .multiple(self)
    }
}

// MARK: - ICalProperty Conformance

extension ICalProperty: ICalendarBuildable {
    public func build() -> BuildResult {
        .single(PropertyBuildable(property: self))
    }
}
