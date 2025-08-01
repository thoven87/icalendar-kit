import Foundation
import Testing

@testable import VCard

@Test("VCard Formatter Date Parsing Edge Cases")
func testDateParsingEdgeCases() throws {
    // Test partial dates
    let partialYear = VCardFormatter.parseDate("1990----")
    #expect(partialYear?.year == 1990)
    #expect(partialYear?.month == nil)
    #expect(partialYear?.day == nil)

    let partialYearMonth = VCardFormatter.parseDate("1990-12--")
    #expect(partialYearMonth?.year == 1990)
    #expect(partialYearMonth?.month == 12)
    #expect(partialYearMonth?.day == nil)

    // Test YYYYMMDD format
    let compactDate = VCardFormatter.parseDate("19901225")
    #expect(compactDate?.year == 1990)
    #expect(compactDate?.month == 12)
    #expect(compactDate?.day == 25)

    // Test invalid dates
    let invalidDate = VCardFormatter.parseDate("invalid")
    #expect(invalidDate == nil)

    let invalidFormat = VCardFormatter.parseDate("90-12-25")
    #expect(invalidFormat == nil)
}

@Test("VCard Formatter Geo Parsing Variations")
func testGeoParsingVariations() throws {
    // Test geo: URI format
    let geoURI = VCardFormatter.parseGeo("geo:37.7749,-122.4194")
    #expect(geoURI?.latitude == 37.7749)
    #expect(geoURI?.longitude == -122.4194)

    // Test simple coordinate format
    let simpleCoords = VCardFormatter.parseGeo("37.7749,-122.4194")
    #expect(simpleCoords?.latitude == 37.7749)
    #expect(simpleCoords?.longitude == -122.4194)

    // Test with altitude (should ignore)
    let withAltitude = VCardFormatter.parseGeo("geo:37.7749,-122.4194,100")
    #expect(withAltitude?.latitude == 37.7749)
    #expect(withAltitude?.longitude == -122.4194)

    // Test invalid formats
    let invalidGeo = VCardFormatter.parseGeo("not-geo-data")
    #expect(invalidGeo == nil)

    let invalidCoords = VCardFormatter.parseGeo("geo:invalid,coords")
    #expect(invalidCoords == nil)
}

@Test("VCard Formatter Line Folding")
func testLineFolding() throws {
    let longLine = "DESCRIPTION:" + String(repeating: "A", count: 100)
    let folded = VCardFormatter.foldLine(longLine, maxLength: 75)

    #expect(folded.contains("\r\n "))

    let unfolded = VCardFormatter.unfoldLines(folded)
    #expect(unfolded == longLine)
}

@Test("VCard Formatter Parameter Escaping")
func testParameterEscaping() throws {
    let paramWithSpecialChars = "My Company: Best \"Quotes\" & More"
    let escaped = VCardFormatter.escapeParameterValue(paramWithSpecialChars)
    let unescaped = VCardFormatter.unescapeParameterValue(escaped)

    #expect(unescaped == paramWithSpecialChars)
    #expect(escaped.hasPrefix("\""))
    #expect(escaped.hasSuffix("\""))
}

@Test("VCard Formatter Validation Functions")
func testValidationFunctions() throws {
    // Email validation
    #expect(VCardFormatter.isValidEmail("user@domain.com") == true)
    #expect(VCardFormatter.isValidEmail("user+tag@domain.co.uk") == true)
    #expect(VCardFormatter.isValidEmail("invalid.email") == false)
    #expect(VCardFormatter.isValidEmail("@domain.com") == false)
    #expect(VCardFormatter.isValidEmail("user@") == false)

    // URI validation
    #expect(VCardFormatter.isValidURI("https://example.com") == true)
    #expect(VCardFormatter.isValidURI("http://test.org/path?query=1") == true)
    #expect(VCardFormatter.isValidURI("ftp://files.example.com") == true)
    #expect(VCardFormatter.isValidURI("mailto:test@example.com") == true)
    #expect(VCardFormatter.isValidURI("not-a-uri") == false)
    #expect(VCardFormatter.isValidURI("") == false)

    // Telephone validation
    #expect(VCardFormatter.isValidTelephone("+1-555-123-4567") == true)
    #expect(VCardFormatter.isValidTelephone("(555) 123-4567") == true)
    #expect(VCardFormatter.isValidTelephone("555.123.4567") == true)
    #expect(VCardFormatter.isValidTelephone("5551234567") == true)
    #expect(VCardFormatter.isValidTelephone("abc") == false)
    #expect(VCardFormatter.isValidTelephone("") == false)

    // Language tag validation
    #expect(VCardFormatter.isValidLanguageTag("en") == true)
    #expect(VCardFormatter.isValidLanguageTag("en-US") == true)
    #expect(VCardFormatter.isValidLanguageTag("zh-Hans-CN") == true)
    #expect(VCardFormatter.isValidLanguageTag("invalid-tag-") == false)
    #expect(VCardFormatter.isValidLanguageTag("") == false)

    // Media type validation
    #expect(VCardFormatter.isValidMediaType("text/plain") == true)
    #expect(VCardFormatter.isValidMediaType("image/jpeg") == true)
    #expect(VCardFormatter.isValidMediaType("application/json") == true)
    #expect(VCardFormatter.isValidMediaType("invalid") == false)
    #expect(VCardFormatter.isValidMediaType("text/") == false)
}

