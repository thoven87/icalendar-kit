import Foundation

// MARK: - Calendar Context

/// Centralized context that knows which calendar system and timezone to use.
///
/// The `ICalendarContext` eliminates repeated calendar detection logic throughout the library
/// by providing a single source of truth for calendar system awareness. It automatically
/// detects the appropriate calendar system from calendar properties (CALSCALE) or event
/// recurrence rules (RSCALE) and provides consistent date calculations.
///
/// ## Example Usage
///
/// ```swift
/// // Create Hebrew calendar context
/// let hebrewContext = ICalendarContext.hebrew
///
/// // Auto-detect from calendar properties
/// let calendar = client.createHebrewCalendar()
/// let context = ICalendarContext(from: calendar)  // Detects Hebrew system
///
/// // Use context for date calculations
/// let startOfDay = context.startOfDay(for: Date())
/// ```
///
/// ## Supported Calendar Systems
///
/// - Gregorian (default)
/// - Hebrew
/// - Islamic
/// - Chinese
/// - Buddhist
/// - Japanese
/// - Persian
/// - Indian
/// - Coptic
/// - Ethiopic
///
/// - Important: The context automatically handles timezone conversions and ensures
///   that date calculations use the correct calendar system for each event or calendar.
///
/// - Note: For date-only events (birthdays, holidays), timezone is set to `nil` to
///   indicate timezone-neutral dates.
public struct ICalendarContext: Sendable {
    /// The calendar system to use for date calculations
    public let calendar: Calendar

    /// Default timezone for operations
    public let defaultTimeZone: TimeZone

    /// Calendar scale (GREGORIAN, HEBREW, ISLAMIC, etc.)
    public let calendarScale: ICalRecurrenceScale

    /// Whether to log calendar system assumptions
    public let logAssumptions: Bool

    /// Creates a new calendar context with specified settings.
    ///
    /// - Parameters:
    ///   - calendarScale: The calendar system to use (default: Gregorian)
    ///   - defaultTimeZone: The default timezone for operations (default: GMT)
    ///   - logAssumptions: Whether to log calendar system assumptions (default: false)
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Create Hebrew calendar context with EST timezone
    /// let context = ICalendarContext(
    ///     calendarScale: .hebrew,
    ///     defaultTimeZone: TimeZone(identifier: "America/New_York")!,
    ///     logAssumptions: true
    /// )
    /// ```
    public init(
        calendarScale: ICalRecurrenceScale = .gregorian,
        defaultTimeZone: TimeZone = .gmt,
        logAssumptions: Bool = false
    ) {
        self.calendarScale = calendarScale
        self.calendar = Calendar(identifier: calendarScale.foundationIdentifier)
        self.defaultTimeZone = defaultTimeZone
        self.logAssumptions = logAssumptions
    }

    /// Creates context by auto-detecting calendar system from calendar properties.
    ///
    /// This initializer examines the calendar's CALSCALE property and X-WR-TIMEZONE
    /// to automatically determine the appropriate calendar system and timezone.
    ///
    /// - Parameter calendar: The calendar to analyze for context detection
    ///
    /// ## Auto-Detection Logic
    ///
    /// 1. **Calendar Scale**: Reads CALSCALE property (e.g., "HEBREW", "ISLAMIC")
    /// 2. **Timezone**: Reads X-WR-TIMEZONE property or defaults to GMT
    /// 3. **Logging**: Enables assumption logging for debugging
    ///
    /// ```swift
    /// let hebrewCalendar = client.createHebrewCalendar()
    /// let context = ICalendarContext(from: hebrewCalendar)  // Auto-detects Hebrew
    /// print(context.calendarScale)  // .hebrew
    /// ```
    public init(from calendar: ICalendar) {
        let scale =
            calendar.calendarScale
            .flatMap(ICalRecurrenceScale.init) ?? .gregorian
        let timezone =
            calendar.xwrTimeZone
            .flatMap { TimeZone(identifier: $0) } ?? .gmt

        self.init(
            calendarScale: scale,
            defaultTimeZone: timezone,
            logAssumptions: true
        )
    }

    /// Creates context by detecting calendar system from event's recurrence rule.
    ///
    /// This initializer examines the event's recurrence rule for RSCALE parameter
    /// to determine which calendar system should be used for date calculations.
    ///
    /// - Parameters:
    ///   - event: The event to analyze for calendar system detection
    ///   - fallback: Context to use if no RSCALE is found (default: Gregorian)
    ///
    /// ## Detection Logic
    ///
    /// - If event has recurrence rule with RSCALE → Use that calendar system
    /// - If no RSCALE found → Use fallback context
    /// - Preserves timezone and logging settings from fallback
    ///
    /// ```swift
    /// let event = client.createEvent(summary: "Rosh Hashanah", ...)
    /// event.recurrenceRule = client.createHebrewRecurrence(frequency: .yearly)
    /// let context = ICalendarContext(from: event)  // Auto-detects Hebrew
    /// ```
    public init(from event: ICalEvent, fallback: ICalendarContext = .default) {
        if let rscale = event.recurrenceRule?.rscale {
            self.init(
                calendarScale: rscale,
                defaultTimeZone: fallback.defaultTimeZone,
                logAssumptions: fallback.logAssumptions
            )
        } else {
            self = fallback
        }
    }
}

