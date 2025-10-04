import Foundation

// MARK: - Validation Types

/// Validation result with detailed error reporting
public enum ICalValidationResult: Sendable {
    case success
    case warnings([ICalValidationWarning])
    case errors([ICalValidationError])
    case mixed([ICalValidationWarning], [ICalValidationError])

    public var isValid: Bool {
        switch self {
        case .success, .warnings: return true
        case .errors, .mixed: return false
        }
    }

    public var hasWarnings: Bool {
        switch self {
        case .warnings, .mixed: return true
        default: return false
        }
    }

    /// Combines multiple validation results
    public static func combine(_ results: [ICalValidationResult]) -> ICalValidationResult {
        var allWarnings: [ICalValidationWarning] = []
        var allErrors: [ICalValidationError] = []

        for result in results {
            switch result {
            case .success:
                continue
            case .warnings(let warnings):
                allWarnings.append(contentsOf: warnings)
            case .errors(let errors):
                allErrors.append(contentsOf: errors)
            case .mixed(let warnings, let errors):
                allWarnings.append(contentsOf: warnings)
                allErrors.append(contentsOf: errors)
            }
        }

        switch (allWarnings.isEmpty, allErrors.isEmpty) {
        case (true, true): return .success
        case (false, true): return .warnings(allWarnings)
        case (true, false): return .errors(allErrors)
        case (false, false): return .mixed(allWarnings, allErrors)
        }
    }
}

/// Validation warning with context
public struct ICalValidationWarning: Sendable, Hashable {
    public let message: String
    public let property: String?
    public let component: String?
    public let rfc5545Section: String?

    public init(message: String, property: String? = nil, component: String? = nil, rfc5545Section: String? = nil) {
        self.message = message
        self.property = property
        self.component = component
        self.rfc5545Section = rfc5545Section
    }
}

/// Validation error with severity and context
public struct ICalValidationError: Sendable, Hashable {
    public let message: String
    public let property: String?
    public let component: String?
    public let rfc5545Section: String
    public let severity: Severity

    public enum Severity: Sendable, Hashable {
        case error
        case critical
    }

    public init(message: String, property: String? = nil, component: String? = nil, rfc5545Section: String, severity: Severity = .error) {
        self.message = message
        self.property = property
        self.component = component
        self.rfc5545Section = rfc5545Section
        self.severity = severity
    }
}

/// Validation rule types for RFC 5545 compliance
public enum ICalValidationRuleType: Sendable {
    case required([String])
    case requiredOnce([String])
    case optionalOnce([String])
    case mutuallyExclusive([String])
    case conditionallyRequired([String], condition: @Sendable (any ICalendarComponent) -> Bool)
    case custom(@Sendable (any ICalendarComponent) -> ICalValidationResult)
}

/// Validation rule with description and RFC context
public struct ICalValidationRule: Sendable {
    public let type: ICalValidationRuleType
    public let description: String
    public let rfc5545Section: String

    public init(type: ICalValidationRuleType, description: String, rfc5545Section: String) {
        self.type = type
        self.description = description
        self.rfc5545Section = rfc5545Section
    }
}
