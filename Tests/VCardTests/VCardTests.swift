import Foundation
import Testing

@testable import VCard

@Test("Basic vCard Creation")
func testBasicVCardCreation() throws {
    let client = VCardClient()
    let vcard = client.createVCard(formattedName: "John Doe")

    #expect(vcard.formattedName == "John Doe")
    #expect(vcard.version == .v4_0)
}

@Test("Person vCard Creation")
func testPersonVCardCreation() throws {
    let client = VCardClient()
    let vcard = client.createPersonVCard(
        formattedName: "John Smith",
        familyName: "Smith",
        givenName: "John",
        middleName: "William",
        prefix: "Mr.",
        suffix: "Jr."
    )

    #expect(vcard.formattedName == "John Smith")
    #expect(vcard.name?.familyNames == ["Smith"])
    #expect(vcard.name?.givenNames == ["John"])
    #expect(vcard.name?.additionalNames == ["William"])
    #expect(vcard.name?.honorificPrefixes == ["Mr."])
    #expect(vcard.name?.honorificSuffixes == ["Jr."])
    #expect(vcard.kind == VCardKind.individual)
}

@Test("Organization vCard Creation")
func testOrganizationVCardCreation() throws {
    let client = VCardClient()
    let vcard = client.createOrganizationVCard(
        organizationName: "Acme Corporation",
        organizationalUnits: ["Engineering", "Software"]
    )

    #expect(vcard.formattedName == "Acme Corporation")
    #expect(vcard.organization?.organizationName == "Acme Corporation")
    #expect(vcard.organization?.organizationalUnits == ["Engineering", "Software"])
    #expect(vcard.kind == VCardKind.org)
}

@Test("Adding Contact Information")
func testAddingContactInformation() throws {
    let client = VCardClient()
    var vcard = client.createVCard(formattedName: "Test Contact")

    client.addEmail(to: &vcard, email: "test@example.com", types: [.work])
    client.addTelephone(to: &vcard, number: "+1234567890", types: [.work, .voice])

    let address = VCardAddress(
        streetAddress: "123 Main St",
        locality: "Anytown",
        region: "CA",
        postalCode: "12345",
        countryName: "USA"
    )
    client.addAddress(to: &vcard, address: address, types: [.work])
    client.addUrl(to: &vcard, url: "https://example.com", type: .work)

    #expect(vcard.emails.count == 1)
    #expect(vcard.emails.first?.value == "test@example.com")
    #expect(vcard.telephones.count == 1)
    #expect(vcard.telephones.first?.value == "+1234567890")
    #expect(vcard.addresses.count == 1)
    #expect(vcard.urls.count == 1)
}

@Test("vCard Serialization")
func testVCardSerialization() throws {
    let client = VCardClient()
    let vcard = client.createVCard(formattedName: "Test User")

    let serialized: String = try client.serializeVCard(vcard)

    #expect(serialized.contains("BEGIN:VCARD"))
    #expect(serialized.contains("END:VCARD"))
    #expect(serialized.contains("VERSION:4.0"))
    #expect(serialized.contains("FN:Test User"))
}

@Test("vCard Parsing")
func testVCardParsing() throws {
    let client = VCardClient()
    let vcardString = """
        BEGIN:VCARD
        VERSION:4.0
        FN:Jane Doe
        N:Doe;Jane;Marie;;
        EMAIL:jane@example.com
        TEL:+1-555-123-4567
        ORG:Example Corp
        TITLE:Software Engineer
        END:VCARD
        """

    let vcard = try client.parseVCard(from: vcardString)

    #expect(vcard.formattedName == "Jane Doe")
    #expect(vcard.name?.familyNames == ["Doe"])
    #expect(vcard.name?.givenNames == ["Jane"])
    #expect(vcard.name?.additionalNames == ["Marie"])
    #expect(vcard.emails.count == 1)
    #expect(vcard.emails.first?.value == "jane@example.com")
    #expect(vcard.telephones.count == 1)
    #expect(vcard.telephones.first?.value == "+1-555-123-4567")
    #expect(vcard.organization?.organizationName == "Example Corp")
    #expect(vcard.title == "Software Engineer")
}

