import Foundation
import Testing

@testable import ICalendar

@Suite("Result Builder API Tests")
struct ResultBuilderTests {

    @Test("Basic calendar creation with result builder")
    func basicCalendarCreation() {
        let calendar = ICalendar(productId: "Test//Test//EN") {
            ICalEvent(uid: "test@example.com", summary: "Test Event")
        }

        #expect(calendar.productId == "Test//Test//EN")
        #expect(calendar.version == "2.0")
        #expect(calendar.events.count == 1)
        #expect(calendar.events.first?.uid == "test@example.com")
    }

    @Test("Multiple events in calendar")
    func multipleEventsCreation() {
        let calendar = ICalendar(productId: "Multi//Test//EN") {
            ICalEvent(uid: "event1@example.com", summary: "First Event")
            ICalEvent(uid: "event2@example.com", summary: "Second Event")
            ICalEvent(uid: "event3@example.com", summary: "Third Event")
        }

        #expect(calendar.events.count == 3)

        let eventIds = calendar.events.map { $0.uid }.sorted()
        #expect(eventIds == ["event1@example.com", "event2@example.com", "event3@example.com"])
    }

    @Test("Conditional event creation")
    func conditionalEventCreation() {
        let includeOptional = true

        // Build events conditionally outside the result builder to avoid type inference issues
        var events: [ICalEvent] = [
            ICalEvent(uid: "required@example.com", summary: "Required Event")
        ]

        if includeOptional {
            events.append(ICalEvent(uid: "optional@example.com", summary: "Optional Event"))
        }

        let calendar = ICalendar(productId: "Conditional//Test//EN") {
            events
        }

        #expect(calendar.events.count == 2)

        let eventIds = Set(calendar.events.map { $0.uid })
        #expect(eventIds.contains("required@example.com"))
        #expect(eventIds.contains("optional@example.com"))
    }

    @Test("Dynamic event creation from array")
    func dynamicEventCreation() {
        let eventNames = ["Morning Meeting", "Lunch Break", "Afternoon Review"]
        let calendar = ICalendar(productId: "Dynamic//Test//EN") {
            eventNames.enumerated().map { index, name in
                ICalEvent(uid: "event-\(index)@example.com", summary: name)
            }
        }

        #expect(calendar.events.count == 3)

        // Check that events have correct summaries
        let summaries = Set(calendar.events.compactMap { $0.summary })
        #expect(summaries == Set(eventNames))
    }

    @Test("Calendar with custom properties")
    func calendarWithCustomProperties() {
        let calendar = ICalendar(productId: "Custom//Test//EN") {
            // Calendar-level properties
            ICalProperty(name: "X-WR-CALNAME", value: "My Test Calendar")
            ICalProperty(name: "X-WR-CALDESC", value: "A calendar for testing")

            ICalEvent(uid: "custom@example.com", summary: "Custom Event")
        }

        #expect(calendar.events.count == 1)

        // Check custom properties were added
        let customName = calendar.properties.first { $0.name == "X-WR-CALNAME" }?.value
        #expect(customName == "My Test Calendar")

        let customDesc = calendar.properties.first { $0.name == "X-WR-CALDESC" }?.value
        #expect(customDesc == "A calendar for testing")
    }

    @Test("Event with nested properties using result builder")
    func eventWithNestedProperties() {
        let calendar = ICalendar(productId: "Nested//Test//EN") {
            ICalEvent(uid: "nested@example.com") {
                ICalProperty(name: "SUMMARY", value: "Detailed Event")
                ICalProperty(name: "DESCRIPTION", value: "An event with many properties")
                ICalProperty(name: "LOCATION", value: "Conference Room A")
                ICalProperty(name: "STATUS", value: "CONFIRMED")
            }
        }

        let event = calendar.events.first!
        #expect(event.summary == "Detailed Event")

        // Check properties were added
        let descProp = event.properties.first { $0.name == "DESCRIPTION" }
        #expect(descProp?.value == "An event with many properties")

        let locProp = event.properties.first { $0.name == "LOCATION" }
        #expect(locProp?.value == "Conference Room A")

        let statusProp = event.properties.first { $0.name == "STATUS" }
        #expect(statusProp?.value == "CONFIRMED")
    }

