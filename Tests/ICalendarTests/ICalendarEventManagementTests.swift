import Foundation
import Testing

@testable import ICalendar

@Test("Event Update Functionality")
func testEventUpdate() throws {
    let client = ICalendarClient()
    var calendar = client.createCalendar(productId: "-//Test//EN")

    let originalEvent = client.createEvent(
        summary: "Original Meeting",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600),
        location: "Room A",
        description: "Original description"
    )

    calendar.addEvent(originalEvent)
    let eventUID = originalEvent.uid

    // Test updating event summary
    let summaryUpdated = client.updateEventSummary(
        in: &calendar,
        eventUID: eventUID,
        newSummary: "Updated Meeting"
    )

    #expect(summaryUpdated == true)
    let updatedEvent = client.findEvent(in: calendar, withUID: eventUID)
    #expect(updatedEvent?.summary == "Updated Meeting")
    #expect(updatedEvent?.sequence == 1)  // Should increment sequence

    // Test updating location
    let locationUpdated = client.changeEventLocation(
        in: &calendar,
        eventUID: eventUID,
        newLocation: "Room B"
    )

    #expect(locationUpdated == true)
    let locationEvent = client.findEvent(in: calendar, withUID: eventUID)
    #expect(locationEvent?.location == "Room B")
    #expect(locationEvent?.sequence == 2)  // Should increment again

    // Test updating description
    let descriptionUpdated = client.updateEventDescription(
        in: &calendar,
        eventUID: eventUID,
        newDescription: "Updated description"
    )

    #expect(descriptionUpdated == true)
    let descriptionEvent = client.findEvent(in: calendar, withUID: eventUID)
    #expect(descriptionEvent?.description == "Updated description")

    // Test updating non-existent event
    let nonExistentUpdate = client.updateEventSummary(
        in: &calendar,
        eventUID: "non-existent-uid",
        newSummary: "Should Fail"
    )

    #expect(nonExistentUpdate == false)
}

@Test("Event Rescheduling")
func testEventRescheduling() throws {
    let client = ICalendarClient()
    var calendar = client.createCalendar(productId: "-//Test//EN")

    let originalStart = Date()
    let originalEnd = originalStart.addingTimeInterval(3600)  // 1 hour

    let event = client.createEvent(
        summary: "Meeting to Reschedule",
        startDate: originalStart,
        endDate: originalEnd
    )

    calendar.addEvent(event)
    let eventUID = event.uid

    // Test rescheduling with new dates (keeping duration)
    let newStart = originalStart.addingTimeInterval(86400)  // 1 day later
    let rescheduled = client.rescheduleEvent(
        in: &calendar,
        eventUID: eventUID,
        newStartDate: newStart,
        keepDuration: true
    )

    #expect(rescheduled == true)

    let rescheduledEvent = client.findEvent(in: calendar, withUID: eventUID)
    #expect(abs((rescheduledEvent?.dateTimeStart?.date)!.timeIntervalSince(newStart)) < 1.0)

    // Check that duration was preserved (1 hour)
    let expectedEnd = newStart.addingTimeInterval(3600)
    #expect(abs((rescheduledEvent?.dateTimeEnd?.date)!.timeIntervalSince(expectedEnd)) < 1.0)

    // Test rescheduling with explicit end date
    let explicitEnd = newStart.addingTimeInterval(7200)  // 2 hours
    let explicitReschedule = client.rescheduleEvent(
        in: &calendar,
        eventUID: eventUID,
        newStartDate: newStart,
        newEndDate: explicitEnd,
        keepDuration: false
    )

    #expect(explicitReschedule == true)
    let explicitEvent = client.findEvent(in: calendar, withUID: eventUID)
    #expect(abs((explicitEvent?.dateTimeEnd?.date)!.timeIntervalSince(explicitEnd)) < 1.0)
}

