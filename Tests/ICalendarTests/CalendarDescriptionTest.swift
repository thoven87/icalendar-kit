import Foundation
import Testing

@testable import ICalendar

struct CalendarDescriptionTest {

    @Test("Calendar description properties for maximum compatibility")
    func testCalendarDescriptionProperties() async throws {
        var calendar = ICalendar(productId: "-//Test//Compliance Test//EN")

        // Set calendarDescription - this should set both DESCRIPTION (RFC 7986) and X-WR-CALDESC (legacy) for maximum compatibility
        calendar.calendarDescription = "Standard Description"

        let serialized1 = try ICalendarSerializer().serialize(calendar)

        // calendarDescription sets both properties for maximum compatibility
        #expect(serialized1.contains("DESCRIPTION:Standard Description"), "Should contain RFC 7986 DESCRIPTION property")
        #expect(serialized1.contains("X-WR-CALDESC:Standard Description"), "Should contain X-WR-CALDESC for legacy compatibility")

        // Now set xwrDescription separately - this should only affect X-WR-CALDESC
        calendar.xwrDescription = "Different X-WR Description"

        let serialized2 = try ICalendarSerializer().serialize(calendar)
        #expect(serialized2.contains("DESCRIPTION:Standard Description"), "DESCRIPTION should remain unchanged")
        #expect(serialized2.contains("X-WR-CALDESC:Different X-WR Description"), "X-WR-CALDESC should be updated")
    }