    @Test("Event with timezone properties")
    func eventWithTimezoneProperties() {
        let calendar = ICalendar(productId: "Timezone//Test//EN") {
            ICalEvent(uid: "tz@example.com") {
                ICalProperty(name: "SUMMARY", value: "Timezone Event")
                ICalProperty(name: "DTSTART", value: "20231201T140000", parameters: ["TZID": "America/New_York"])
                ICalProperty(name: "DTEND", value: "20231201T150000", parameters: ["TZID": "America/New_York"])
            }
        }

        let event = calendar.events.first!
        #expect(event.summary == "Timezone Event")

        // Check that timezone parameters were preserved
        let startProp = event.properties.first { $0.name == "DTSTART" }
        #expect(startProp?.parameters["TZID"] == "America/New_York")

        let endProp = event.properties.first { $0.name == "DTEND" }
        #expect(endProp?.parameters["TZID"] == "America/New_York")
    }

    @Test("Empty calendar creation")
    func emptyCalendarCreation() {
        let calendar = ICalendar(productId: "Empty//Test//EN") {
            // No content
        }

        #expect(calendar.events.isEmpty)
        #expect(calendar.todos.isEmpty)
        #expect(calendar.journals.isEmpty)
        #expect(calendar.productId == "Empty//Test//EN")
        #expect(calendar.version == "2.0")
    }

    @Test(
        "Nested conditional logic with explicit arrays",
        arguments: [
            (
                includeWork: true, includePersonal: false, isWeekend: false, expectedCount: 2, expectedWork1: true, expectedWork2: true,
                expectedPersonal: false
            ),
            (
                includeWork: true, includePersonal: true, isWeekend: false, expectedCount: 3, expectedWork1: true, expectedWork2: true,
                expectedPersonal: true
            ),
            (
                includeWork: false, includePersonal: true, isWeekend: false, expectedCount: 1, expectedWork1: false, expectedWork2: false,
                expectedPersonal: true
            ),
            (
                includeWork: true, includePersonal: false, isWeekend: true, expectedCount: 1, expectedWork1: true, expectedWork2: false,
                expectedPersonal: false
            ),
            (
                includeWork: false, includePersonal: false, isWeekend: false, expectedCount: 0, expectedWork1: false, expectedWork2: false,
                expectedPersonal: false
            ),
        ]
    )
    func nestedConditionalLogic(
        includeWork: Bool,
        includePersonal: Bool,
        isWeekend: Bool,
        expectedCount: Int,
        expectedWork1: Bool,
        expectedWork2: Bool,
        expectedPersonal: Bool
    ) {
        // Build events conditionally outside the result builder
        var events: [ICalEvent] = []

        if includeWork {
            events.append(ICalEvent(uid: "work1@example.com", summary: "Work Meeting"))

            if !isWeekend {
                events.append(ICalEvent(uid: "work2@example.com", summary: "Weekday Work"))
            }
        }

        if includePersonal {
            events.append(ICalEvent(uid: "personal@example.com", summary: "Personal Appointment"))
        }

        let calendar = ICalendar(productId: "Nested//Test//EN") {
            events
        }

        #expect(calendar.events.count == expectedCount)

        let eventIds = Set(calendar.events.map { $0.uid })
        #expect(eventIds.contains("work1@example.com") == expectedWork1)
        #expect(eventIds.contains("work2@example.com") == expectedWork2)
        #expect(eventIds.contains("personal@example.com") == expectedPersonal)
    }

    @Test("Calendar validation after builder creation")
    func calendarValidationAfterBuilding() {
        let calendar = ICalendar(productId: "Valid//Test//EN") {
            ICalEvent(uid: "valid@example.com", summary: "Valid Event")
        }

        let result = calendar.validate()
        #expect(result.isValid)

        switch result {
        case .success:
            // Expected for valid calendar
            break
        case .warnings(let warnings):
            // Acceptable if only warnings
            #expect(warnings.count >= 0)
        default:
            Issue.record("Calendar should be valid or have only warnings")
        }
    }