@Test("Event Deletion")
func testEventDeletion() throws {
    let client = ICalendarClient()
    var calendar = client.createCalendar(productId: "-//Test//EN")

    let event1 = client.createEvent(
        summary: "Event 1",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )
    let event2 = client.createEvent(
        summary: "Event 2",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )

    calendar.addEvent(event1)
    calendar.addEvent(event2)

    #expect(calendar.events.count == 2)

    // Delete first event
    let deleted = client.deleteEvent(from: &calendar, eventUID: event1.uid)
    #expect(deleted == true)
    #expect(calendar.events.count == 1)
    #expect(calendar.events.first?.uid == event2.uid)

    // Try to delete non-existent event
    let notDeleted = client.deleteEvent(from: &calendar, eventUID: "non-existent")
    #expect(notDeleted == false)
    #expect(calendar.events.count == 1)

    // Test immutable deletion (returns new calendar)
    let newCalendar = client.deleteEvent(from: calendar, eventUID: event2.uid)
    #expect(newCalendar?.events.count == 0)
    #expect(calendar.events.count == 1)  // Original unchanged
}

@Test("Alarm Checking Functionality")
func testAlarmChecking() throws {
    let client = ICalendarClient()

    let eventWithoutAlarms = client.createEvent(
        summary: "No Alarms",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )

    let eventWithDisplayAlarm = client.createEvent(
        summary: "With Display Alarm",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )
    var mutableDisplayEvent = eventWithDisplayAlarm
    let displayAlarm = client.createDisplayAlarm(description: "Reminder", triggerMinutesBefore: 15)
    mutableDisplayEvent.addAlarm(displayAlarm)

    let eventWithMultipleAlarms = client.createEvent(
        summary: "Multiple Alarms",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )
    var mutableMultipleEvent = eventWithMultipleAlarms
    let audioAlarm = client.createAudioAlarm(triggerMinutesBefore: 5)
    let emailAlarm = client.createEmailAlarm(
        summary: "Email Alert",
        description: "Meeting reminder",
        attendees: [client.createAttendee(email: "test@example.com")],
        triggerMinutesBefore: 30
    )
    mutableMultipleEvent.addAlarm(displayAlarm)
    mutableMultipleEvent.addAlarm(audioAlarm)
    mutableMultipleEvent.addAlarm(emailAlarm)

    // Test hasAlarms method
    #expect(client.hasAlarms(eventWithoutAlarms) == false)
    #expect(client.hasAlarms(mutableDisplayEvent) == true)
    #expect(client.hasAlarms(mutableMultipleEvent) == true)

    // Test hasAlarms with specific type
    #expect(client.hasAlarms(mutableDisplayEvent, ofType: .display) == true)
    #expect(client.hasAlarms(mutableDisplayEvent, ofType: .audio) == false)
    #expect(client.hasAlarms(mutableMultipleEvent, ofType: .display) == true)
    #expect(client.hasAlarms(mutableMultipleEvent, ofType: .audio) == true)
    #expect(client.hasAlarms(mutableMultipleEvent, ofType: .email) == true)

    // Test getAlarms methods
    #expect(client.getAlarms(for: eventWithoutAlarms).count == 0)
    #expect(client.getAlarms(for: mutableDisplayEvent).count == 1)
    #expect(client.getAlarms(for: mutableMultipleEvent).count == 3)

    #expect(client.getAlarms(for: mutableMultipleEvent, ofType: .display).count == 1)
    #expect(client.getAlarms(for: mutableMultipleEvent, ofType: .audio).count == 1)
    #expect(client.getAlarms(for: mutableMultipleEvent, ofType: .email).count == 1)
}

@Test("Alarm Management")
func testAlarmManagement() throws {
    let client = ICalendarClient()
    var event = client.createEvent(
        summary: "Alarm Test",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )

    // Initially no alarms
    #expect(client.hasAlarms(event) == false)

    // Add alarms
    let displayAlarm = client.createDisplayAlarm(description: "Display", triggerMinutesBefore: 15)
    let audioAlarm = client.createAudioAlarm(triggerMinutesBefore: 5)

    client.addAlarm(to: &event, alarm: displayAlarm)
    client.addAlarm(to: &event, alarm: audioAlarm)

    #expect(client.hasAlarms(event) == true)
    #expect(client.getAlarms(for: event).count == 2)

    // Remove specific alarm type
    client.removeAlarms(from: &event, ofType: .audio)
    #expect(client.getAlarms(for: event).count == 1)
    #expect(client.hasAlarms(event, ofType: .display) == true)
    #expect(client.hasAlarms(event, ofType: .audio) == false)

    // Remove all alarms
    client.removeAllAlarms(from: &event)
    #expect(client.hasAlarms(event) == false)
    #expect(client.getAlarms(for: event).count == 0)
}

