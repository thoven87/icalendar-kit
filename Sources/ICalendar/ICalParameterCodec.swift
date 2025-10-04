import Foundation

// MARK: - RFC 6868 Parameter Value Encoding

/// Parameter codec for RFC 6868 compliant encoding and decoding of parameter values
/// Handles special characters (caret, newline, quotes) in iCalendar parameter values
public struct ICalParameterCodec: Sendable {

    // MARK: - Encoding Constants

    /// Encoded representation of caret character
    private static let encodedCaret = "^^"

    /// Encoded representation of newline character
    private static let encodedNewline = "^n"

    /// Encoded representation of quote character
    private static let encodedQuote = "^'"

    // MARK: - Private Helper Methods

    /// Checks if a value needs quoting (contains colon, semicolon, comma, or non-ASCII)
    private static func needsQuoting(_ value: String) -> Bool {
        value.contains(":") || value.contains(";") || value.contains(",") || containsNonASCII(value)
    }

    /// Checks if a string contains non-ASCII characters
    private static func containsNonASCII(_ value: String) -> Bool {
        value.unicodeScalars.contains { !$0.isASCII }
    }

    /// Checks if a string has parameter quotes (wrapping quotes added for parameter encoding)
    /// Parameter quotes are outer quotes with no literal quotes inside (all quotes inside should be escaped as ^')
    private static func hasParameterQuotes(_ value: String) -> Bool {
        guard value.hasPrefix("\"") && value.hasSuffix("\"") && value.count >= 2 else {
            return false
        }

        // Check the content between the outer quotes - should not contain literal quotes
        // All quotes inside should be escaped as ^'
        let inner = value.dropFirst().dropLast()
        return !inner.contains("\"")
    }

    // MARK: - Public Interface

    /// Encodes a parameter value according to RFC 6868
    /// - Parameter value: The raw parameter value to encode
    /// - Returns: The encoded parameter value, optionally wrapped in quotes
    /// - Throws: ParameterEncodingError if encoding fails
    public func encode(_ value: String) throws -> String {
        var result = ""

        for char in value {
            switch char {
            case "^":
                result.append("^^")
            case "\n":
                result.append("^n")
            case "\"":
                result.append("^'")
            default:
                result.append(char)
            }
        }

        // Apply quotes if value contains special characters that require quoting
        if Self.needsQuoting(result) {
            result = "\"\(result)\""
        }

        return result
    }

    /// Decodes a parameter value according to RFC 6868
    /// - Parameter value: The encoded parameter value to decode
    /// - Returns: The decoded parameter value with quotes removed if appropriate
    /// - Throws: ParameterDecodingError if decoding fails
    public func decode(_ value: String) throws -> String {
        var workingValue = value

        // First, check for and remove parameter quotes (outer quotes added for special chars)
        if Self.hasParameterQuotes(workingValue) {
            workingValue = String(workingValue.dropFirst().dropLast())
        }

        // Then, decode RFC 6868 escape sequences
        var i = workingValue.startIndex
        var result = ""

        while i < workingValue.endIndex {
            let char = workingValue[i]

            if char == "^" {
                // Check if we have a next character
                let nextIndex = workingValue.index(after: i)
                guard nextIndex < workingValue.endIndex else {
                    throw ParameterDecodingError.decodingFailed("Incomplete escape sequence at end of string")
                }

                let nextChar = workingValue[nextIndex]
                switch nextChar {
                case "^":
                    result.append("^")
                    i = workingValue.index(after: nextIndex)
                case "n":
                    result.append("\n")
                    i = workingValue.index(after: nextIndex)
                case "'":
                    result.append("\"")
                    i = workingValue.index(after: nextIndex)
                default:
                    throw ParameterDecodingError.decodingFailed("Invalid escape sequence: ^\\(\nextChar)")
                }
            } else {
                result.append(char)
                i = workingValue.index(after: i)
            }
        }

        return result
    }

    /// Checks if a parameter value needs encoding
    /// - Parameter value: The parameter value to check
    /// - Returns: true if the value contains characters that need RFC 6868 encoding
    public func needsEncoding(_ value: String) -> Bool {
        value.contains("^") || value.contains("\n") || value.contains("\"") || Self.needsQuoting(value)
    }

    /// Checks if a parameter value appears to be encoded
    /// - Parameter value: The parameter value to check
    /// - Returns: true if the value appears to contain RFC 6868 encoded sequences
    public func isEncoded(_ value: String) -> Bool {
        value.contains("^^") || value.contains("^n") || value.contains("^'")
    }
}

// MARK: - Error Types

/// Errors that can occur during parameter encoding
public enum ParameterEncodingError: Error, LocalizedError, Sendable {
    case invalidInput(String)
    case encodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidInput(let input):
            return "Invalid input for parameter encoding: \(input)"
        case .encodingFailed(let reason):
            return "Parameter encoding failed: \(reason)"
        }
    }
}

/// Errors that can occur during parameter decoding
public enum ParameterDecodingError: Error, LocalizedError, Sendable {
    case invalidInput(String)
    case decodingFailed(String)
    case malformedQuotedString(String)

    public var errorDescription: String? {
        switch self {
        case .invalidInput(let input):
            return "Invalid input for parameter decoding: \(input)"
        case .decodingFailed(let reason):
            return "Parameter decoding failed: \(reason)"
        case .malformedQuotedString(let input):
            return "Malformed quoted string in parameter value: \(input)"
        }
    }
}

