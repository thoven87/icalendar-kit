import Foundation

// MARK: - Non-Gregorian Calendar Support

/// Support for non-Gregorian calendar systems in iCalendar
/// Provides conversion and formatting for various international calendar systems
public struct ICalNonGregorianCalendars: Sendable {

    /// Supported non-Gregorian calendar systems
    public enum CalendarSystem: String, CaseIterable, Codable, Sendable {
        case hebrew = "HEBREW"
        case islamic = "ISLAMIC"
        case chinese = "CHINESE"
        case buddhist = "BUDDHIST"
        case persian = "PERSIAN"
        case indian = "INDIAN"
        case japanese = "JAPANESE"
        case coptic = "COPTIC"
        case ethiopic = "ETHIOPIC"
        case iso8601 = "ISO8601"
        case republicOfChina = "REPUBLIC-OF-CHINA"

        /// Foundation Calendar identifier mapping
        public var foundationIdentifier: Calendar.Identifier? {
            switch self {
            case .hebrew: return .hebrew
            case .islamic: return .islamicCivil
            case .chinese: return .chinese
            case .buddhist: return .buddhist
            case .persian: return .persian
            case .indian: return .indian
            case .japanese: return .japanese
            case .coptic: return .coptic
            case .ethiopic: return .ethiopicAmeteAlem
            case .iso8601: return .iso8601
            case .republicOfChina: return .republicOfChina
            }
        }
    }

    /// Calendar-specific date representation
    public struct CalendarDate: Equatable, Hashable, Codable, Sendable {
        public let calendarSystem: CalendarSystem
        public let year: Int
        public let month: Int
        public let day: Int
        public let era: Int?
        public let isLeapYear: Bool
        public let gregorianEquivalent: Date

        public init(
            calendarSystem: CalendarSystem,
            year: Int,
            month: Int,
            day: Int,
            era: Int? = nil,
            isLeapYear: Bool = false,
            gregorianEquivalent: Date
        ) {
            self.calendarSystem = calendarSystem
            self.year = year
            self.month = month
            self.day = day
            self.era = era
            self.isLeapYear = isLeapYear
            self.gregorianEquivalent = gregorianEquivalent
        }
    }

    /// Calendar conversion utilities
    public struct CalendarConverter: Sendable {

        /// Convert Gregorian date to specified calendar system
        public static func convertToCalendarSystem(
            _ date: Date,
            calendarSystem: CalendarSystem,
            timeZone: TimeZone = .current
        ) -> CalendarDate? {
            guard let identifier = calendarSystem.foundationIdentifier else { return nil }

            var calendar = Calendar(identifier: identifier)
            calendar.timeZone = timeZone

            let components = calendar.dateComponents([.year, .month, .day, .era], from: date)

            guard let year = components.year,
                let month = components.month,
                let day = components.day
            else {
                return nil
            }

            let isLeapYear = calendar.range(of: .day, in: .year, for: date)?.count ?? 0 > 365

            return CalendarDate(
                calendarSystem: calendarSystem,
                year: year,
                month: month,
                day: day,
                era: components.era,
                isLeapYear: isLeapYear,
                gregorianEquivalent: date
            )
        }

        /// Convert calendar date back to Gregorian
        public static func convertToGregorian(
            _ calendarDate: CalendarDate,
            timeZone: TimeZone = .current
        ) -> Date? {
            guard let identifier = calendarDate.calendarSystem.foundationIdentifier else {
                return calendarDate.gregorianEquivalent
            }

            var calendar = Calendar(identifier: identifier)
            calendar.timeZone = timeZone

            var components = DateComponents()
            components.year = calendarDate.year
            components.month = calendarDate.month
            components.day = calendarDate.day
            components.era = calendarDate.era

            return calendar.date(from: components)
        }

        /// Format date in native calendar system
        public static func formatDate(
            _ calendarDate: CalendarDate,
            style: DateFormatter.Style = .medium,
            locale: Locale = .current
        ) -> String {
            guard let identifier = calendarDate.calendarSystem.foundationIdentifier else {
                return DateFormatter.localizedString(from: calendarDate.gregorianEquivalent, dateStyle: style, timeStyle: .none)
            }

            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: identifier)
            formatter.dateStyle = style
            formatter.locale = locale

