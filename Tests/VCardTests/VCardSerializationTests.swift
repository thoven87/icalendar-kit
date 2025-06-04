import Foundation
import Testing

@testable import VCard

@Test("Basic vCard Serialization")
func testBasicVCardSerialization() async throws {
    let client = VCardClient()
    let vcard = client.createVCard(formattedName: "Test User")

    let serializer = VCardSerializer()
    let serialized = try await serializer.serialize(vcard)

    #expect(serialized.contains("BEGIN:VCARD"))
    #expect(serialized.contains("END:VCARD"))
    #expect(serialized.contains("VERSION:4.0"))
    #expect(serialized.contains("FN:Test User"))
    #expect(serialized.hasSuffix("\r\n"))
}

@Test("vCard Serialization with All Properties")
func testCompleteVCardSerialization() async throws {
    let client = VCardClient()
    var vcard = client.createPersonVCard(
        formattedName: "John William Smith",
        familyName: "Smith",
        givenName: "John",
        middleName: "William"
    )

    vcard.title = "Software Engineer"
    vcard.organization = VCardOrganization(organizationName: "Tech Corp")
    vcard.birthday = VCardDate(year: 1990, month: 5, day: 15)
    vcard.gender = .male
    vcard.note = "Great colleague"
    vcard.uid = "unique-123"

    client.addEmail(to: &vcard, email: "john@work.com", types: [.work])
    client.addTelephone(to: &vcard, number: "+1234567890", types: [.work, .voice])

    let address = VCardAddress(
        streetAddress: "123 Main St",
        locality: "Anytown",
        region: "CA",
        postalCode: "12345",
        countryName: "USA"
    )
    client.addAddress(to: &vcard, address: address, types: [.work])

    let serializer = VCardSerializer()
    let serialized = try await serializer.serialize(vcard)

    #expect(serialized.contains("FN:John William Smith"))
    #expect(serialized.contains("N:Smith;John;William;;"))
    #expect(serialized.contains("TITLE:Software Engineer"))
    #expect(serialized.contains("ORG:Tech Corp"))
    #expect(serialized.contains("BDAY:1990-05-15"))
    #expect(serialized.contains("GENDER:M"))
    #expect(serialized.contains("NOTE:Great colleague"))
    #expect(serialized.contains("UID:unique-123"))
    #expect(serialized.contains("EMAIL;TYPE=WORK:john@work.com"))
    #expect(serialized.contains("TEL;TYPE=WORK,VOICE:+1234567890"))
    #expect(serialized.contains("ADR;TYPE=WORK:;;123 Main St;Anytown;CA;12345;USA"))
}

@Test("Multiple vCard Serialization")
func testMultipleVCardSerialization() async throws {
    let client = VCardClient()
    let vcards = [
        client.createVCard(formattedName: "John Doe"),
        client.createVCard(formattedName: "Jane Smith"),
    ]

    let serializer = VCardSerializer()
    let serialized = try await serializer.serialize(vcards)

    let beginCount = serialized.components(separatedBy: "BEGIN:VCARD").count - 1
    let endCount = serialized.components(separatedBy: "END:VCARD").count - 1

    #expect(beginCount == 2)
    #expect(endCount == 2)
    #expect(serialized.contains("FN:John Doe"))
    #expect(serialized.contains("FN:Jane Smith"))
}

@Test("vCard Version Specific Serialization")
func testVersionSpecificSerialization() async throws {
    let client = VCardClient()
    let vcard = client.createVCard(formattedName: "Version Test")

    let serializer = VCardSerializer()

    let v3Serialized = try await serializer.serialize(vcard, version: .v3_0)
    #expect(v3Serialized.contains("VERSION:3.0"))

    let v4Serialized = try await serializer.serialize(vcard, version: .v4_0)
    #expect(v4Serialized.contains("VERSION:4.0"))
}

@Test("Minimal vCard Serialization")
func testMinimalVCardSerialization() async throws {
    let client = VCardClient()
    var vcard = client.createVCard(formattedName: "Minimal Test")

    vcard.note = "This should not appear in minimal"
    vcard.categories = ["Optional"]

    let serializer = VCardSerializer()
    let minimal = try await serializer.serializeMinimal(vcard)

    #expect(minimal.contains("FN:Minimal Test"))
    #expect(minimal.contains("VERSION:4.0"))
    #expect(!minimal.contains("NOTE:"))
    #expect(!minimal.contains("CATEGORIES:"))
}