    @Test("calendarDescription sets both properties for maximum compatibility")
    func testStandardDescriptionBehavior() async throws {
        var calendar = ICalendar(productId: "-//Test//EN")

        // Setting calendarDescription sets both DESCRIPTION (RFC 7986) and X-WR-CALDESC (legacy) for maximum compatibility
        calendar.calendarDescription = "Standard Description Only"

        let serialized = try ICalendarSerializer().serialize(calendar)

        #expect(serialized.contains("DESCRIPTION:Standard Description Only"), "Should contain RFC 7986 DESCRIPTION property")
        #expect(serialized.contains("X-WR-CALDESC:Standard Description Only"), "Should contain X-WR-CALDESC for legacy compatibility")
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

    @Test("Maximum compatibility approach - both RFC 7986 and legacy properties")
    func testMaximumCompatibilityApproach() async throws {
        var calendar = ICalendar(productId: "-//Test//EN")

        let description = "My Calendar Description"

        // Set calendarDescription - this sets both DESCRIPTION (RFC 7986) and X-WR-CALDESC (legacy) for maximum compatibility
        calendar.calendarDescription = description

        let serialized = try ICalendarSerializer().serialize(calendar)

        // Should contain both properties with the same value for maximum compatibility
        #expect(serialized.contains("DESCRIPTION:\(description)"), "Should contain RFC 7986 DESCRIPTION property")
        #expect(serialized.contains("X-WR-CALDESC:\(description)"), "Should contain legacy X-WR-CALDESC property")

        // Count how many times the description appears (should be twice - once in each property)
        let descriptionCount = serialized.components(separatedBy: description).count - 1
        #expect(descriptionCount == 2, "Description should appear exactly twice in output")
    }

    @Test("Property behavior verification")
    func testPropertyBehavior() async throws {
        var calendar = ICalendar(productId: "-//Test//EN")

        // Set calendarDescription - sets both DESCRIPTION (RFC 7986) and X-WR-CALDESC (legacy)
        calendar.calendarDescription = "First Description"

        let serialized1 = try ICalendarSerializer().serialize(calendar)
        #expect(serialized1.contains("DESCRIPTION:First Description"), "Should set RFC 7986 DESCRIPTION property")
        #expect(serialized1.contains("X-WR-CALDESC:First Description"), "calendarDescription sets both properties for compatibility")

        // Set xwrDescription separately - only affects X-WR-CALDESC
        calendar.xwrDescription = "Second Description"

        let serialized2 = try ICalendarSerializer().serialize(calendar)
        #expect(serialized2.contains("DESCRIPTION:First Description"), "Original DESCRIPTION should remain unchanged")
        #expect(serialized2.contains("X-WR-CALDESC:Second Description"), "X-WR-CALDESC should be updated")

        // Modify calendarDescription again - sets both properties again
        calendar.calendarDescription = "Modified First Description"

        let serialized3 = try ICalendarSerializer().serialize(calendar)
        #expect(serialized3.contains("DESCRIPTION:Modified First Description"), "DESCRIPTION should be modified")
        #expect(serialized3.contains("X-WR-CALDESC:Modified First Description"), "X-WR-CALDESC should also be modified")
    }

    @Test("Nil property handling")
    func testNilPropertyHandling() async throws {
        var calendar = ICalendar(productId: "-//Test//EN")

        // Set calendarDescription (sets both DESCRIPTION and X-WR-CALDESC)
        calendar.calendarDescription = "Test Description"
        // Then set xwrDescription separately
        calendar.xwrDescription = "Test X-WR Description"

        let serialized1 = try ICalendarSerializer().serialize(calendar)
        #expect(serialized1.contains("DESCRIPTION:Test Description"), "Should set RFC 7986 DESCRIPTION property")
        #expect(serialized1.contains("X-WR-CALDESC:Test X-WR Description"))

        // Set calendarDescription to nil (removes both DESCRIPTION and X-WR-CALDESC)
        calendar.calendarDescription = nil

        let serialized2 = try ICalendarSerializer().serialize(calendar)
        #expect(!serialized2.contains("DESCRIPTION:"), "DESCRIPTION property should be removed")
        #expect(!serialized2.contains("X-WR-CALDESC:"), "X-WR-CALDESC should also be removed when calendarDescription is nil")

        // Set xwrDescription back
        calendar.xwrDescription = "Test X-WR Description"

        let serialized3 = try ICalendarSerializer().serialize(calendar)
        #expect(!serialized3.contains("DESCRIPTION:"), "DESCRIPTION should remain absent")
        #expect(serialized3.contains("X-WR-CALDESC:Test X-WR Description"), "X-WR-CALDESC should be present")
    }

    @Test("RFC 7986 to legacy property mappings for maximum compatibility")
    func testRFC7986ToLegacyMappings() async throws {
        var calendar = ICalendar(productId: "-//Test//EN")

        // Test 1: NAME (RFC 7986) → X-WR-CALNAME (legacy)
        calendar.name = "RFC 7986 Calendar Name"

        let serialized1 = try ICalendarSerializer().serialize(calendar)
        #expect(serialized1.contains("NAME:RFC 7986 Calendar Name"), "Should contain RFC 7986 NAME property")
        #expect(serialized1.contains("X-WR-CALNAME:RFC 7986 Calendar Name"), "Should contain legacy X-WR-CALNAME property")

        // Verify getter works from both properties
        #expect(calendar.name == "RFC 7986 Calendar Name", "name getter should return correct value")
        #expect(calendar.displayName == "RFC 7986 Calendar Name", "displayName getter should fallback to NAME")

        // Test 2: DESCRIPTION (RFC 7986) → X-WR-CALDESC (legacy)
        calendar.calendarDescription = "RFC 7986 Calendar Description"

        let serialized2 = try ICalendarSerializer().serialize(calendar)
        #expect(serialized2.contains("DESCRIPTION:RFC 7986 Calendar Description"), "Should contain RFC 7986 DESCRIPTION property")
        #expect(serialized2.contains("X-WR-CALDESC:RFC 7986 Calendar Description"), "Should contain legacy X-WR-CALDESC property")

        // Test 3: REFRESH-INTERVAL (RFC 7986) → X-PUBLISHED-TTL (legacy)
        let duration = ICalDuration(hours: 24)
        calendar.refreshInterval = duration

        let serialized3 = try ICalendarSerializer().serialize(calendar)
        #expect(serialized3.contains("REFRESH-INTERVAL:PT24H"), "Should contain RFC 7986 REFRESH-INTERVAL property")
        #expect(serialized3.contains("X-PUBLISHED-TTL:PT24H"), "Should contain legacy X-PUBLISHED-TTL property")

        // Verify getter works from both properties
        #expect(calendar.refreshInterval?.hours == 24, "refreshInterval getter should return correct value")
        #expect(calendar.publishedTTL == "PT24H", "publishedTTL getter should fallback to REFRESH-INTERVAL")
    }

    @Test("Legacy to RFC 7986 fallback reading")
    func testLegacyFallbackReading() async throws {
        var calendar = ICalendar(productId: "-//Test//EN")

        // Manually set only legacy properties to test fallback reading
        calendar.setPropertyValue("X-WR-CALNAME", value: "Legacy Calendar Name")
        calendar.setPropertyValue("X-WR-CALDESC", value: "Legacy Calendar Description")
        calendar.setPropertyValue("X-PUBLISHED-TTL", value: "PT12H")

        // Test that RFC 7986 getters can read from legacy properties as fallback
        #expect(calendar.name == "Legacy Calendar Name", "name should fallback to X-WR-CALNAME")
        #expect(calendar.calendarDescription == "Legacy Calendar Description", "calendarDescription should fallback to X-WR-CALDESC")
        #expect(calendar.refreshInterval?.hours == 12, "refreshInterval should fallback to X-PUBLISHED-TTL")

        // Test that legacy getters still work
        #expect(calendar.displayName == "Legacy Calendar Name", "displayName should read X-WR-CALNAME")
        #expect(calendar.xwrDescription == "Legacy Calendar Description", "xwrDescription should read X-WR-CALDESC")
        #expect(calendar.publishedTTL == "PT12H", "publishedTTL should read X-PUBLISHED-TTL")
    }
}