@Test("Name Formatting and Parsing")
func testNameFormattingAndParsing() throws {
    let name = VCardName(
        familyNames: ["Smith", "Jones"],
        givenNames: ["John", "Paul"],
        additionalNames: ["William"],
        honorificPrefixes: ["Dr."],
        honorificSuffixes: ["PhD"]
    )

    let formatted = VCardFormatter.format(name: name)
    let parsed = VCardFormatter.parseName(formatted)

    #expect(parsed?.familyNames == name.familyNames)
    #expect(parsed?.givenNames == name.givenNames)
    #expect(parsed?.additionalNames == name.additionalNames)
    #expect(parsed?.honorificPrefixes == name.honorificPrefixes)
    #expect(parsed?.honorificSuffixes == name.honorificSuffixes)
}

@Test("Address Formatting and Parsing")
func testAddressFormattingAndParsing() throws {
    let address = VCardAddress(
        postOfficeBox: "PO Box 123",
        extendedAddress: "Suite 456",
        streetAddress: "789 Main Street",
        locality: "Anytown",
        region: "California",
        postalCode: "90210",
        countryName: "United States"
    )

    let formatted = VCardFormatter.format(address: address)
    let parsed = VCardFormatter.parseAddress(formatted)

    #expect(parsed?.postOfficeBox == address.postOfficeBox)
    #expect(parsed?.extendedAddress == address.extendedAddress)
    #expect(parsed?.streetAddress == address.streetAddress)
    #expect(parsed?.locality == address.locality)
    #expect(parsed?.region == address.region)
    #expect(parsed?.postalCode == address.postalCode)
    #expect(parsed?.countryName == address.countryName)
}

@Test("Geo Formatting and Parsing")
func testGeoFormattingAndParsing() throws {
    let geo = VCardGeo(latitude: 37.7749, longitude: -122.4194)

    let formatted = VCardFormatter.format(geo: geo)
    let parsed = VCardFormatter.parseGeo(formatted)

    #expect(parsed?.latitude == geo.latitude)
    #expect(parsed?.longitude == geo.longitude)
    #expect(formatted == "geo:37.7749,-122.4194")
}

@Test("Date Formatting and Parsing")
func testDateFormattingAndParsing() throws {
    let date = VCardDate(year: 1990, month: 12, day: 25)

    let formatted = VCardFormatter.format(date: date)
    let parsed = VCardFormatter.parseDate(formatted)

    #expect(parsed?.year == date.year)
    #expect(parsed?.month == date.month)
    #expect(parsed?.day == date.day)
    #expect(formatted == "1990-12-25")
}

@Test("Organization Formatting and Parsing")
func testOrganizationFormattingAndParsing() throws {
    let org = VCardOrganization(
        organizationName: "Acme Corp",
        organizationalUnits: ["Engineering", "Software", "Mobile"]
    )

    let formatted = VCardFormatter.format(organization: org)
    let parsed = VCardFormatter.parseOrganization(formatted)

    #expect(parsed?.organizationName == org.organizationName)
    #expect(parsed?.organizationalUnits == org.organizationalUnits)
}

@Test("Text Escaping and Unescaping")
func testTextEscapingAndUnescaping() throws {
    let text = "Hello; world,\nThis is a test\r\nwith\\backslash"
    let escaped = VCardFormatter.escapeText(text)
    let unescaped = VCardFormatter.unescapeText(escaped)

    #expect(unescaped == text)
    #expect(escaped.contains("\\;"))
    #expect(escaped.contains("\\,"))
    #expect(escaped.contains("\\n"))
    #expect(escaped.contains("\\\\"))
}