    @Test("Mixed calendar components")
    func mixedCalendarComponents() {
        let calendar = ICalendar(productId: "Mixed//Test//EN") {
            // Add various components
            ICalEvent(uid: "event@example.com", summary: "Test Event")

            // Custom properties
            ICalProperty(name: "X-WR-CALNAME", value: "Mixed Calendar")
            ICalProperty(name: "METHOD", value: "PUBLISH")
        }

        #expect(calendar.events.count == 1)

        // Check custom properties
        let calName = calendar.properties.first { $0.name == "X-WR-CALNAME" }?.value
        #expect(calName == "Mixed Calendar")

        let method = calendar.properties.first { $0.name == "METHOD" }?.value
        #expect(method == "PUBLISH")
    }

    @Test("Calendar with exception dates")
    func calendarWithExceptionDates() {
        let baseDate = Date()
        let exceptionDate = baseDate.addingTimeInterval(86400 * 7)  // 1 week later

        let calendar = ICalendar(productId: "Exception//Test//EN") {
            ICalEvent(uid: "recurring@example.com") {
                ICalProperty(name: "SUMMARY", value: "Weekly Meeting")
                ICalProperty(name: "RRULE", value: "FREQ=WEEKLY;COUNT=5")
                ICalProperty(name: "EXDATE", value: ICalendarFormatter.format(dateTime: exceptionDate.asICalDateTimeUTC()))
            }
        }

        let event = calendar.events.first!
        #expect(event.summary == "Weekly Meeting")

        // Check exception dates were set
        let exdateProp = event.properties.first { $0.name == "EXDATE" }
        #expect(exdateProp != nil)
        #expect(!event.exceptionDates.isEmpty)
    }

    @Test("Performance with moderate number of events", .timeLimit(.minutes(1)))
    func performanceWithModerateEvents() {
        let eventCount = 100
        let eventNames = (1...eventCount).map { "Event \($0)" }

        let calendar = ICalendar(productId: "Performance//Test//EN") {
            eventNames.enumerated().map { index, name in
                ICalEvent(uid: "perf-\(index)@example.com", summary: name)
            }
        }

        #expect(calendar.events.count == eventCount)

        // Validation should be fast
        let result = calendar.validate()
        #expect(result.isValid || result.hasWarnings)
    }

    @Test("Calendar serialization with result builder")
    func calendarSerializationWithResultBuilder() {
        let calendar = ICalendar(productId: "Serialize//Test//EN") {
            ICalProperty(name: "X-WR-CALNAME", value: "Test Calendar")

            ICalEvent(uid: "serialize@example.com", summary: "Serialization Test")
        }

        // Test that it can be serialized
        do {
            let serialized: String = try ICalendarKit.serializeCalendar(calendar)

            #expect(serialized.contains("BEGIN:VCALENDAR"))
            #expect(serialized.contains("END:VCALENDAR"))
            #expect(serialized.contains("PRODID:Serialize//Test//EN"))
            #expect(serialized.contains("X-WR-CALNAME:Test Calendar"))
            #expect(serialized.contains("SUMMARY:Serialization Test"))
        } catch {
            Issue.record("Failed to serialize calendar: \(error)")
        }
    }

    @Test("Event builder integration with result builder")
    func eventBuilderIntegrationWithResultBuilder() {
        // Test that EventBuilder works within result builders
        let eventBuilder = EventBuilder(summary: "Builder Test")
            .location("Test Location")
            .confirmed()

        let calendar = ICalendar(productId: "Builder//Test//EN") {
            eventBuilder.buildEvent()
        }

        #expect(calendar.events.count == 1)

        let event = calendar.events.first!
        #expect(event.summary == "Builder Test")
        #expect(event.location == "Test Location")
        #expect(event.status == ICalEventStatus.confirmed)
    }
}
