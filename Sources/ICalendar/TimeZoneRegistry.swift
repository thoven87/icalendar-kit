import Foundation
import Synchronization

/// Registry for managing VTIMEZONE components - generates them dynamically without file dependencies
/// By creating VTIMEZONE components at runtime using Foundation's TimeZone
public final class TimeZoneRegistry: Sendable {
    public static let shared = TimeZoneRegistry()

    private let cacheMutex = Mutex<[String: ICalTimeZone]>([String: ICalTimeZone]())

    private init() {}

    /// Get timezone component for given timezone ID
    public func getTimeZone(for tzid: String) -> ICalTimeZone? {
        cacheMutex.withLock { cache in
            // Check cache first
            if let cached = cache[tzid] {
                return cached
            }

            // Generate timezone component dynamically
            if let vtimezone = generateTimeZone(for: tzid) {
                cache[tzid] = vtimezone
                return vtimezone
            }

            return nil
        }
    }

    /// Clear the timezone cache
    public func clearCache() {
        cacheMutex.withLock { cache in
            cache.removeAll()
        }
    }

    // MARK: - Dynamic VTIMEZONE Generation

    private func generateTimeZone(for tzid: String) -> ICalTimeZone? {
        guard let foundationTimeZone = TimeZone(identifier: tzid) else {
            return nil
        }

        var timeZone = ICalTimeZone(timeZoneId: tzid)

        // Add TZURL for RFC 7808 compliance - automatic timezone updates
        timeZone.timeZoneUrl = ICalTimeZoneURLGenerator.generateTZURL(for: tzid)

        // Add X-LIC-LOCATION for better compatibility - set to IANA timezone identifier like ical.Net
        timeZone.xLicLocation = tzid

        // Generate timezone components based on DST transitions
        let components = generateTimezoneComponents(for: foundationTimeZone, tzid: tzid)
        timeZone.components = components

        return components.isEmpty ? nil : timeZone
    }

    private func generateTimezoneComponents(for timeZone: TimeZone, tzid: String) -> [ICalTimeZoneComponent] {
        var components: [ICalTimeZoneComponent] = []
        let currentDate = Date()

        // Check if timezone observes DST by looking at different times of year
        let winterDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let summerDate = Calendar.current.date(from: DateComponents(year: 2024, month: 7, day: 15))!

        let winterOffset = timeZone.secondsFromGMT(for: winterDate)
        let summerOffset = timeZone.secondsFromGMT(for: summerDate)

        if winterOffset != summerOffset {
            // DST observed - create both STANDARD and DAYLIGHT components
            let standardOffset = min(winterOffset, summerOffset)
            let daylightOffset = max(winterOffset, summerOffset)

            // STANDARD component (fall transition - back to standard time)
            var standardComponent = ICalTimeZoneComponent(isStandard: true)
            standardComponent.timeZoneName = getTimeZoneAbbreviation(for: timeZone, isStandard: true)
            standardComponent.offsetFrom = formatOffset(daylightOffset)
            standardComponent.offsetTo = formatOffset(standardOffset)
            standardComponent.dateTimeStart = createDTStart(for: timeZone, isStandard: true)
            if let rrule = createRRuleForTransition(isStandard: true, timeZone: timeZone) {
                standardComponent.recurrenceRule = rrule
            }
            components.append(standardComponent)

            // DAYLIGHT component (spring transition - forward to daylight time)
            var daylightComponent = ICalTimeZoneComponent(isStandard: false)
            daylightComponent.timeZoneName = getTimeZoneAbbreviation(for: timeZone, isStandard: false)
            daylightComponent.offsetFrom = formatOffset(standardOffset)
            daylightComponent.offsetTo = formatOffset(daylightOffset)
            daylightComponent.dateTimeStart = createDTStart(for: timeZone, isStandard: false)
            if let rrule = createRRuleForTransition(isStandard: false, timeZone: timeZone) {
                daylightComponent.recurrenceRule = rrule
            }
            components.append(daylightComponent)

        } else {
            // No DST - create single STANDARD component
            var standardComponent = ICalTimeZoneComponent(isStandard: true)
            standardComponent.timeZoneName = timeZone.abbreviation(for: currentDate) ?? tzid
            standardComponent.offsetFrom = formatOffset(winterOffset)
            standardComponent.offsetTo = formatOffset(winterOffset)
            standardComponent.dateTimeStart = createDTStart(for: timeZone, isStandard: true)
            components.append(standardComponent)
        }

        return components
    }