            return formatter.string(from: calendarDate.gregorianEquivalent)
        }
    }

    /// Calendar-specific formatting and localization
    public struct CalendarFormatting: Sendable {

        /// Month names in different calendar systems
        public static func monthNames(for calendarSystem: CalendarSystem, locale: Locale = .current) -> [String] {
            guard let identifier = calendarSystem.foundationIdentifier else { return [] }

            var calendar = Calendar(identifier: identifier)
            calendar.locale = locale

            return calendar.monthSymbols
        }

        /// Era names in different calendar systems
        public static func eraNames(for calendarSystem: CalendarSystem, locale: Locale = .current) -> [String] {
            guard let identifier = calendarSystem.foundationIdentifier else { return [] }

            var calendar = Calendar(identifier: identifier)
            calendar.locale = locale

            return calendar.eraSymbols
        }

        /// Weekday names in different calendar systems
        public static func weekdayNames(for calendarSystem: CalendarSystem, locale: Locale = .current) -> [String] {
            guard let identifier = calendarSystem.foundationIdentifier else { return [] }

            var calendar = Calendar(identifier: identifier)
            calendar.locale = locale

            return calendar.weekdaySymbols
        }

        /// First day of week for calendar system
        public static func firstDayOfWeek(for calendarSystem: CalendarSystem, locale: Locale = .current) -> Int {
            guard let identifier = calendarSystem.foundationIdentifier else { return 1 }

            var calendar = Calendar(identifier: identifier)
            calendar.locale = locale

            return calendar.firstWeekday
        }
    }

    /// Religious and cultural observances
    public struct CulturalObservances: Sendable {

        /// Holiday information
        public struct Holiday: Equatable, Hashable, Codable, Sendable {
            public let name: String
            public let calendarSystem: CalendarSystem
            public let month: Int
            public let day: Int
            public let isMoveable: Bool
            public let description: String?
            public let category: HolidayCategory

            public init(
                name: String,
                calendarSystem: CalendarSystem,
                month: Int,
                day: Int,
                isMoveable: Bool = false,
                description: String? = nil,
                category: HolidayCategory = .religious
            ) {
                self.name = name
                self.calendarSystem = calendarSystem
                self.month = month
                self.day = day
                self.isMoveable = isMoveable
                self.description = description
                self.category = category
            }
        }

        public enum HolidayCategory: String, CaseIterable, Codable, Sendable {
            case religious = "RELIGIOUS"
            case cultural = "CULTURAL"
            case national = "NATIONAL"
            case seasonal = "SEASONAL"
            case astronomical = "ASTRONOMICAL"
        }

        /// Common holidays for different calendar systems
        public static func holidays(for calendarSystem: CalendarSystem) -> [Holiday] {
            switch calendarSystem {
            case .hebrew:
                return hebrewHolidays
            case .islamic:
                return islamicHolidays
            case .chinese:
                return chineseHolidays
            case .buddhist:
                return buddhistHolidays
            case .persian:
                return persianHolidays
            case .indian:
                return indianHolidays
            case .japanese:
                return japaneseHolidays
            case .coptic:
                return copticHolidays
            case .ethiopic:
                return ethiopicHolidays
            default:
                return []
            }
        }

        private static let hebrewHolidays: [Holiday] = [
            Holiday(name: "Rosh Hashanah", calendarSystem: .hebrew, month: 1, day: 1, category: .religious),
            Holiday(name: "Yom Kippur", calendarSystem: .hebrew, month: 1, day: 10, category: .religious),
            Holiday(name: "Sukkot", calendarSystem: .hebrew, month: 1, day: 15, category: .religious),
            Holiday(name: "Hanukkah", calendarSystem: .hebrew, month: 3, day: 25, category: .religious),
            Holiday(name: "Tu BiShvat", calendarSystem: .hebrew, month: 5, day: 15, category: .cultural),
            Holiday(name: "Purim", calendarSystem: .hebrew, month: 6, day: 14, isMoveable: true, category: .religious),
            Holiday(name: "Passover", calendarSystem: .hebrew, month: 7, day: 15, category: .religious),
        ]

        private static let islamicHolidays: [Holiday] = [
            Holiday(name: "Muharram", calendarSystem: .islamic, month: 1, day: 1, category: .religious),
            Holiday(name: "Ashura", calendarSystem: .islamic, month: 1, day: 10, category: .religious),
            Holiday(name: "Mawlid an-Nabi", calendarSystem: .islamic, month: 3, day: 12, isMoveable: true, category: .religious),
            Holiday(name: "Ramadan", calendarSystem: .islamic, month: 9, day: 1, category: .religious),
            Holiday(name: "Eid al-Fitr", calendarSystem: .islamic, month: 10, day: 1, category: .religious),
            Holiday(name: "Eid al-Adha", calendarSystem: .islamic, month: 12, day: 10, category: .religious),
        ]

        private static let chineseHolidays: [Holiday] = [
            Holiday(name: "Chinese New Year", calendarSystem: .chinese, month: 1, day: 1, category: .cultural),
            Holiday(name: "Lantern Festival", calendarSystem: .chinese, month: 1, day: 15, category: .cultural),
            Holiday(name: "Dragon Boat Festival", calendarSystem: .chinese, month: 5, day: 5, category: .cultural),
            Holiday(name: "Qixi Festival", calendarSystem: .chinese, month: 7, day: 7, category: .cultural),
            Holiday(name: "Ghost Festival", calendarSystem: .chinese, month: 7, day: 15, category: .cultural),
            Holiday(name: "Mid-Autumn Festival", calendarSystem: .chinese, month: 8, day: 15, category: .cultural),
        ]

        private static let buddhistHolidays: [Holiday] = [
            Holiday(name: "Buddha's Birthday", calendarSystem: .buddhist, month: 5, day: 15, isMoveable: true, category: .religious),
            Holiday(name: "Vesak", calendarSystem: .buddhist, month: 5, day: 15, isMoveable: true, category: .religious),
            Holiday(name: "Asalha Puja", calendarSystem: .buddhist, month: 8, day: 15, isMoveable: true, category: .religious),
            Holiday(name: "Kathina", calendarSystem: .buddhist, month: 11, day: 15, isMoveable: true, category: .religious),
        ]

        private static let persianHolidays: [Holiday] = [
            Holiday(name: "Nowruz", calendarSystem: .persian, month: 1, day: 1, category: .cultural),
            Holiday(name: "Sizdeh Bedar", calendarSystem: .persian, month: 1, day: 13, category: .cultural),
            Holiday(name: "Yalda", calendarSystem: .persian, month: 10, day: 1, category: .seasonal),
        ]

        private static let indianHolidays: [Holiday] = [
            Holiday(name: "Diwali", calendarSystem: .indian, month: 8, day: 15, isMoveable: true, category: .religious),
            Holiday(name: "Holi", calendarSystem: .indian, month: 12, day: 15, isMoveable: true, category: .cultural),
            Holiday(name: "Dussehra", calendarSystem: .indian, month: 7, day: 10, isMoveable: true, category: .religious),
        ]

        private static let japaneseHolidays: [Holiday] = [
            Holiday(name: "Oshogatsu", calendarSystem: .japanese, month: 1, day: 1, category: .cultural),
            Holiday(name: "Setsubun", calendarSystem: .japanese, month: 2, day: 3, category: .cultural),
            Holiday(name: "Tanabata", calendarSystem: .japanese, month: 7, day: 7, category: .cultural),
        ]

        private static let copticHolidays: [Holiday] = [
            Holiday(name: "Coptic New Year", calendarSystem: .coptic, month: 1, day: 1, category: .religious),
            Holiday(name: "Coptic Christmas", calendarSystem: .coptic, month: 4, day: 29, category: .religious),
            Holiday(name: "Epiphany", calendarSystem: .coptic, month: 5, day: 11, category: .religious),
        ]

        private static let ethiopicHolidays: [Holiday] = [
            Holiday(name: "Ethiopian New Year", calendarSystem: .ethiopic, month: 1, day: 1, category: .cultural),
            Holiday(name: "Timkat", calendarSystem: .ethiopic, month: 5, day: 11, category: .religious),
            Holiday(name: "Ethiopian Christmas", calendarSystem: .ethiopic, month: 4, day: 29, category: .religious),
        ]
    }

    /// Astronomical calculations for calendar systems
    public struct AstronomicalCalculations: Sendable {

        /// Moon phase information
        public struct MoonPhase: Equatable, Sendable {
            public let phase: Phase
            public let date: Date
            public let illumination: Double  // 0.0 to 1.0

            public enum Phase: String, CaseIterable, Sendable {
                case newMoon = "NEW_MOON"
                case waxingCrescent = "WAXING_CRESCENT"
                case firstQuarter = "FIRST_QUARTER"
                case waxingGibbous = "WAXING_GIBBOUS"
                case fullMoon = "FULL_MOON"
                case waningGibbous = "WANING_GIBBOUS"
                case lastQuarter = "LAST_QUARTER"
                case waningCrescent = "WANING_CRESCENT"
            }

            public init(phase: Phase, date: Date, illumination: Double) {
                self.phase = phase
                self.date = date
                self.illumination = illumination
            }
        }

        /// Solar calculations
        public struct SolarInfo: Equatable, Sendable {
            public let sunrise: Date
            public let sunset: Date
            public let solarNoon: Date
            public let dayLength: TimeInterval
            public let seasonalPosition: Double  // 0.0 to 1.0 through the year

            public init(sunrise: Date, sunset: Date, solarNoon: Date, dayLength: TimeInterval, seasonalPosition: Double) {
                self.sunrise = sunrise
                self.sunset = sunset
                self.solarNoon = solarNoon
                self.dayLength = dayLength
                self.seasonalPosition = seasonalPosition
            }
        }

        /// Calculate moon phase for date (simplified calculation)
        public static func moonPhase(for date: Date) -> MoonPhase {
            // Simplified lunar cycle calculation (29.53 days average)
            let referenceNewMoon = Date(timeIntervalSince1970: 592800)  // Jan 8, 1970 (close to new moon)
            let lunarCycle: TimeInterval = 29.53 * 24 * 60 * 60

            let daysSinceReference = date.timeIntervalSince(referenceNewMoon)
            let cyclePosition = (daysSinceReference.truncatingRemainder(dividingBy: lunarCycle)) / lunarCycle

            let phase: MoonPhase.Phase
            let illumination: Double

            switch cyclePosition {
            case 0.0..<0.125:
                phase = .newMoon
                illumination = cyclePosition * 8
            case 0.125..<0.25:
                phase = .waxingCrescent
                illumination = (cyclePosition - 0.125) * 8
            case 0.25..<0.375:
                phase = .firstQuarter
                illumination = 0.5 + (cyclePosition - 0.25) * 4
            case 0.375..<0.5:
                phase = .waxingGibbous
                illumination = 0.75 + (cyclePosition - 0.375) * 2
            case 0.5..<0.625:
                phase = .fullMoon
                illumination = 1.0 - (cyclePosition - 0.5) * 2
            case 0.625..<0.75:
                phase = .waningGibbous
                illumination = 0.75 - (cyclePosition - 0.625) * 4
            case 0.75..<0.875:
                phase = .lastQuarter
                illumination = 0.5 - (cyclePosition - 0.75) * 8
            default:
                phase = .waningCrescent
                illumination = (1.0 - cyclePosition) * 8
            }

            return MoonPhase(phase: phase, date: date, illumination: min(1.0, max(0.0, illumination)))
        }

        /// Basic solar information calculation
        public static func solarInfo(for date: Date, latitude: Double, longitude: Double) -> SolarInfo {
            let calendar = Calendar.current
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

            // Simplified calculation - for production use, consider more accurate astronomical libraries
            let seasonalPosition = Double(dayOfYear) / 365.25

            // Approximate sunrise/sunset calculation
            let solarNoon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
            let dayLengthHours = 12 + 4 * sin(2 * .pi * seasonalPosition) * sin(.pi * latitude / 180)
            let dayLength = dayLengthHours * 3600

            let sunrise = solarNoon.addingTimeInterval(-dayLength / 2)
            let sunset = solarNoon.addingTimeInterval(dayLength / 2)

            return SolarInfo(
                sunrise: sunrise,
                sunset: sunset,
                solarNoon: solarNoon,
                dayLength: dayLength,
                seasonalPosition: seasonalPosition
            )
        }
    }
}