// MARK: - Extensions

/// Extension to ICalendarProperty to support RFC 6868 parameter encoding
extension ICalendarProperty {

    /// Gets a parameter with RFC 6868 encoding applied
    /// - Parameters:
    ///   - name: Parameter name
    ///   - value: Parameter value (will be encoded if necessary)
    /// - Returns: Encoded parameter value
    public func getEncodedParameter(_ name: String, value: String) -> String {
        let codec = ICalParameterCodec()
        do {
            return try codec.encode(value)
        } catch {
            // Fallback to basic escaping if RFC 6868 encoding fails
            return ICalendarFormatter.escapeParameterValue(value)
        }
    }

    /// Gets a parameter with RFC 6868 decoding
    /// - Parameter name: Parameter name
    /// - Returns: Decoded parameter value, or nil if parameter doesn't exist
    public func getDecodedParameter(_ name: String) -> String? {
        guard let encodedValue = parameters[name] else { return nil }

        let codec = ICalParameterCodec()
        do {
            return try codec.decode(encodedValue)
        } catch {
            // Fallback to basic unescaping if RFC 6868 decoding fails
            return ICalendarFormatter.unescapeParameterValue(encodedValue)
        }
    }

    /// Gets all parameters with RFC 6868 encoding applied
    /// - Returns: Dictionary of encoded parameters
    public func getAllEncodedParameters() -> [String: String] {
        let codec = ICalParameterCodec()
        var encodedParameters: [String: String] = [:]

        for (name, value) in parameters {
            if codec.needsEncoding(value) && !codec.isEncoded(value) {
                do {
                    encodedParameters[name] = try codec.encode(value)
                } catch {
                    // Keep original value if encoding fails
                    encodedParameters[name] = value
                }
            } else {
                encodedParameters[name] = value
            }
        }

        return encodedParameters
    }

    /// Gets all parameters with RFC 6868 decoding applied
    /// - Returns: Dictionary of decoded parameters
    public func getAllDecodedParameters() -> [String: String] {
        let codec = ICalParameterCodec()
        var decodedParameters: [String: String] = [:]

        for (name, value) in parameters {
            if codec.isEncoded(value) {
                do {
                    decodedParameters[name] = try codec.decode(value)
                } catch {
                    // Keep original value if decoding fails
                    decodedParameters[name] = value
                }
            } else {
                decodedParameters[name] = value
            }
        }

        return decodedParameters
    }
}

// MARK: - Enhanced ICalendarFormatter Extensions

extension ICalendarFormatter {

    /// Formats a property with RFC 6868 parameter encoding
    /// - Parameter property: The property to format
    /// - Returns: Formatted property string with encoded parameters
    public static func formatPropertyWithParameterEncoding(_ property: ICalendarProperty) -> String {
        var line = property.name

        let codec = ICalParameterCodec()
        let sortedParameters = property.parameters.sorted { $0.key < $1.key }

        for (key, value) in sortedParameters {
            line += ";"
            line += key
            line += "="

            // Apply RFC 6868 encoding
            do {
                let encodedValue = try codec.encode(value)
                line += encodedValue
            } catch {
                // Fallback to basic escaping
                line += escapeParameterValue(value)
            }
        }

        line += ":"
        line += property.value

        return foldLine(line)
    }

    /// Parses a property line with RFC 6868 parameter decoding
    /// - Parameter line: The property line to parse
    /// - Returns: Parsed property with decoded parameters, or nil if parsing fails
    public static func parsePropertyWithParameterDecoding(_ line: String) -> ICalendarProperty? {
        guard let property = parseProperty(line) else { return nil }

        let decodedParameters = property.getAllDecodedParameters()
        return ICalProperty(name: property.name, value: property.value, parameters: decodedParameters)
    }
}

// MARK: - Test Helpers (Debug builds only)

#if DEBUG
extension ICalParameterCodec {

    /// Test data for RFC 6868 compliance testing
    public static let testCases: [(input: String, encoded: String)] = [
        ("", ""),
        ("^", "^^"),
        ("^^", "^^^^"),
        ("\n", "^n"),
        ("\"", "^'"),
        ("This is ^a \n\"test\"", "This is ^^a ^n^'test^'"),
        ("test: 1", "\"test: 1\""),
        ("test@example.com", "test@example.com"),
        ("CN=John Doe", "\"CN=John Doe\""),
        ("Multi\nLine\nValue", "Multi^nLine^nValue"),
        ("Value with \"quotes\"", "Value with ^'quotes^'"),
        ("Caret ^ and newline \n", "Caret ^^ and newline ^n"),
    ]

    /// Runs all RFC 6868 test cases
    /// - Returns: Array of failed test cases, empty if all pass
    public func runTestCases() -> [(String, String, String)] {
        var failures: [(input: String, expected: String, actual: String)] = []

        for (input, expected) in Self.testCases {
            do {
                let actual = try encode(input)
                if actual != expected {
                    failures.append((input, expected, actual))
                }

                // Test round-trip encoding/decoding
                let decoded = try decode(actual)
                if decoded != input {
                    failures.append((input, input, decoded))
                }
            } catch {
                failures.append((input, expected, "ERROR: \(error)"))
            }
        }

        return failures
    }
}
#endif