@Test("Finding Events with Alarms")
func testFindingEventsWithAlarms() throws {
    let client = ICalendarClient()
    var calendar = client.createCalendar(productId: "-//Test//EN")

    // Create events with different alarm configurations
    let noAlarmEvent = client.createEvent(
        summary: "No Alarms",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )

    var displayAlarmEvent = client.createEvent(
        summary: "Display Alarm",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )
    displayAlarmEvent.addAlarm(
        client.createDisplayAlarm(description: "Display", triggerMinutesBefore: 15)
    )

    var audioAlarmEvent = client.createEvent(
        summary: "Audio Alarm",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )
    audioAlarmEvent.addAlarm(client.createAudioAlarm(triggerMinutesBefore: 5))

    var multipleAlarmEvent = client.createEvent(
        summary: "Multiple Alarms",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )
    multipleAlarmEvent.addAlarm(
        client.createDisplayAlarm(description: "Display", triggerMinutesBefore: 15)
    )
    multipleAlarmEvent.addAlarm(client.createAudioAlarm(triggerMinutesBefore: 5))

    calendar.addEvent(noAlarmEvent)
    calendar.addEvent(displayAlarmEvent)
    calendar.addEvent(audioAlarmEvent)
    calendar.addEvent(multipleAlarmEvent)

    // Test finding events with any alarms
    let eventsWithAlarms = client.findEventsWithAlarms(in: calendar)
    #expect(eventsWithAlarms.count == 3)

    // Test finding events with specific alarm types
    let eventsWithDisplayAlarms = client.findEventsWithAlarms(in: calendar, ofType: .display)
    #expect(eventsWithDisplayAlarms.count == 2)

    let eventsWithAudioAlarms = client.findEventsWithAlarms(in: calendar, ofType: .audio)
    #expect(eventsWithAudioAlarms.count == 2)

    let eventsWithEmailAlarms = client.findEventsWithAlarms(in: calendar, ofType: .email)
    #expect(eventsWithEmailAlarms.count == 0)
}

@Test("Event Search Functionality")
func testEventSearch() throws {
    let client = ICalendarClient()
    var calendar = client.createCalendar(productId: "-//Test//EN")

    let event1 = client.createEvent(
        summary: "Team Meeting",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )
    let event2 = client.createEvent(
        summary: "Project Review",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )
    let event3 = client.createEvent(
        summary: "Team Standup",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )

    calendar.addEvent(event1)
    calendar.addEvent(event2)
    calendar.addEvent(event3)

    // Test finding by UID
    let foundEvent = client.findEvent(in: calendar, withUID: event1.uid)
    #expect(foundEvent?.summary == "Team Meeting")

    // Test finding by summary (case insensitive)
    let teamEvents = client.findEvents(in: calendar, withSummary: "team", caseSensitive: false)
    #expect(teamEvents.count == 2)

    let teamEventsCaseSensitive = client.findEvents(
        in: calendar,
        withSummary: "Team",
        caseSensitive: true
    )
    #expect(teamEventsCaseSensitive.count == 2)

    let projectEvents = client.findEvents(in: calendar, withSummary: "Project")
    #expect(projectEvents.count == 1)
    #expect(projectEvents.first?.summary == "Project Review")

    // Test finding non-existent event
    let nonExistent = client.findEvent(in: calendar, withUID: "non-existent")
    #expect(nonExistent == nil)
}

