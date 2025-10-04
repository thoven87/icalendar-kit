//
//  RFC6868ParameterEncodingTests.swift
//  ICalendarTests
//
//  Tests for RFC 6868 Parameter Value Encoding
//  https://tools.ietf.org/html/rfc6868
//

import Testing

@testable import ICalendar

struct RFC6868ParameterEncodingTests {

    @Test("RFC 6868 Parameter Encoding")
    func testParameterEncoding() throws {
        let codec = ICalParameterCodec()

        // Test empty string
        #expect(try codec.encode("") == "")

        // Test single caret
        #expect(try codec.encode("^") == "^^")

        // Test double caret
        #expect(try codec.encode("^^") == "^^^^")

        // Test newline
        #expect(try codec.encode("\n") == "^n")

        // Test quote
        #expect(try codec.encode("\"") == "^'")

        // Test complex string with multiple special characters
        #expect(try codec.encode("This is ^a \n\"test\"") == "This is ^^a ^n^'test^'")
    }

    @Test("RFC 6868 Parameter Quoting")
    func testParameterQuoting() throws {
        let codec = ICalParameterCodec()

        // Values with colon, semicolon, or comma should be quoted
        #expect(try codec.encode("test: 1") == "\"test: 1\"")
        #expect(try codec.encode("test; 2") == "\"test; 2\"")
        #expect(try codec.encode("test, 3") == "\"test, 3\"")

        // Non-ASCII characters should be quoted
        #expect(try codec.encode("José") == "\"José\"")
        #expect(try codec.encode("München") == "\"München\"")

        // Regular ASCII without special chars should not be quoted
        #expect(try codec.encode("test") == "test")
        #expect(try codec.encode("test123") == "test123")
        #expect(try codec.encode("test@example.com") == "test@example.com")
    }

    @Test("RFC 6868 Parameter Decoding")
    func testParameterDecoding() throws {
        let codec = ICalParameterCodec()

        // Test empty string
        #expect(try codec.decode("") == "")

        // Test encoded caret
        #expect(try codec.decode("^^") == "^")

        // Test double encoded caret
        #expect(try codec.decode("^^^^") == "^^")

        // Test encoded newline
        #expect(try codec.decode("^n") == "\n")

        // Test encoded quote
        #expect(try codec.decode("^'") == "\"")

        // Test complex encoded string
        #expect(try codec.decode("This is ^^a ^n^'test^'") == "This is ^a \n\"test\"")

        // Test quoted string (should remove quotes)
        #expect(try codec.decode("\"José\"") == "José")
        #expect(try codec.decode("\"test: 1\"") == "test: 1")

        // Test unquoted string
        #expect(try codec.decode("test") == "test")
    }

    @Test("RFC 6868 Round-trip Encoding")
    func testRoundTripEncoding() throws {
        let codec = ICalParameterCodec()

        let testStrings = [
            "",
            "simple",
            "test with spaces",
            "test^caret",
            "test\nnewline",
            "test\"quote",
            "test: colon",
            "test; semicolon",
            "test, comma",
            "José with ñ",
            "Complex ^test\n with \"quotes\" and: special; chars, okay?",
            "Multiple^^carets^^^here",
            "Line1\nLine2\nLine3",
            "\"Already quoted\"",
            "Mixed ^content\n with \"quotes\"",
        ]

        for testString in testStrings {
            let encoded = try codec.encode(testString)
            let decoded = try codec.decode(encoded)
            #expect(decoded == testString, "Round-trip failed for: '\(testString)' -> '\(encoded)' -> '\(decoded)'")
        }
    }

    @Test("RFC 6868 Error Handling")
    func testErrorHandling() throws {
        let codec = ICalParameterCodec()

        // Test invalid escape sequences
        #expect(throws: ParameterDecodingError.self) {
            try codec.decode("^x")  // Invalid escape sequence
        }

        #expect(throws: ParameterDecodingError.self) {
            try codec.decode("test^")  // Incomplete escape at end
        }

        #expect(throws: ParameterDecodingError.self) {
            try codec.decode("^z invalid")  // Invalid escape character
        }
    }

    @Test("RFC 6868 Edge Cases")
    func testEdgeCases() throws {
        let codec = ICalParameterCodec()

        // Test string that starts and ends with quotes but isn't quoted parameter
        let withQuotes = "\"unquoted\" content"
        let encoded = try codec.encode(withQuotes)
        let decoded = try codec.decode(encoded)
        #expect(decoded == withQuotes)

        // Test string with only special characters
        #expect(try codec.encode("^^\n\"") == "^^^^^n^'")
        #expect(try codec.decode("^^^^^n^'") == "^^\n\"")

        // Test very long string with mixed content
        let longString = String(repeating: "test^content\nwith\"quotes ", count: 100)
        let encodedLong = try codec.encode(longString)
        let decodedLong = try codec.decode(encodedLong)
        #expect(decodedLong == longString)
    }

    @Test("RFC 6868 Individual Character Encoding")
    func testIndividualCharacterEncoding() throws {
        let codec = ICalParameterCodec()

        // Test individual characters
        #expect(try codec.encode("^") == "^^")
        #expect(try codec.encode("^^") == "^^^^")
        #expect(try codec.encode("\n") == "^n")
        #expect(try codec.encode("\"") == "^'")

        // Test the combined string - this should be 5 carets, not 4
        // ^^ -> ^^^^ (4 carets)
        // \n -> ^n (adds 1 more caret + n)
        // " -> ^' (adds 1 more caret + ')
        // Total: ^^^^^n^'
        #expect(try codec.encode("^^\n\"") == "^^^^^n^'")
    }
}