@Test("Property Formatting and Parsing")
func testPropertyFormattingAndParsing() throws {
    let property = VProperty(
        name: "EMAIL",
        value: "test@example.com",
        parameters: ["TYPE": "WORK", "PREF": "1"]
    )

    let formatted = VCardFormatter.formatProperty(property)
    let parsed = VCardFormatter.parseProperty(formatted)

    #expect(parsed?.name == property.name)
    #expect(parsed?.value == property.value)
    #expect(parsed?.parameters["TYPE"] == "WORK")
    #expect(parsed?.parameters["PREF"] == "1")
}

@Test("Multiple vCard Parsing")
func testMultipleVCardParsing() throws {
    let client = VCardClient()
    let multipleVCards = """
        BEGIN:VCARD
        VERSION:4.0
        FN:John Doe
        EMAIL:john@example.com
        END:VCARD
        BEGIN:VCARD
        VERSION:4.0
        FN:Jane Smith
        EMAIL:jane@example.com
        END:VCARD
        """

    let vcards = try client.parseVCards(from: multipleVCards)

    #expect(vcards.count == 2)
    #expect(vcards[0].formattedName == "John Doe")
    #expect(vcards[1].formattedName == "Jane Smith")
}

@Test("vCard Builder Pattern")
func testVCardBuilderPattern() throws {
    let vcard = VCardBuilder(formattedName: "Builder Test")
        .name(familyName: "Test", givenName: "Builder")
        .email("builder@example.com", types: [.work])
        .telephone("+1234567890", types: [.work, .voice])
        .organization("Test Corp", units: ["Engineering"])
        .title("Software Engineer")
        .birthday(Date())
        .gender(VCardGender.other)
        .note("Created with builder pattern")
        .build()

    #expect(vcard.formattedName == "Builder Test")
    #expect(vcard.name?.familyNames == ["Test"])
    #expect(vcard.name?.givenNames == ["Builder"])
    #expect(vcard.emails.count == 1)
    #expect(vcard.telephones.count == 1)
    #expect(vcard.organization?.organizationName == "Test Corp")
    #expect(vcard.title == "Software Engineer")
    #expect(vcard.birthday != nil)
    #expect(vcard.gender == VCardGender.other)
    #expect(vcard.note == "Created with builder pattern")
}

@Test("Address Builder Pattern")
func testAddressBuilderPattern() throws {
    let address = VCardAddressBuilder()
        .streetAddress("123 Main St")
        .locality("Anytown")
        .region("CA")
        .postalCode("12345")
        .country("USA")
        .build()

    #expect(address.streetAddress == "123 Main St")
    #expect(address.locality == "Anytown")
    #expect(address.region == "CA")
    #expect(address.postalCode == "12345")
    #expect(address.countryName == "USA")
}

@Test("Contact Templates")
func testContactTemplates() throws {
    let personal = ContactTemplates.personalContact(
        name: "John Doe",
        email: "john@personal.com",
        phone: "+1234567890"
    )

    let business = ContactTemplates.businessContact(
        name: "Jane Smith",
        title: "CEO",
        company: "Acme Corp",
        email: "jane@acme.com",
        phone: "+0987654321"
    )

    let org = ContactTemplates.organizationContact(
        name: "Tech Company",
        website: "https://techcompany.com",
        email: "info@techcompany.com",
        phone: "+1111111111"
    )

    #expect(personal.formattedName == "John Doe")
    #expect(personal.kind == VCardKind.individual)
    #expect(personal.emails.first?.types.contains(.home) == true)

    #expect(business.formattedName == "Jane Smith")
    #expect(business.title == "CEO")
    #expect(business.organization?.organizationName == "Acme Corp")

    #expect(org.formattedName == "Tech Company")
    #expect(org.kind == VCardKind.org)
}

