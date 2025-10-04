import Foundation
import Synchronization

/// Registry for managing VTIMEZONE components following ical4j approach
/// This class handles loading timezone definitions from ical4j resources and provides caching
public final class TimeZoneRegistry: Sendable {
    public static let shared = TimeZoneRegistry()

    private let cacheMutex = Mutex<[String: ICalTimeZone]>([String: ICalTimeZone]())
    private let bundle = Bundle.module

    private init() {}

    /// Get timezone component for given timezone ID
    public func getTimeZone(for tzid: String) -> ICalTimeZone? {
        cacheMutex.withLock { cache in
            // Check cache first
            if let cached = cache[tzid] {
                return cached
            }

            // Try to load from ical4j resources first (preferred)
            if let vtimezone = loadFromIcal4jResource(tzid: tzid) {
                cache[tzid] = vtimezone
                return vtimezone
            }

            // Fallback to Foundation TimeZone
            if let fallback = createFromFoundationTimeZone(tzid: tzid) {
                cache[tzid] = fallback
                return fallback
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

    // MARK: - Private Methods

    private func loadFromIcal4jResource(tzid: String) -> ICalTimeZone? {
        let resourcePath = "zoneinfo/\(tzid).ics"

        guard let resourceURL = bundle.url(forResource: resourcePath, withExtension: nil) else {
            return nil
        }

        do {
            let content = try String(contentsOf: resourceURL, encoding: .utf8)

            // Parse timezone components from the ical4j resource file
            return parseTimezoneFromContent(content: content, tzid: tzid)

        } catch {
            return nil
        }
    }

    private func parseTimezoneFromContent(content: String, tzid: String) -> ICalTimeZone? {
        var timeZone = ICalTimeZone(timeZoneId: tzid)

        // Parse timezone components, but only use the most recent/relevant ones
        let components = extractTimezoneComponents(from: content)

        // Get the most recent STANDARD and DAYLIGHT components
        let standardComponents = components.filter { $0.type == "STANDARD" }
        let daylightComponents = components.filter { $0.type == "DAYLIGHT" }

        // Use only the last (most recent) STANDARD component
        if let lastStandard = standardComponents.last {
            var component = ICalTimeZoneComponent(isStandard: true)
            component.timeZoneName = lastStandard.name
            component.offsetFrom = lastStandard.offsetFrom
            component.offsetTo = lastStandard.offsetTo

            if let dtstart = lastStandard.dtstart {
                component.dateTimeStart = parseDateTimeStart(dtstart)
            }

            timeZone.components.append(component)
        }

        // Use only the last (most recent) DAYLIGHT component if it exists
        if let lastDaylight = daylightComponents.last {
            var component = ICalTimeZoneComponent(isStandard: false)
            component.timeZoneName = lastDaylight.name
            component.offsetFrom = lastDaylight.offsetFrom
            component.offsetTo = lastDaylight.offsetTo

            if let dtstart = lastDaylight.dtstart {
                component.dateTimeStart = parseDateTimeStart(dtstart)
            }

            timeZone.components.append(component)
        }

        return timeZone.components.isEmpty ? nil : timeZone
    }

    private func extractTimezoneComponents(from content: String) -> [TimezoneComponentInfo] {
        var components: [TimezoneComponentInfo] = []
        let lines = content.components(separatedBy: .newlines)
        var i = 0

        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("BEGIN:STANDARD") || line.hasPrefix("BEGIN:DAYLIGHT") {
                let componentType = line.hasPrefix("BEGIN:STANDARD") ? "STANDARD" : "DAYLIGHT"

                if let component = parseTimezoneComponent(lines: lines, startIndex: i, type: componentType) {
                    components.append(component)
                }
            }

            i += 1
        }

        return components
    }

    private func parseTimezoneComponent(lines: [String], startIndex: Int, type: String) -> TimezoneComponentInfo? {
        var name: String?
        var offsetFrom: String?
        var offsetTo: String?
        var dtstart: String?
        var i = startIndex + 1

        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            if line == "END:\(type)" {
                break
            }

            if line.hasPrefix("TZNAME:") {
                name = String(line.dropFirst("TZNAME:".count))
            } else if line.hasPrefix("TZOFFSETFROM:") {
                offsetFrom = String(line.dropFirst("TZOFFSETFROM:".count))
            } else if line.hasPrefix("TZOFFSETTO:") {
                offsetTo = String(line.dropFirst("TZOFFSETTO:".count))
            } else if line.hasPrefix("DTSTART:") {
                dtstart = String(line.dropFirst("DTSTART:".count))
            }

            i += 1
        }

        guard let name = name, let offsetFrom = offsetFrom, let offsetTo = offsetTo else {
            return nil
        }

        return TimezoneComponentInfo(type: type, name: name, offsetFrom: offsetFrom, offsetTo: offsetTo, dtstart: dtstart)
    }

    private func parseDateTimeStart(_ dtstart: String) -> ICalDateTime? {
        // Basic DTSTART parsing - this could be enhanced
        ICalDateTime(
            date: DateComponents(calendar: Calendar.current, year: 1970, month: 1, day: 1, hour: 0, minute: 0).date!,
            timeZone: nil,
            isDateOnly: false
        )
    }

    private func createFromFoundationTimeZone(tzid: String) -> ICalTimeZone? {
        guard let foundationTimeZone = TimeZone(identifier: tzid) else {
            return nil
        }

        var timeZone = ICalTimeZone(timeZoneId: tzid)

        // Create basic standard time component using current offset
        var standard = ICalTimeZoneComponent(isStandard: true)
        let currentOffset = foundationTimeZone.secondsFromGMT()
        let offsetString = formatOffset(currentOffset)

        standard.offsetFrom = offsetString
        standard.offsetTo = offsetString
        standard.timeZoneName = foundationTimeZone.abbreviation() ?? tzid
        standard.dateTimeStart = ICalDateTime(
            date: DateComponents(calendar: Calendar.current, year: 1970, month: 1, day: 1, hour: 0, minute: 0).date!,
            timeZone: nil,
            isDateOnly: false
        )

        timeZone.components = [standard]
        return timeZone
    }

    private func formatOffset(_ seconds: Int) -> String {
        let hours = abs(seconds) / 3600
        let minutes = (abs(seconds) % 3600) / 60
        let sign = seconds >= 0 ? "+" : "-"
        return String(format: "%@%02d%02d", sign, hours, minutes)
    }
}

// MARK: - Helper Types

private struct TimezoneComponentInfo {
    let type: String
    let name: String
    let offsetFrom: String
    let offsetTo: String
    let dtstart: String?
}