// MARK: - Predefined Contexts

extension ICalendarContext {
    /// Default Gregorian context with GMT timezone
    public static let `default` = ICalendarContext()

    /// Hebrew calendar context
    public static let hebrew = ICalendarContext(calendarScale: .hebrew)

    /// Islamic calendar context
    public static let islamic = ICalendarContext(calendarScale: .islamic)

    /// Chinese calendar context
    public static let chinese = ICalendarContext(calendarScale: .chinese)

    /// Buddhist calendar context
    public static let buddhist = ICalendarContext(calendarScale: .buddhist)

    /// Japanese calendar context
    public static let japanese = ICalendarContext(calendarScale: .japanese)

    /// Persian calendar context
    public static let persian = ICalendarContext(calendarScale: .persian)

    /// Indian calendar context
    public static let indian = ICalendarContext(calendarScale: .indian)

    /// Coptic calendar context
    public static let coptic = ICalendarContext(calendarScale: .coptic)

    /// Ethiopic calendar context
    public static let ethiopic = ICalendarContext(calendarScale: .ethiopic)
}

// MARK: - Context Operations

extension ICalendarContext {
    /// Creates a timezone-aware calendar for date operations.
    ///
    /// Returns a Foundation Calendar configured with this context's calendar system
    /// and the specified timezone (or default timezone if none provided).
    ///
    /// - Parameter timeZone: Optional timezone override (uses defaultTimeZone if nil)
    /// - Returns: Configured Calendar ready for date calculations
    ///
    /// ```swift
    /// let hebrewContext = ICalendarContext.hebrew
    /// let cal = hebrewContext.workingCalendar(timeZone: TimeZone(identifier: "America/New_York"))
    /// let startOfDay = cal.startOfDay(for: Date())  // Uses Hebrew calendar + EST
    /// ```
    public func workingCalendar(timeZone: TimeZone? = nil) -> Calendar {
        var cal = calendar
        cal.timeZone = timeZone ?? defaultTimeZone
        return cal
    }

    /// Checks if a date occurs on a specific day using this calendar system.
    ///
    /// This method uses the context's calendar system (Hebrew, Islamic, etc.) to
    /// determine if two dates fall on the same day, accounting for the calendar's
    /// specific date calculation rules.
    ///
    /// - Parameters:
    ///   - date: The date to check
    ///   - day: The target day to compare against
    ///   - timeZone: Optional timezone (uses defaultTimeZone if nil)
    /// - Returns: True if the dates occur on the same day in this calendar system
    ///
    /// ```swift
    /// let hebrewContext = ICalendarContext.hebrew
    /// let roshHashanah = Date()  // Some Hebrew holiday date
    /// let today = Date()
    /// let isToday = hebrewContext.dateOccursOn(roshHashanah, day: today)
    /// ```
    public func dateOccursOn(_ date: Date, day: Date, timeZone: TimeZone? = nil) -> Bool {
        let cal = workingCalendar(timeZone: timeZone)
        return cal.isDate(date, inSameDayAs: day)
    }

    /// Gets the start of day using this calendar system.
    ///
    /// Returns the beginning of the day (typically 00:00:00) for the given date,
    /// calculated according to this context's calendar system and timezone.
    ///
    /// - Parameters:
    ///   - date: The date to get start of day for
    ///   - timeZone: Optional timezone (uses defaultTimeZone if nil)
    /// - Returns: Date representing the start of the day
    ///
    /// - Note: Different calendar systems may have different concepts of when
    ///   a day begins (e.g., Hebrew calendar days begin at sunset).
    public func startOfDay(for date: Date, timeZone: TimeZone? = nil) -> Date {
        let cal = workingCalendar(timeZone: timeZone)
        return cal.startOfDay(for: date)
    }