@Test("vCard Validation")
func testVCardValidation() throws {
    let client = VCardClient()
    let validVCard = client.createVCard(formattedName: "Valid Contact")

    // Should not throw for valid vCard
    try client.validateVCard(validVCard)

    // Test validation utilities
    #expect(VCardValidationUtilities.hasMinimumInfo(validVCard) == true)
    #expect(VCardValidationUtilities.hasContactInfo(validVCard) == false)

    var contactWithInfo = validVCard
    client.addEmail(to: &contactWithInfo, email: "test@example.com")
    #expect(VCardValidationUtilities.hasContactInfo(contactWithInfo) == true)
    #expect(VCardValidationUtilities.hasValidEmails(contactWithInfo) == true)
}

@Test("vCard Statistics")
func testVCardStatistics() throws {
    let client = VCardClient()
    var vcard = client.createPersonVCard(formattedName: "Test User")

    client.addEmail(to: &vcard, email: "test1@example.com")
    client.addEmail(to: &vcard, email: "test2@example.com")
    client.addTelephone(to: &vcard, number: "+1234567890")

    let stats = client.getVCardStatistics(vcard)

    #expect(stats.emailCount == 2)
    #expect(stats.telephoneCount == 1)
    #expect(stats.version == .v4_0)
    #expect(stats.propertyTypes.contains("EMAIL"))
    #expect(stats.propertyTypes.contains("TEL"))
}

@Test("Contact Finding")
func testContactFinding() throws {
    let client = VCardClient()
    let vcards = [
        client.createPersonVCard(formattedName: "John Doe"),
        client.createPersonVCard(formattedName: "Jane Smith"),
        client.createPersonVCard(formattedName: "Bob Johnson"),
    ]

    var johnCard = vcards[0]
    client.addEmail(to: &johnCard, email: "john@example.com")
    client.addTelephone(to: &johnCard, number: "+1234567890")

    let foundByName = client.findContacts(in: [johnCard], containing: "John")
    let foundByEmail = client.findContacts(in: [johnCard], withEmail: "john@example.com")
    let foundByPhone = client.findContacts(in: [johnCard], withPhoneNumber: "1234567890")

    #expect(foundByName.count == 1)
    #expect(foundByEmail.count == 1)
    #expect(foundByPhone.count == 1)
}

@Test("Array Extensions")
func testArrayExtensions() throws {
    let client = VCardClient()
    let vcards = [
        client.createPersonVCard(formattedName: "Alice"),
        client.createOrganizationVCard(organizationName: "Acme Corp"),
        client.createGroupVCard(groupName: "Friends"),
    ]

    #expect(vcards.individuals.count == 1)
    #expect(vcards.organizations.count == 1)
    #expect(vcards.groups.count == 1)

    let sorted = vcards.sortedByName
    #expect(sorted.first?.formattedName == "Acme Corp")
}

@Test("String Extensions")
func testStringExtensions() throws {
    #expect("test@example.com".isValidEmail == true)
    #expect("invalid-email".isValidEmail == false)

    #expect("https://example.com".isValidURI == true)
    #expect("not-a-uri".isValidURI == false)

    #expect("+1-555-123-4567".isValidTelephone == true)
    #expect("abc".isValidTelephone == false)

    let escaped = "Hello; world".escapedForVCard
    #expect(escaped.contains("\\;"))

    let unescaped = escaped.unescapedFromVCard
    #expect(unescaped == "Hello; world")
}

@Test("Date Extensions")
func testDateExtensions() throws {
    let date = Date()
    let vCardDate = date.asVCardDate()
    let vCardDateTime = date.asVCardDateTime()

    #expect(vCardDate.date != nil)
    #expect(vCardDateTime.date.date != nil)
}

@Test("Sendable Conformance")
func testSendableConformance() throws {
    // Test that all main types conform to Sendable
    let vcard = VCard(formattedName: "Test")
    let address = VCardAddress(streetAddress: "123 Main St")
    let geo = VCardGeo(latitude: 0.0, longitude: 0.0)
    let organization = VCardOrganization(organizationName: "Test Corp")

    // These should compile without warnings in Swift 6
    Task {
        let _ = vcard
        let _ = address
        let _ = geo
        let _ = organization
    }

    let parser = VCardParser()
    let serializer = VCardSerializer()

    let _ = try parser.parse("BEGIN:VCARD\nVERSION:4.0\nFN:Test\nEND:VCARD")
    let _ = try serializer.serialize(vcard)

    #expect(Bool(true))
}