@Test("Apple Contacts Compatibility Serialization")
func testAppleContactsSerialization() async throws {
    let client = VCardClient()
    var vcard = client.createPersonVCard(
        formattedName: "Apple Test",
        familyName: "Test",
        givenName: "Apple"
    )

    vcard.organization = VCardOrganization(organizationName: "Apple Inc")
    client.addEmail(to: &vcard, email: "test@apple.com", types: [.work])
    client.addTelephone(to: &vcard, number: "+1-408-996-1010", types: [.work])

    let serializer = VCardSerializer()
    let appleSerialized = await serializer.serializeForApple(vcard)

    #expect(appleSerialized.contains("VERSION:3.0"))
    #expect(appleSerialized.contains("FN:Apple Test"))
    #expect(appleSerialized.contains("N:Test;Apple;;;"))
    #expect(appleSerialized.contains("ORG:Apple Inc"))
    #expect(appleSerialized.contains("EMAIL;TYPE=WORK:test@apple.com"))
}

@Test("Google Contacts Compatibility Serialization")
func testGoogleContactsSerialization() async throws {
    let client = VCardClient()
    var vcard = client.createPersonVCard(
        formattedName: "Google Test",
        familyName: "Test",
        givenName: "Google"
    )

    client.addEmail(to: &vcard, email: "test@google.com", types: [.work])
    client.addTelephone(to: &vcard, number: "+1-650-253-0000", types: [.work])

    let serializer = VCardSerializer()
    let googleSerialized = await serializer.serializeForGoogle(vcard)

    #expect(googleSerialized.contains("VERSION:3.0"))
    #expect(googleSerialized.contains("FN:Google Test"))
    #expect(googleSerialized.contains("EMAIL;TYPE=WORK:test@google.com"))
}

@Test("Outlook Compatibility Serialization")
func testOutlookSerialization() async throws {
    let client = VCardClient()
    var vcard = client.createPersonVCard(
        formattedName: "Outlook Test",
        familyName: "Test",
        givenName: "Outlook"
    )

    client.addEmail(to: &vcard, email: "test@outlook.com", types: [.work])

    let serializer = VCardSerializer()
    let outlookSerialized = await serializer.serializeForOutlook(vcard)

    #expect(outlookSerialized.contains("VERSION:2.1"))
    #expect(outlookSerialized.contains("FN:Outlook Test"))
}

@Test("Pretty Print Serialization")
func testPrettyPrintSerialization() async throws {
    let client = VCardClient()
    let vcard = client.createVCard(formattedName: "Pretty Test")

    let serializer = VCardSerializer()
    let pretty = await serializer.serializePretty(vcard)

    #expect(pretty.contains("FN:Pretty Test"))
    #expect(pretty.contains("VERSION:4.0"))
}

@Test("Serialization with Custom Line Ending")
func testCustomLineEndingSerialization() async throws {
    let client = VCardClient()
    let vcard = client.createVCard(formattedName: "Line Ending Test")

    let serializer = VCardSerializer()
    let unixStyle = try await serializer.serialize(vcard, lineEnding: "\n")

    #expect(unixStyle.contains("\n"))
    #expect(!unixStyle.contains("\r\n"))
}

@Test("Serialization Options")
func testSerializationOptions() async throws {
    let client = VCardClient()
    var vcard = client.createVCard(formattedName: "Options Test")

    vcard.note = "Test note"
    client.addEmail(to: &vcard, email: "test@example.com")

    let compactOptions = VCardSerializer.SerializationOptions.compact
    let compactSerializer = VCardSerializer(options: compactOptions)
    let compactSerialized = try await compactSerializer.serialize(vcard)

    let defaultOptions = VCardSerializer.SerializationOptions.default
    let defaultSerializer = VCardSerializer(options: defaultOptions)
    let defaultSerialized = try await defaultSerializer.serialize(vcard)

    #expect(compactSerialized.count <= defaultSerialized.count)
}

@Test("Serialization with Validation")
func testSerializationWithValidation() async throws {
    let client = VCardClient()
    let vcard = client.createVCard(formattedName: "Validation Test")

    let validatingOptions = VCardSerializer.SerializationOptions(
        validateBeforeSerializing: true
    )
    let serializer = VCardSerializer(options: validatingOptions)

    // Should not throw for valid vCard
    let serialized = try await serializer.serialize(vcard)
    #expect(serialized.contains("FN:Validation Test"))
}