    /// Gets the end of day using this calendar system.
    ///
    /// Returns the end of the day (typically 23:59:59) for the given date,
    /// calculated according to this context's calendar system and timezone.
    ///
    /// - Parameters:
    ///   - date: The date to get end of day for
    ///   - timeZone: Optional timezone (uses defaultTimeZone if nil)
    /// - Returns: Date representing the end of the day
    ///
    /// - Note: This calculates the end as one second before the start of the next day.
    public func endOfDay(for date: Date, timeZone: TimeZone? = nil) -> Date {
        let cal = workingCalendar(timeZone: timeZone)
        let startOfDay = self.startOfDay(for: date, timeZone: timeZone)
        guard let startOfNext = cal.date(byAdding: .day, value: 1, to: startOfDay) else {
            // Fallback: return start of day + 23:59:59
            return startOfDay.addingTimeInterval(86399)  // 24 hours - 1 second
        }
        return startOfNext.addingTimeInterval(-1)
    }

    /// Check if date range spans given day
    public func dateRangeSpans(start: Date, end: Date, day: Date, timeZone: TimeZone? = nil) -> Bool {
        let cal = workingCalendar(timeZone: timeZone)
        let dayStart = cal.startOfDay(for: day)
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else {
            // Fallback: use 24 hours from start of day
            let fallbackEnd = dayStart.addingTimeInterval(86400)  // 24 hours
            return start < fallbackEnd && end > dayStart
        }

        return start < dayEnd && end > dayStart
    }

    /// Adds date components using this calendar system.
    ///
    /// - Parameters:
    ///   - component: The calendar component to add (day, month, year, etc.)
    ///   - value: The value to add (can be negative for subtraction)
    ///   - date: The base date to modify
    ///   - timeZone: Optional timezone (uses defaultTimeZone if nil)
    /// - Returns: New date with components added, or nil if calculation fails
    public func date(byAdding component: Calendar.Component, value: Int, to date: Date, timeZone: TimeZone? = nil) -> Date? {
        let cal = workingCalendar(timeZone: timeZone)
        return cal.date(byAdding: component, value: value, to: date)
    }

    /// Gets date components using this calendar system.
    ///
    /// - Parameters:
    ///   - components: Set of components to extract (year, month, day, etc.)
    ///   - date: The date to extract components from
    ///   - timeZone: Optional timezone (uses defaultTimeZone if nil)
    /// - Returns: DateComponents with requested components
    public func dateComponents(_ components: Set<Calendar.Component>, from date: Date, timeZone: TimeZone? = nil) -> DateComponents {
        let cal = workingCalendar(timeZone: timeZone)
        return cal.dateComponents(components, from: date)
    }

    /// Creates date from components using this calendar system.
    ///
    /// - Parameter components: DateComponents to create date from
    /// - Returns: Date created from components, or nil if invalid
    ///
    /// - Note: Uses the calendar's default timezone unless overridden in components
    public func date(from components: DateComponents) -> Date? {
        calendar.date(from: components)
    }
}

// MARK: - Event Extensions

extension ICalEvent {
    /// Gets the appropriate calendar context for this event.
    ///
    /// The context is automatically determined by examining the event's recurrence rule
    /// for RSCALE parameters. If no specific calendar system is found, defaults to Gregorian.
    ///
    /// - Returns: The calendar context appropriate for this event's calculations
    ///
    /// ```swift
    /// let event = client.createEvent(summary: "Passover", ...)
    /// event.recurrenceRule = client.createHebrewRecurrence(frequency: .yearly)
    /// print(event.context.calendarScale)  // .hebrew
    /// ```
    public var context: ICalendarContext {
        ICalendarContext(from: self)
    }

    /// Checks if the event occurs on a specific date using the proper calendar system.
    ///
    /// This method automatically uses the event's calendar context (detected from recurrence
    /// rules) to perform accurate date calculations. For Hebrew events, it uses Hebrew calendar;
    /// for Islamic events, it uses Islamic calendar, etc.
    ///
    /// - Parameters:
    ///   - date: The date to check against
    ///   - timeZone: Optional timezone override (uses context default if nil)
    ///   - context: Optional context override (uses event's context if nil)
    /// - Returns: True if the event occurs on the specified date
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Hebrew event automatically uses Hebrew calendar
    /// let passover = client.createEvent(summary: "Passover", ...)
    /// passover.recurrenceRule = client.createHebrewRecurrence(frequency: .yearly)
    /// let occursToday = passover.occursOn(date: Date())  // Uses Hebrew calendar
    ///
    /// // Override with specific timezone
    /// let occursInEST = passover.occursOn(
    ///     date: Date(),
    ///     timeZone: TimeZone(identifier: "America/New_York")
    /// )
    /// ```
    ///
    /// - Important: This method now correctly uses the event's calendar system instead
    ///   of always using the Gregorian calendar, fixing fundamental bugs in date calculations
    ///   for Hebrew, Islamic, and other calendar systems.
    public func occursOn(date: Date, timeZone: TimeZone? = nil, context: ICalendarContext? = nil) -> Bool {
        guard let start = dateTimeStart?.date else { return false }

        let effectiveContext = context ?? self.context
        let effectiveTimeZone = timeZone ?? effectiveContext.defaultTimeZone

        if dateTimeStart?.isDateOnly == true {
            return effectiveContext.dateOccursOn(start, day: date, timeZone: effectiveTimeZone)
        } else {
            if let end = dateTimeEnd?.date {
                return effectiveContext.dateRangeSpans(start: start, end: end, day: date, timeZone: effectiveTimeZone)
            } else {
                // Single point in time
                let cal = effectiveContext.workingCalendar(timeZone: effectiveTimeZone)
                return cal.isDate(start, inSameDayAs: date)
            }
        }
    }