@Test("Attendee Management")
func testAttendeeManagement() throws {
    let client = ICalendarClient()
    var calendar = client.createCalendar(productId: "-//Test//EN")

    let organizer = client.createOrganizer(email: "organizer@test.com", name: "Organizer")
    let attendee1 = client.createAttendee(email: "attendee1@test.com", name: "Attendee 1")
    let attendee2 = client.createAttendee(email: "attendee2@test.com", name: "Attendee 2")

    var event = client.createEvent(
        summary: "Team Meeting",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )
    event.organizer = organizer
    event.attendees = [attendee1]

    calendar.addEvent(event)
    let eventUID = event.uid

    // Test adding attendee
    let attendeeAdded = client.addAttendee(to: &calendar, eventUID: eventUID, attendee: attendee2)
    #expect(attendeeAdded == true)

    let updatedEvent = client.findEvent(in: calendar, withUID: eventUID)
    #expect(updatedEvent?.attendees.count == 2)

    // Test removing attendee
    let attendeeRemoved = client.removeAttendee(
        from: &calendar,
        eventUID: eventUID,
        attendeeEmail: "attendee1@test.com"
    )
    #expect(attendeeRemoved == true)

    let finalEvent = client.findEvent(in: calendar, withUID: eventUID)
    #expect(finalEvent?.attendees.count == 1)
    #expect(finalEvent?.attendees.first?.email == "attendee2@test.com")

    // Test updating all attendees
    let newAttendee = client.createAttendee(email: "new@test.com", name: "New Attendee")
    let attendeesUpdated = client.updateEventAttendees(
        in: &calendar,
        eventUID: eventUID,
        attendees: [newAttendee]
    )
    #expect(attendeesUpdated == true)

    let newEvent = client.findEvent(in: calendar, withUID: eventUID)
    #expect(newEvent?.attendees.count == 1)
    #expect(newEvent?.attendees.first?.email == "new@test.com")
}

@Test("Event Status Management")
func testEventStatusManagement() throws {
    let client = ICalendarClient()
    var calendar = client.createCalendar(productId: "-//Test//EN")

    var event = client.createEvent(
        summary: "Status Test",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )
    event.status = .tentative

    calendar.addEvent(event)
    let eventUID = event.uid

    // Test changing status to confirmed
    let statusChanged = client.changeEventStatus(
        in: &calendar,
        eventUID: eventUID,
        newStatus: .confirmed
    )
    #expect(statusChanged == true)

    let confirmedEvent = client.findEvent(in: calendar, withUID: eventUID)
    #expect(confirmedEvent?.status == .confirmed)

    // Test changing to cancelled
    let cancelledStatus = client.changeEventStatus(
        in: &calendar,
        eventUID: eventUID,
        newStatus: .cancelled
    )
    #expect(cancelledStatus == true)

    let cancelledEvent = client.findEvent(in: calendar, withUID: eventUID)
    #expect(cancelledEvent?.status == .cancelled)
}

@Test("ICalEvent Extensions")
func testICalEventExtensions() throws {
    let client = ICalendarClient()

    // Test alarm extensions
    var event = client.createEvent(
        summary: "Extension Test",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )

    #expect(event.hasAlarms == false)

    event.addReminder(minutesBefore: 15)
    #expect(event.hasAlarms == true)
    #expect(event.hasAlarms(ofType: .display) == true)
    #expect(event.hasAlarms(ofType: .audio) == false)

    let displayAlarms = event.getAlarms(ofType: .display)
    #expect(displayAlarms.count == 1)

    // Test event properties
    #expect(event.isAllDay == false)
    #expect(event.isRecurring == false)
    #expect(event.eventDuration == 3600)  // 1 hour

    // Test all-day event
    let allDayEvent = client.createAllDayEvent(
        summary: "All Day Event",
        date: Date()
    )
    #expect(allDayEvent.isAllDay == true)

    // Test recurring event
    let recurringEvent = client.createRecurringEvent(
        summary: "Recurring Event",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600),
        recurrenceRule: client.createDailyRecurrence(count: 5)
    )
    #expect(recurringEvent.isRecurring == true)
}