// MARK: - Extensions for Non-Gregorian Calendar Support

extension ICalEvent {
    /// Add non-Gregorian calendar date information
    public mutating func setNonGregorianDate(
        _ calendarDate: ICalNonGregorianCalendars.CalendarDate,
        for property: String = "DTSTART"
    ) {
        // Set the standard Gregorian date
        if property == "DTSTART" {
            dateTimeStart = ICalDateTime(date: calendarDate.gregorianEquivalent)
        } else if property == "DTEND" {
            dateTimeEnd = ICalDateTime(date: calendarDate.gregorianEquivalent)
        }

        // Add calendar system metadata
        setPropertyValue("X-\(property)-CALENDAR-SYSTEM", value: calendarDate.calendarSystem.rawValue)
        setPropertyValue("X-\(property)-NATIVE-DATE", value: "\(calendarDate.year)-\(calendarDate.month)-\(calendarDate.day)")

        if let era = calendarDate.era {
            setPropertyValue("X-\(property)-ERA", value: String(era))
        }

        if calendarDate.isLeapYear {
            setPropertyValue("X-\(property)-LEAP-YEAR", value: "TRUE")
        }
    }

    /// Get non-Gregorian calendar information
    public func getNonGregorianDate(for property: String = "DTSTART") -> ICalNonGregorianCalendars.CalendarDate? {
        guard let systemValue = getPropertyValue("X-\(property)-CALENDAR-SYSTEM"),
            let system = ICalNonGregorianCalendars.CalendarSystem(rawValue: systemValue),
            let nativeDateValue = getPropertyValue("X-\(property)-NATIVE-DATE")
        else {
            return nil
        }

        let components = nativeDateValue.split(separator: "-").compactMap { Int($0) }
        guard components.count == 3 else { return nil }

        let era = getPropertyValue("X-\(property)-ERA").flatMap(Int.init)
        let isLeapYear = getPropertyValue("X-\(property)-LEAP-YEAR") == "TRUE"

        let gregorianDate: Date
        if property == "DTSTART" {
            gregorianDate = dateTimeStart?.date ?? Date()
        } else if property == "DTEND" {
            gregorianDate = dateTimeEnd?.date ?? Date()
        } else {
            gregorianDate = Date()
        }

        return ICalNonGregorianCalendars.CalendarDate(
            calendarSystem: system,
            year: components[0],
            month: components[1],
            day: components[2],
            era: era,
            isLeapYear: isLeapYear,
            gregorianEquivalent: gregorianDate
        )
    }