    /// Get all occurrence dates for recurring event within date range
    public func occurrences(from startDate: Date, to endDate: Date, context: ICalendarContext? = nil) -> [Date] {
        guard let recurrenceRule = recurrenceRule,
            let eventStart = dateTimeStart?.date
        else {
            // Non-recurring event
            if let eventStart = dateTimeStart?.date,
                eventStart >= startDate && eventStart <= endDate
            {
                return [eventStart]
            }
            return []
        }

        let effectiveContext = context ?? self.context
        return calculateRecurrenceOccurrences(
            rule: recurrenceRule,
            startDate: eventStart,
            rangeStart: startDate,
            rangeEnd: endDate,
            context: effectiveContext
        )
    }

    private func calculateRecurrenceOccurrences(
        rule: ICalRecurrenceRule,
        startDate: Date,
        rangeStart: Date,
        rangeEnd: Date,
        context: ICalendarContext
    ) -> [Date] {
        var occurrences: [Date] = []
        var currentDate = startDate
        let cal = context.workingCalendar()

        // Simple implementation for basic frequencies
        let maxOccurrences = rule.count ?? 1000  // Prevent infinite loops

        for _ in 0..<maxOccurrences {
            if currentDate > rangeEnd {
                break
            }

            if currentDate >= rangeStart {
                occurrences.append(currentDate)
            }

            // Add interval based on frequency
            switch rule.frequency {
            case .daily:
                guard let nextDate = cal.date(byAdding: .day, value: rule.interval, to: currentDate) else {
                    break  // Stop if date calculation fails
                }
                currentDate = nextDate
            case .weekly:
                guard let nextDate = cal.date(byAdding: .weekOfYear, value: rule.interval, to: currentDate) else {
                    break  // Stop if date calculation fails
                }
                currentDate = nextDate
            case .monthly:
                guard let nextDate = cal.date(byAdding: .month, value: rule.interval, to: currentDate) else {
                    break  // Stop if date calculation fails
                }
                currentDate = nextDate
            case .yearly:
                guard let nextDate = cal.date(byAdding: .year, value: rule.interval, to: currentDate) else {
                    break  // Stop if date calculation fails
                }
                currentDate = nextDate
            default:
                break
            }

            if let until = rule.until?.date, currentDate > until {
                break
            }
        }

        return occurrences
    }
}

// MARK: - Calendar Extensions

extension ICalendar {
    /// Get calendar's context from properties (BREAKING CHANGE)
    public var context: ICalendarContext {
        ICalendarContext(from: self)
    }

    /// Get events on date using proper calendar system
    public func events(on date: Date, timeZone: TimeZone? = nil, context: ICalendarContext? = nil) -> [ICalEvent] {
        let effectiveContext = context ?? self.context
        return events.filter { event in
            event.occursOn(date: date, timeZone: timeZone, context: effectiveContext)
        }
    }

    /// Today's events using calendar context
    public var todaysEvents: [ICalEvent] {
        events(on: Date(), context: context)
    }

    /// Events in date range using proper calendar system
    public func events(from startDate: Date, to endDate: Date, timeZone: TimeZone? = nil, context: ICalendarContext? = nil) -> [ICalEvent] {
        let effectiveContext = context ?? self.context
        return events.filter { event in
            // Check if event or any of its occurrences fall within the range
            let occurrences = event.occurrences(from: startDate, to: endDate, context: effectiveContext)
            return !occurrences.isEmpty
        }
    }
}

// MARK: - Formatter Extensions

extension ICalendarFormatter {
    /// Parse datetime with context awareness
    public static func parseDateTime(_ value: String, context: ICalendarContext, timeZone: TimeZone? = nil) -> ICalDateTime? {
        let effectiveTimeZone = timeZone ?? context.defaultTimeZone
        return parseDateTime(value, timeZone: effectiveTimeZone)
    }

    /// Format datetime using context
    public static func format(dateTime: ICalDateTime, context: ICalendarContext) -> String {
        format(dateTime: dateTime)
    }
}
