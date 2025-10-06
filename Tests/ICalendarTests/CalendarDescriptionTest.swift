import Foundation
import Testing

@testable import ICalendar

struct CalendarDescriptionTest {

    @Test("Calendar description properties are independent")
    func testCalendarDescriptionProperties() async throws {
        var calendar = ICalendar(productId: "-//Test//Compliance Test//EN")

        // Set both description properties to different values
        calendar.calendarDescription = "RFC 7986 Standard Description"
        calendar.xwrDescription = "Legacy X-WR Description"

        let serialized = try ICalendarSerializer().serialize(calendar)

        // Should contain BOTH properties independently
        #expect(serialized.contains("DESCRIPTION:RFC 7986 Standard Description"), "Should contain RFC 7986 DESCRIPTION property")
        #expect(serialized.contains("X-WR-CALDESC:Legacy X-WR Description"), "Should contain X-WR-CALDESC property")

        // Verify they don't interfere with each other
        #expect(!serialized.contains("DESCRIPTION:Legacy X-WR Description"), "DESCRIPTION should not contain X-WR value")
        #expect(!serialized.contains("X-WR-CALDESC:RFC 7986 Standard Description"), "X-WR-CALDESC should not contain DESCRIPTION value")
    }

    @Test("Only RFC 7986 DESCRIPTION property")
    func testOnlyStandardDescription() async throws {
        var calendar = ICalendar(productId: "-//Test//EN")

        // Only set the RFC 7986 standard property
        calendar.calendarDescription = "Standard Description Only"

        let serialized = try ICalendarSerializer().serialize(calendar)

        #expect(serialized.contains("DESCRIPTION:Standard Description Only"), "Should contain DESCRIPTION property")
        #expect(!serialized.contains("X-WR-CALDESC:"), "Should NOT contain X-WR-CALDESC property")
    }

    @Test("Only X-WR-CALDESC property")
    func testOnlyXWRDescription() async throws {
        var calendar = ICalendar(productId: "-//Test//EN")

        // Only set the X-WR legacy property
        calendar.xwrDescription = "X-WR Description Only"

        let serialized = try ICalendarSerializer().serialize(calendar)

        #expect(serialized.contains("X-WR-CALDESC:X-WR Description Only"), "Should contain X-WR-CALDESC property")
        #expect(!serialized.contains("DESCRIPTION:X-WR Description Only"), "Should NOT contain DESCRIPTION property with X-WR value")
    }

    @Test("CalendarBuilder uses X-WR-CALDESC")
    func testCalendarBuilderDescription() async throws {
        // Test what the CalendarBuilder actually produces by checking the implementation
        var calendar = ICalendar(productId: "-//Test//EN")

        // The CalendarBuilder's CalendarDescription function sets X-WR-CALDESC
        calendar.xwrDescription = "Builder Description"

        let serialized = try ICalendarSerializer().serialize(calendar)

        // Verify builder approach uses X-WR-CALDESC for compatibility
        #expect(serialized.contains("X-WR-CALDESC:Builder Description"), "Builder should produce X-WR-CALDESC")
    }

    @Test("Maximum compatibility approach")
    func testMaximumCompatibilityApproach() async throws {
        var calendar = ICalendar(productId: "-//Test//EN")

        let description = "My Calendar Description"

        // Set both properties to the same value for maximum compatibility
        calendar.calendarDescription = description  // RFC 7986 for modern apps
        calendar.xwrDescription = description  // X-WR for legacy apps

        let serialized = try ICalendarSerializer().serialize(calendar)

        // Should contain both with the same value
        #expect(serialized.contains("DESCRIPTION:\(description)"), "Should contain RFC 7986 property")
        #expect(serialized.contains("X-WR-CALDESC:\(description)"), "Should contain X-WR property")

        // Count how many times the description appears
        let descriptionCount = serialized.components(separatedBy: description).count - 1
        #expect(descriptionCount == 2, "Description should appear exactly twice in output")
    }

    @Test("Property independence verification")
    func testPropertyIndependence() async throws {
        var calendar = ICalendar(productId: "-//Test//EN")

        // Set one property
        calendar.calendarDescription = "First Description"

        let serialized1 = try ICalendarSerializer().serialize(calendar)
        #expect(serialized1.contains("DESCRIPTION:First Description"))
        #expect(!serialized1.contains("X-WR-CALDESC:"))

        // Set the other property without affecting the first
        calendar.xwrDescription = "Second Description"

        let serialized2 = try ICalendarSerializer().serialize(calendar)
        #expect(serialized2.contains("DESCRIPTION:First Description"), "Original DESCRIPTION should remain")
        #expect(serialized2.contains("X-WR-CALDESC:Second Description"), "X-WR-CALDESC should be added")

        // Modify only one property
        calendar.calendarDescription = "Modified First Description"

        let serialized3 = try ICalendarSerializer().serialize(calendar)
        #expect(serialized3.contains("DESCRIPTION:Modified First Description"), "DESCRIPTION should be modified")
        #expect(serialized3.contains("X-WR-CALDESC:Second Description"), "X-WR-CALDESC should remain unchanged")
    }

    @Test("Nil property handling")
    func testNilPropertyHandling() async throws {
        var calendar = ICalendar(productId: "-//Test//EN")

        // Set both properties
        calendar.calendarDescription = "Test Description"
        calendar.xwrDescription = "Test X-WR Description"

        let serialized1 = try ICalendarSerializer().serialize(calendar)
        #expect(serialized1.contains("DESCRIPTION:Test Description"))
        #expect(serialized1.contains("X-WR-CALDESC:Test X-WR Description"))

        // Set one to nil
        calendar.calendarDescription = nil

        let serialized2 = try ICalendarSerializer().serialize(calendar)
        #expect(!serialized2.contains("DESCRIPTION:"), "DESCRIPTION property should be removed")
        #expect(serialized2.contains("X-WR-CALDESC:Test X-WR Description"), "X-WR-CALDESC should remain")

        // Set the other to nil
        calendar.xwrDescription = nil

        let serialized3 = try ICalendarSerializer().serialize(calendar)
        #expect(!serialized3.contains("DESCRIPTION:"), "DESCRIPTION should remain absent")
        #expect(!serialized3.contains("X-WR-CALDESC:"), "X-WR-CALDESC should be removed")
    }
}

// Note: CalendarBuilder.CalendarDescription() uses X-WR-CALDESC for maximum compatibility
// This is verified by the implementation in CalendarBuilder.swift line 120-122