    /// Set cultural observance information
    public mutating func setCulturalObservance(_ holiday: ICalNonGregorianCalendars.CulturalObservances.Holiday) {
        summary = holiday.name
        setPropertyValue("X-CULTURAL-OBSERVANCE", value: "TRUE")
        setPropertyValue("X-OBSERVANCE-CALENDAR", value: holiday.calendarSystem.rawValue)
        setPropertyValue("X-OBSERVANCE-CATEGORY", value: holiday.category.rawValue)

        if let description = holiday.description {
            self.description = description
        }

        if holiday.isMoveable {
            setPropertyValue("X-OBSERVANCE-MOVEABLE", value: "TRUE")
        }
    }
}

extension ICalDateTime {
    /// Create ICalDateTime with non-Gregorian calendar context
    public init(calendarDate: ICalNonGregorianCalendars.CalendarDate, timeZone: TimeZone = .current) {
        self.init(date: calendarDate.gregorianEquivalent, timeZone: timeZone)
    }

    /// Convert to specific calendar system
    public func toCalendarSystem(_ system: ICalNonGregorianCalendars.CalendarSystem) -> ICalNonGregorianCalendars.CalendarDate? {
        ICalNonGregorianCalendars.CalendarConverter.convertToCalendarSystem(
            date,
            calendarSystem: system,
            timeZone: timeZone ?? .current
        )
    }
}