    private func createDTStart(for timeZone: TimeZone, isStandard: Bool) -> ICalDateTime {
        // Create a reasonable DTSTART for the timezone component
        // Use historical dates that are likely to have correct transitions
        let year = 1970

        // Use simple fixed dates for transitions - this is what many implementations do
        let month = isStandard ? 11 : 3  // November for standard, March for daylight
        let day = isStandard ? 1 : 14  // Simple fixed days

        // Create components without timezone to get "floating" time
        let dateComponents = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: 2,  // 2 AM is standard for DST transitions
            minute: 0,
            second: 0
        )

        let date = Calendar.current.date(from: dateComponents) ?? Date(timeIntervalSince1970: 0)

        // Return as floating time for VTIMEZONE DTSTART (no timezone, no Z suffix)
        return ICalDateTime(
            date: date,
            timeZone: nil,
            isDateOnly: false
        )
    }

    private func getTimeZoneAbbreviation(for timeZone: TimeZone, isStandard: Bool) -> String {
        // Use TimeZone.localizedName with appropriate locale
        // This gives us proper regional abbreviations (BST, PST, EST, etc.)

        // Determine appropriate locale for timezone
        let locale = getAppropriateLocale(for: timeZone.identifier)

        // Get the proper short timezone name
        let nameStyle: TimeZone.NameStyle = isStandard ? .shortStandard : .shortDaylightSaving
        if let abbreviation = timeZone.localizedName(for: nameStyle, locale: locale) {
            return abbreviation
        }

        // Fallback to abbreviation(for:) method
        let (standardDate, daylightDate) = findRepresentativeDates(for: timeZone)
        let targetDate = isStandard ? standardDate : daylightDate
        return timeZone.abbreviation(for: targetDate) ?? timeZone.identifier
    }

    private func getAppropriateLocale(for timezoneId: String) -> Locale {
        // Map timezone regions to appropriate locales for proper abbreviations
        if timezoneId.hasPrefix("Europe/") {
            // Use GB locale for European timezones to get proper abbreviations like BST
            return Locale(identifier: "en_GB")
        } else if timezoneId.hasPrefix("America/") {
            // Use US locale for American timezones
            return Locale(identifier: "en_US")
        } else if timezoneId.hasPrefix("Asia/") {
            // Use generic English locale for Asian timezones
            return Locale(identifier: "en")
        } else if timezoneId.hasPrefix("Australia/") || timezoneId.hasPrefix("Pacific/Auckland") {
            // Use AU locale for Australian/NZ timezones
            return Locale(identifier: "en_AU")
        }

        // Default to system locale
        return Locale.current
    }

    private func findRepresentativeDates(for timeZone: TimeZone) -> (standard: Date, daylight: Date) {
        let currentYear = Calendar.current.component(.year, from: Date())
        let calendar = Calendar.current

        // Sample dates throughout the year to find standard vs daylight periods
        var standardDate = Date()
        var daylightDate = Date()
        var minOffset = Int.max
        var maxOffset = Int.min

        // Sample every month to find the minimum and maximum offsets
        for month in 1...12 {
            guard let date = calendar.date(from: DateComponents(year: currentYear, month: month, day: 15)) else { continue }
            let offset = timeZone.secondsFromGMT(for: date)

            if offset < minOffset {
                minOffset = offset
                standardDate = date
            }
            if offset > maxOffset {
                maxOffset = offset
                daylightDate = date
            }
        }

        // If no DST (same offset year-round), use winter/summer dates
        if minOffset == maxOffset {
            let winterDate = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 15)) ?? Date()
            let summerDate = calendar.date(from: DateComponents(year: currentYear, month: 7, day: 15)) ?? Date()
            return (winterDate, summerDate)
        }

        return (standardDate, daylightDate)
    }

    private func formatOffset(_ seconds: Int) -> String {
        let hours = abs(seconds) / 3600
        let minutes = (abs(seconds) % 3600) / 60
        let sign = seconds >= 0 ? "+" : "-"
        return String(format: "%@%02d%02d", sign, hours, minutes)
    }

    private func createRRuleForTransition(isStandard: Bool, timeZone: TimeZone) -> ICalRecurrenceRule? {
        // Generate RRULE for DST transitions like ical.Net does with NodaTime
        guard let transitionInfo = analyzeDSTTransitions(for: timeZone, isStandard: isStandard) else {
            return nil
        }

        var rrule = ICalRecurrenceRule(
            frequency: .yearly,
            byWeekday: [transitionInfo.weekday],
            byMonth: [transitionInfo.month]
        )

        if let weekOfMonth = transitionInfo.weekOfMonth {
            // Specific week of month (e.g., 2nd Sunday)
            rrule = ICalRecurrenceRule(
                frequency: .yearly,
                byWeekday: [transitionInfo.weekday],
                byMonth: [transitionInfo.month],
                bySetpos: [weekOfMonth]
            )
        } else if transitionInfo.isLastWeekOfMonth {
            // Last week of month (e.g., last Sunday)
            rrule = ICalRecurrenceRule(
                frequency: .yearly,
                byWeekday: [transitionInfo.weekday],
                byMonth: [transitionInfo.month],
                bySetpos: [-1]
            )
        }

        return rrule
    }

    private struct DSTTransitionInfo {
        let month: Int
        let weekday: ICalWeekday
        let weekOfMonth: Int?
        let isLastWeekOfMonth: Bool
    }

    private func analyzeDSTTransitions(for timeZone: TimeZone, isStandard: Bool) -> DSTTransitionInfo? {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        // Check multiple years to find consistent pattern
        var transitions: [Date] = []

        for year in (currentYear - 2)...(currentYear + 2) {
            if let transition = findTransitionDate(for: timeZone, year: year, isStandard: isStandard) {
                transitions.append(transition)
            }
        }

        guard let firstTransition = transitions.first else { return nil }

        let month = calendar.component(.month, from: firstTransition)
        let weekday = weekdayFromFoundation(calendar.component(.weekday, from: firstTransition))
        let dayOfMonth = calendar.component(.day, from: firstTransition)

        // Determine if it's a specific week or last week of month
        let weekOfMonth = calculateWeekOfMonth(dayOfMonth: dayOfMonth, month: month, year: calendar.component(.year, from: firstTransition))
        let isLastWeek = isLastWeekOfMonth(dayOfMonth: dayOfMonth, month: month, year: calendar.component(.year, from: firstTransition))

        return DSTTransitionInfo(
            month: month,
            weekday: weekday,
            weekOfMonth: isLastWeek ? nil : weekOfMonth,
            isLastWeekOfMonth: isLastWeek
        )
    }

    private func findTransitionDate(for timeZone: TimeZone, year: Int, isStandard: Bool) -> Date? {
        let calendar = Calendar.current

        // For standard transitions, check fall months (Sept-Dec)
        // For daylight transitions, check spring months (Feb-May)
        let monthsToCheck = isStandard ? [9, 10, 11, 12] : [2, 3, 4, 5]

        for month in monthsToCheck {
            // Check each day of the month for offset changes
            for day in 1...31 {
                guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)),
                    let nextDate = calendar.date(byAdding: .day, value: 1, to: date)
                else { continue }

                let currentOffset = timeZone.secondsFromGMT(for: date)
                let nextOffset = timeZone.secondsFromGMT(for: nextDate)

                if isStandard {
                    // Standard transition: offset decreases (fall back)
                    if nextOffset < currentOffset {
                        // Return the actual transition day (current date), not the day after
                        return date
                    }
                } else {
                    // Daylight transition: offset increases (spring forward)
                    if nextOffset > currentOffset {
                        // Return the actual transition day (current date), not the day after
                        return date
                    }
                }
            }
        }

        return nil
    }

    private func calculateWeekOfMonth(dayOfMonth: Int, month: Int, year: Int) -> Int {
        (dayOfMonth - 1) / 7 + 1
    }

    private func isLastWeekOfMonth(dayOfMonth: Int, month: Int, year: Int) -> Bool {
        let calendar = Calendar.current
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: dayOfMonth)),
            let range = calendar.range(of: .day, in: .month, for: date)
        else {
            return false
        }

        let lastDayOfMonth = range.upperBound - 1
        return (lastDayOfMonth - dayOfMonth) < 7
    }

    private func weekdayFromFoundation(_ foundationWeekday: Int) -> ICalWeekday {
        switch foundationWeekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .sunday
        }
    }
}
