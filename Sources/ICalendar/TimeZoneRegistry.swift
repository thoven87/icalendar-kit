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

        // Add X-LIC-LOCATION for better compatibility
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

            // Determine which season has standard vs daylight time
            let _ = winterOffset < summerOffset

            // STANDARD component (fall transition - back to standard time)
            var standardComponent = ICalTimeZoneComponent(isStandard: true)
            standardComponent.timeZoneName = getStandardAbbreviation(for: timeZone, isStandard: true)
            standardComponent.offsetFrom = formatOffset(daylightOffset)
            standardComponent.offsetTo = formatOffset(standardOffset)
            standardComponent.dateTimeStart = createDTStart(for: timeZone, isStandard: true)
            components.append(standardComponent)

            // DAYLIGHT component (spring transition - forward to daylight time)
            var daylightComponent = ICalTimeZoneComponent(isStandard: false)
            daylightComponent.timeZoneName = getStandardAbbreviation(for: timeZone, isStandard: false)
            daylightComponent.offsetFrom = formatOffset(standardOffset)
            daylightComponent.offsetTo = formatOffset(daylightOffset)
            daylightComponent.dateTimeStart = createDTStart(for: timeZone, isStandard: false)
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

    private func getStandardAbbreviation(for timeZone: TimeZone, isStandard: Bool) -> String {
        // Get timezone abbreviations for different times of year
        let winterDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let summerDate = Calendar.current.date(from: DateComponents(year: 2024, month: 7, day: 15))!

        let winterAbbrev = timeZone.abbreviation(for: winterDate) ?? "STD"
        let summerAbbrev = timeZone.abbreviation(for: summerDate) ?? "DST"

        // If abbreviations are different, we can distinguish standard vs daylight
        if winterAbbrev != summerAbbrev {
            let winterOffset = timeZone.secondsFromGMT(for: winterDate)
            let summerOffset = timeZone.secondsFromGMT(for: summerDate)

            // Standard time is typically the one with the smaller offset (more negative/less positive)
            if isStandard {
                return winterOffset <= summerOffset ? winterAbbrev : summerAbbrev
            } else {
                return winterOffset <= summerOffset ? summerAbbrev : winterAbbrev
            }
        }

        // If abbreviations are the same or we can't distinguish, use the abbreviation
        return isStandard ? winterAbbrev : summerAbbrev
    }

    private func formatOffset(_ seconds: Int) -> String {
        let hours = abs(seconds) / 3600
        let minutes = (abs(seconds) % 3600) / 60
        let sign = seconds >= 0 ? "+" : "-"
        return String(format: "%@%02d%02d", sign, hours, minutes)
    }

    private func createRRuleForTransition(isStandard: Bool, timeZone: TimeZone) -> ICalRecurrenceRule? {
        // TODO: Implement proper RRULE generation for DST transitions
        // For now, return nil to avoid complex/brittle rules
        nil
    }
}