@Test("ICalendar Extensions")
func testICalendarExtensions() throws {
    let client = ICalendarClient()
    var calendar = client.createCalendar(productId: "-//Test//EN")

    // Create various types of events
    let todayEvent = client.createEvent(
        summary: "Today",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )

    let allDayEvent = client.createAllDayEvent(summary: "All Day", date: Date())

    let recurringEvent = client.createRecurringEvent(
        summary: "Recurring",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600),
        recurrenceRule: client.createDailyRecurrence(count: 5)
    )

    var alarmEvent = client.createEvent(
        summary: "With Alarm",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )
    alarmEvent.addReminder(minutesBefore: 15)

    var confirmedEvent = client.createEvent(
        summary: "Confirmed",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )
    confirmedEvent.status = .confirmed

    var tentativeEvent = client.createEvent(
        summary: "Tentative",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600)
    )
    tentativeEvent.status = .tentative

    calendar.addEvent(todayEvent)
    calendar.addEvent(allDayEvent)
    calendar.addEvent(recurringEvent)
    calendar.addEvent(alarmEvent)
    calendar.addEvent(confirmedEvent)
    calendar.addEvent(tentativeEvent)

    // Test extension properties
    #expect(calendar.allDayEvents.count == 1)
    #expect(calendar.recurringEvents.count == 1)
    #expect(calendar.eventsWithAlarms.count == 1)
    #expect(calendar.confirmedEvents.count == 1)
    #expect(calendar.tentativeEvents.count == 1)

    // Test events on specific date
    let todaysEvents = calendar.events(on: Date())
    #expect(todaysEvents.count == 6)  // All events are today

    // Test extended statistics
    let stats = calendar.extendedStatistics
    #expect(stats.events == 6)
    #expect(stats.withAlarms == 1)
    #expect(stats.recurring == 1)
    #expect(stats.allDay == 1)
    #expect(stats.confirmed == 1)
}

@Test("Upcoming Alarms")
func testUpcomingAlarms() throws {
    let client = ICalendarClient()
    var calendar = client.createCalendar(productId: "-//Test//EN")

    let futureDate = Date().addingTimeInterval(3600)  // 1 hour from now

    var event = client.createEvent(
        summary: "Future Event",
        startDate: futureDate,
        endDate: futureDate.addingTimeInterval(3600)
    )

    // Add alarm 15 minutes before event
    event.addReminder(minutesBefore: 15)
    calendar.addEvent(event)

    // Look for alarms in the next 2 hours
    let upcomingAlarms = client.findEventsWithUpcomingAlarms(
        in: calendar,
        within: 7200,  // 2 hours
        from: Date()
    )

    #expect(upcomingAlarms.count == 1)
    #expect(upcomingAlarms.first?.event.summary == "Future Event")

    // Look for alarms in the next 30 minutes (should find none)
    let nearAlarms = client.findEventsWithUpcomingAlarms(
        in: calendar,
        within: 1800,  // 30 minutes
        from: Date()
    )

    #expect(nearAlarms.count == 0)
}

@Test("Event Happening Now")
func testEventHappeningNow() throws {
    let client = ICalendarClient()

    let now = Date()
    let oneHourAgo = now.addingTimeInterval(-3600)
    let oneHourFromNow = now.addingTimeInterval(3600)

    // Event happening now
    let currentEvent = client.createEvent(
        summary: "Current Event",
        startDate: oneHourAgo,
        endDate: oneHourFromNow
    )

    // Past event
    let pastEvent = client.createEvent(
        summary: "Past Event",
        startDate: oneHourAgo.addingTimeInterval(-3600),
        endDate: oneHourAgo
    )

    // Future event
    let futureEvent = client.createEvent(
        summary: "Future Event",
        startDate: oneHourFromNow,
        endDate: oneHourFromNow.addingTimeInterval(3600)
    )

    // All-day event for today
    let allDayEvent = client.createAllDayEvent(
        summary: "All Day Today",
        date: now
    )

    #expect(currentEvent.isHappeningNow(at: now) == true)
    #expect(pastEvent.isHappeningNow(at: now) == false)
    #expect(futureEvent.isHappeningNow(at: now) == false)
    #expect(allDayEvent.isHappeningNow(at: now) == true)

    // Test specific time checks
    #expect(currentEvent.isHappeningNow(at: oneHourAgo.addingTimeInterval(1800)) == true)  // 30 min after start
    #expect(currentEvent.isHappeningNow(at: oneHourFromNow.addingTimeInterval(-1800)) == true)  // 30 min before end
    #expect(currentEvent.isHappeningNow(at: oneHourFromNow.addingTimeInterval(1800)) == false)  // 30 min after end
}