@Test("Complex vCard with All Properties")
func testComplexVCard() throws {
    let client = VCardClient()
    var vcard = client.createPersonVCard(
        formattedName: "Dr. John William Smith Jr.",
        familyName: "Smith",
        givenName: "John",
        middleName: "William",
        prefix: "Dr.",
        suffix: "Jr."
    )

    vcard.nicknames = ["Johnny", "Jack"]
    vcard.birthday = VCardDate(year: 1980, month: 5, day: 15)
    vcard.anniversary = VCardDate(year: 2010, month: 6, day: 20)
    vcard.gender = .male
    vcard.title = "Senior Software Engineer"
    vcard.role = "Technical Lead"
    vcard.organization = VCardOrganization(
        organizationName: "Tech Corp",
        organizationalUnits: ["Engineering", "Software Development"]
    )

    client.addEmail(to: &vcard, email: "john.smith@work.com", types: [.work])
    client.addEmail(to: &vcard, email: "john@personal.com", types: [.home])
    client.addTelephone(to: &vcard, number: "+1-555-123-4567", types: [.work, .voice])
    client.addTelephone(to: &vcard, number: "+1-555-987-6543", types: [.home, .voice])

    let workAddress = VCardAddress(
        streetAddress: "123 Business Blvd",
        locality: "Tech City",
        region: "CA",
        postalCode: "90210",
        countryName: "USA"
    )
    client.addAddress(to: &vcard, address: workAddress, types: [.work])

    client.addUrl(to: &vcard, url: "https://johnsmith.dev", type: .home)
    client.addInstantMessaging(to: &vcard, address: "john.smith@slack.com", service: "Slack")

    vcard.geo = VCardGeo(latitude: 34.0522, longitude: -118.2437)
    vcard.timeZone = "America/Los_Angeles"
    vcard.languages = [.english, .spanish]
    vcard.categories = ["Colleague", "Developer", "Friend"]
    vcard.note = "Brilliant software engineer and great team player"
    vcard.uid = "john.smith.unique.id.123"

    // Test serialization and parsing
    let serialized: String = try client.serializeVCard(vcard)
    let parsed = try client.parseVCard(from: serialized)

    #expect(parsed.formattedName == vcard.formattedName)
    #expect(parsed.name?.familyNames == vcard.name?.familyNames)
    #expect(parsed.emails.count == vcard.emails.count)
    #expect(parsed.telephones.count == vcard.telephones.count)
    #expect(parsed.organization?.organizationName == vcard.organization?.organizationName)
    #expect(parsed.uid == vcard.uid)
}

@Test("Error Handling")
func testErrorHandling() throws {
    let client = VCardClient()

    // Test invalid vCard format
    let invalidVCard = "INVALID VCARD CONTENT"

    do {
        _ = try client.parseVCard(from: invalidVCard)
        #expect(Bool(false), "Should have thrown an error")
    } catch VCardError.invalidFormat {
        // Expected error
        #expect(Bool(true))
    } catch {
        #expect(Bool(false), "Unexpected error type: \(error)")
    }

    // Test missing required property
    let incompleteVCard = """
        BEGIN:VCARD
        VERSION:4.0
        END:VCARD
        """

    do {
        let vcard = try client.parseVCard(from: incompleteVCard)
        try client.validateVCard(vcard)
        #expect(Bool(false), "Should have thrown validation error")
    } catch VCardError.missingRequiredProperty {
        // Expected error
        #expect(Bool(true))
    } catch {
        #expect(Bool(false), "Unexpected error type: \(error)")
    }
}