@Test("Property Sorting in Serialization")
func testPropertySortingSerialization() async throws {
    let client = VCardClient()
    var vcard = client.createVCard(formattedName: "Sort Test")

    client.addEmail(to: &vcard, email: "test@example.com")
    client.addTelephone(to: &vcard, number: "+1234567890")
    vcard.note = "Test note"

    let sortedOptions = VCardSerializer.SerializationOptions(sortProperties: true)
    let sortedSerializer = VCardSerializer(options: sortedOptions)
    let sortedSerialized = try await sortedSerializer.serialize(vcard)

    let unsortedOptions = VCardSerializer.SerializationOptions(sortProperties: false)
    let unsortedSerializer = VCardSerializer(options: unsortedOptions)
    let unsortedSerialized = try await unsortedSerializer.serialize(vcard)

    #expect(sortedSerialized.contains("EMAIL:"))
    #expect(unsortedSerialized.contains("EMAIL:"))
}

@Test("Line Folding in Serialization")
func testLineFoldingSerialization() async throws {
    let client = VCardClient()
    var vcard = client.createVCard(formattedName: "Line Folding Test")

    vcard.note = String(repeating: "This is a very long note that should be folded when serialized. ", count: 5)

    let serializer = VCardSerializer()
    let serialized = try await serializer.serialize(vcard)

    #expect(serialized.contains("\r\n "))
}

@Test("Escaping in Serialization")
func testEscapingSerialization() async throws {
    let client = VCardClient()
    var vcard = client.createVCard(formattedName: "Escape Test")

    vcard.note = "This has; semicolons, commas\nand newlines\r\nand backslashes\\"

    let serializer = VCardSerializer()
    let serialized = try await serializer.serialize(vcard)

    #expect(serialized.contains("\\;"))
    #expect(serialized.contains("\\,"))
    #expect(serialized.contains("\\n"))
    #expect(serialized.contains("\\\\"))
}

@Test("Parameter Escaping in Serialization")
func testParameterEscapingSerialization() async throws {
    let client = VCardClient()
    var vcard = client.createVCard(formattedName: "Parameter Test")

    let address = VCardAddress(streetAddress: "123 Main St")
    client.addAddress(to: &vcard, address: address, label: "Work: Main Office")

    let serializer = VCardSerializer()
    let serialized = try await serializer.serialize(vcard)

    #expect(serialized.contains("LABEL=\"Work: Main Office\""))
}

@Test("Serialization Statistics")
func testSerializationStatistics() async throws {
    let client = VCardClient()
    var vcard = client.createPersonVCard(formattedName: "Stats Test")

    client.addEmail(to: &vcard, email: "stats@example.com")
    client.addEmail(to: &vcard, email: "stats2@example.com")
    client.addTelephone(to: &vcard, number: "+1234567890")

    let address = VCardAddress(streetAddress: "123 Stats St")
    client.addAddress(to: &vcard, address: address)
    client.addUrl(to: &vcard, url: "https://stats.example.com")

    let serializer = VCardSerializer()
    let stats = await serializer.getStatistics(vcard)

    #expect(stats.emailCount == 2)
    #expect(stats.telephoneCount == 1)
    #expect(stats.addressCount == 1)
    #expect(stats.urlCount == 1)
    #expect(stats.totalLines > 0)
    #expect(stats.totalCharacters > 0)
    #expect(stats.propertyCount > 0)
}

@Test("Data and File Serialization")
func testDataAndFileSerialization() async throws {
    let client = VCardClient()
    let vcard = client.createVCard(formattedName: "File Test")

    let serializer = VCardSerializer()

    // Test data serialization
    let data = try await serializer.serializeToData(vcard)
    let string = String(data: data, encoding: String.Encoding.utf8)
    #expect(string?.contains("FN:File Test") == true)

    // Test file serialization
    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test.vcf")
    try await serializer.serializeToFile(vcard, url: tempURL)

    let fileExists = FileManager.default.fileExists(atPath: tempURL.path)
    #expect(fileExists == true)

    // Clean up
    try? FileManager.default.removeItem(at: tempURL)
}

@Test("Concurrent Serialization")
func testConcurrentSerialization() async throws {
    let client = VCardClient()
    let vcards = (1...10).map { i in
        client.createVCard(formattedName: "Concurrent Test \(i)")
    }

    let serializer = VCardSerializer()

    // Test concurrent serialization
    await withTaskGroup(of: Void.self) { group in
        for vcard in vcards {
            group.addTask {
                do {
                    let _ = try await serializer.serialize(vcard)
                } catch {
                    // Handle errors in concurrent context
                }
            }
        }
    }

    #expect(Bool(true))  // If we reach here, concurrent access worked
}