@Test("VCard Formatter Structured Value Parsing")
func testStructuredValueParsing() throws {
    let structuredValue = "component1;component2;component3"
    let parsed = VCardFormatter.parseStructuredValue(structuredValue)
    #expect(parsed == ["component1", "component2", "component3"])

    let listValue = "item1,item2, item3 , item4"
    let parsedList = VCardFormatter.parseListValue(listValue)
    #expect(parsedList == ["item1", "item2", "item3", "item4"])

    let components = ["part1", "part2", "part3"]
    let formatted = VCardFormatter.formatStructuredValue(components)
    #expect(formatted == "part1;part2;part3")

    let items = ["one", "two", "three"]
    let formattedList = VCardFormatter.formatListValue(items)
    #expect(formattedList == "one,two,three")
}

@Test("VCard Formatter Base64 Encoding")
func testBase64Encoding() throws {
    let testData = "Hello, World!".data(using: String.Encoding.utf8)!
    let encoded = VCardFormatter.encodeBase64(testData)
    let decoded = VCardFormatter.decodeBase64(encoded)

    #expect(decoded == testData)
    #expect(String(data: decoded!, encoding: String.Encoding.utf8) == "Hello, World!")
}

@Test("VCard Formatter Complex Property Parsing")
func testComplexPropertyParsing() throws {
    let complexProperty = "EMAIL;TYPE=WORK,INTERNET;PREF=1;LABEL=\"Work Email\":john.doe@company.com"
    let parsed = VCardFormatter.parseProperty(complexProperty)

    #expect(parsed?.name == "EMAIL")
    #expect(parsed?.value == "john.doe@company.com")
    #expect(parsed?.parameters["TYPE"] == "WORK,INTERNET")
    #expect(parsed?.parameters["PREF"] == "1")
    #expect(parsed?.parameters["LABEL"] == "Work Email")

    let folded = VCardFormatter.foldLine(complexProperty, maxLength: 30)
    let unfoldedParsed = VCardFormatter.parseProperty(folded)

    #expect(unfoldedParsed?.name == parsed?.name)
    #expect(unfoldedParsed?.value == parsed?.value)
    #expect(unfoldedParsed?.parameters == parsed?.parameters)
}

@Test("VCard Formatter Timestamp Parsing")
func testTimestampParsing() throws {
    let date = Date(timeIntervalSince1970: 1_609_459_200)  // 2021-01-01 00:00:00 UTC
    let formatted = VCardFormatter.format(timestamp: date)
    let parsed = VCardFormatter.parseTimestamp(formatted)

    #expect(abs(parsed!.timeIntervalSince1970 - date.timeIntervalSince1970) < 1.0)

    // Test parsing epoch timestamp
    let epochParsed = VCardFormatter.parseTimestamp("1609459200")
    #expect(epochParsed?.timeIntervalSince1970 == 1_609_459_200)

    // Test invalid timestamp
    let invalid = VCardFormatter.parseTimestamp("not-a-timestamp")
    #expect(invalid == nil)
}

@Test("VCard Formatter Organization Edge Cases")
func testOrganizationEdgeCases() throws {
    // Organization with no units
    let simpleOrg = VCardOrganization(organizationName: "Simple Corp")
    let formatted = VCardFormatter.format(organization: simpleOrg)
    let parsed = VCardFormatter.parseOrganization(formatted)

    #expect(parsed?.organizationName == "Simple Corp")
    #expect(parsed?.organizationalUnits.isEmpty == true)

    // Organization with empty units should be filtered
    let orgWithEmptyUnits = VCardOrganization(
        organizationName: "Main Corp",
        organizationalUnits: ["Unit1", "", "Unit2", ""]
    )
    let formattedWithEmpty = VCardFormatter.format(organization: orgWithEmptyUnits)
    let parsedWithEmpty = VCardFormatter.parseOrganization(formattedWithEmpty)

    #expect(parsedWithEmpty?.organizationName == "Main Corp")
    #expect(parsedWithEmpty?.organizationalUnits == ["Unit1", "Unit2"])
}

@Test("VCard Formatter Address Edge Cases")
func testAddressEdgeCases() throws {
    // Address with all nil components
    let emptyAddress = VCardAddress()
    let formatted = VCardFormatter.format(address: emptyAddress)
    let parsed = VCardFormatter.parseAddress(formatted)

    #expect(formatted == ";;;;;;")
    #expect(parsed?.postOfficeBox == nil)
    #expect(parsed?.streetAddress == nil)

    // Address with some components
    let partialAddress = VCardAddress(
        streetAddress: "123 Main St",
        locality: "Anytown",
        postalCode: "12345"
    )
    let partialFormatted = VCardFormatter.format(address: partialAddress)
    let partialParsed = VCardFormatter.parseAddress(partialFormatted)

    #expect(partialParsed?.streetAddress == "123 Main St")
    #expect(partialParsed?.locality == "Anytown")
    #expect(partialParsed?.postalCode == "12345")
    #expect(partialParsed?.region == nil)
}

@Test("VCard Formatter Name Edge Cases")
func testNameEdgeCases() throws {
    // Name with empty components
    let emptyName = VCardName()
    let formatted = VCardFormatter.format(name: emptyName)
    let parsed = VCardFormatter.parseName(formatted)

    #expect(formatted == ";;;;")
    #expect(parsed?.familyNames.isEmpty == true)
    #expect(parsed?.givenNames.isEmpty == true)

    // Name with spaces in components
    let nameWithSpaces = VCardName(
        familyNames: ["van der Berg"],
        givenNames: ["Mary Jane"],
        honorificPrefixes: ["Dr.", "Prof."]
    )
    let spacedFormatted = VCardFormatter.format(name: nameWithSpaces)
    let spacedParsed = VCardFormatter.parseName(spacedFormatted)

    #expect(spacedParsed?.familyNames == ["van", "der", "Berg"])
    #expect(spacedParsed?.givenNames == ["Mary", "Jane"])
    #expect(spacedParsed?.honorificPrefixes == ["Dr.", "Prof."])
}
