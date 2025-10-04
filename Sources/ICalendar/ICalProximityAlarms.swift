import CoreLocation
import Foundation

// MARK: - Proximity Alarms Support

/// Support for location-based and proximity alarms in iCalendar
/// Provides geofencing, location-based triggers, and proximity scheduling
public struct ICalProximityAlarms: Sendable {

    /// Proximity alarm types
    public enum ProximityType: String, CaseIterable, Codable, Sendable {
        case entering = "ENTERING"
        case leaving = "LEAVING"
        case within = "WITHIN"
        case outside = "OUTSIDE"
        case approaching = "APPROACHING"
        case moving_away = "MOVING-AWAY"
    }

    /// Distance units for proximity calculations
    public enum DistanceUnit: String, CaseIterable, Codable, Sendable {
        case meters = "METERS"
        case kilometers = "KILOMETERS"
        case feet = "FEET"
        case miles = "MILES"
        case nauticalMiles = "NAUTICAL-MILES"

        /// Convert to meters for calculations
        public var metersMultiplier: Double {
            switch self {
            case .meters: return 1.0
            case .kilometers: return 1000.0
            case .feet: return 0.3048
            case .miles: return 1609.344
            case .nauticalMiles: return 1852.0
            }
        }
    }

    /// Geographic region definition
    public struct GeographicRegion: Equatable, Hashable, Codable, Sendable {
        public let id: String
        public let name: String?
        public let center: CLLocationCoordinate2D
        public let radius: Double
        public let unit: DistanceUnit
        public let shape: RegionShape
        public let metadata: [String: String]

        public enum RegionShape: String, CaseIterable, Codable, Sendable {
            case circle = "CIRCLE"
            case rectangle = "RECTANGLE"
            case polygon = "POLYGON"
        }

        public init(
            id: String = UUID().uuidString,
            name: String? = nil,
            center: CLLocationCoordinate2D,
            radius: Double,
            unit: DistanceUnit = .meters,
            shape: RegionShape = .circle,
            metadata: [String: String] = [:]
        ) {
            self.id = id
            self.name = name
            self.center = center
            self.radius = radius
            self.unit = unit
            self.shape = shape
            self.metadata = metadata
        }

        /// Get radius in meters
        public var radiusInMeters: Double {
            radius * unit.metersMultiplier
        }
    }

    /// Proximity alarm configuration
    public struct ProximityAlarm: Equatable, Hashable, Codable, Sendable {
        public let id: String
        public let region: GeographicRegion
        public let proximityType: ProximityType
        public let action: ICalAlarmAction
        public let trigger: ProximityTrigger
        public let isEnabled: Bool
        public let repeatInterval: TimeInterval?
        public let maxRepeats: Int?
        public let conditions: [ProximityCondition]

        public init(
            id: String = UUID().uuidString,
            region: GeographicRegion,
            proximityType: ProximityType,
            action: ICalAlarmAction = .display,
            trigger: ProximityTrigger,
            isEnabled: Bool = true,
            repeatInterval: TimeInterval? = nil,
            maxRepeats: Int? = nil,
            conditions: [ProximityCondition] = []
        ) {
            self.id = id
            self.region = region
            self.proximityType = proximityType
            self.action = action
            self.trigger = trigger
            self.isEnabled = isEnabled
            self.repeatInterval = repeatInterval
            self.maxRepeats = maxRepeats
            self.conditions = conditions
        }
    }

    /// Proximity trigger configuration
    public struct ProximityTrigger: Equatable, Hashable, Codable, Sendable {
        public let threshold: Double
        public let unit: DistanceUnit
        public let duration: TimeInterval?
        public let accuracy: LocationAccuracy
        public let triggerOnce: Bool

        public enum LocationAccuracy: String, CaseIterable, Codable, Sendable {
            case best = "BEST"
            case navigation = "NAVIGATION"
            case nearestTenMeters = "TEN-METERS"
            case hundredMeters = "HUNDRED-METERS"
            case kilometer = "KILOMETER"
            case threeKilometers = "THREE-KILOMETERS"

            public var coreLocationAccuracy: CLLocationAccuracy {
                switch self {
                case .best: return kCLLocationAccuracyBest
                case .navigation: return kCLLocationAccuracyBestForNavigation
                case .nearestTenMeters: return kCLLocationAccuracyNearestTenMeters
                case .hundredMeters: return kCLLocationAccuracyHundredMeters
                case .kilometer: return kCLLocationAccuracyKilometer
                case .threeKilometers: return kCLLocationAccuracyThreeKilometers
                }
            }
        }

        public init(
            threshold: Double,
            unit: DistanceUnit = .meters,
            duration: TimeInterval? = nil,
            accuracy: LocationAccuracy = .nearestTenMeters,
            triggerOnce: Bool = false
        ) {
            self.threshold = threshold
            self.unit = unit
            self.duration = duration
            self.accuracy = accuracy
            self.triggerOnce = triggerOnce
        }

        /// Get threshold in meters
        public var thresholdInMeters: Double {
            threshold * unit.metersMultiplier
        }
    }

    /// Proximity condition for complex triggers
    public struct ProximityCondition: Equatable, Hashable, Codable, Sendable {
        public let type: ConditionType
        public let value: String
        public let `operator`: ComparisonOperator

        public enum ConditionType: String, CaseIterable, Codable, Sendable {
            case timeOfDay = "TIME-OF-DAY"
            case dayOfWeek = "DAY-OF-WEEK"
            case speed = "SPEED"
            case heading = "HEADING"
            case altitude = "ALTITUDE"
            case weather = "WEATHER"
            case batteryLevel = "BATTERY-LEVEL"
            case networkType = "NETWORK-TYPE"
        }

        public enum ComparisonOperator: String, CaseIterable, Codable, Sendable {
            case equals = "EQUALS"
            case notEquals = "NOT-EQUALS"
            case greaterThan = "GREATER-THAN"
            case lessThan = "LESS-THAN"
            case greaterThanOrEqual = "GREATER-THAN-OR-EQUAL"
            case lessThanOrEqual = "LESS-THAN-OR-EQUAL"
            case contains = "CONTAINS"
            case notContains = "NOT-CONTAINS"
        }

        public init(type: ConditionType, value: String, operator: ComparisonOperator = .equals) {
            self.type = type
            self.value = value
            self.`operator` = `operator`
        }
    }

    /// Location-based event scheduling
    public struct LocationBasedSchedule: Sendable {
        public let id: String
        public let event: ICalEvent
        public let locationTriggers: [LocationTrigger]
        public let travelTimeBuffer: TimeInterval?
        public let autoAdjustForTraffic: Bool

        public init(
            id: String = UUID().uuidString,
            event: ICalEvent,
            locationTriggers: [LocationTrigger],
            travelTimeBuffer: TimeInterval? = nil,
            autoAdjustForTraffic: Bool = false
        ) {
            self.id = id
            self.event = event
            self.locationTriggers = locationTriggers
            self.travelTimeBuffer = travelTimeBuffer
            self.autoAdjustForTraffic = autoAdjustForTraffic
        }
    }

    /// Location trigger for event scheduling
    public struct LocationTrigger: Sendable {
        public let fromLocation: CLLocationCoordinate2D?
        public let toLocation: CLLocationCoordinate2D
        public let transportationType: TransportationType
        public let adjustmentType: TimeAdjustmentType

        public enum TransportationType: String, CaseIterable, Codable, Sendable {
            case automobile = "AUTOMOBILE"
            case walking = "WALKING"
            case transit = "TRANSIT"
            case bicycle = "BICYCLE"
            case any = "ANY"
        }

        public enum TimeAdjustmentType: String, CaseIterable, Codable, Sendable {
            case startTime = "START-TIME"
            case departureTime = "DEPARTURE-TIME"
            case arrivalTime = "ARRIVAL-TIME"
            case reminder = "REMINDER"
        }

        public init(
            fromLocation: CLLocationCoordinate2D? = nil,
            toLocation: CLLocationCoordinate2D,
            transportationType: TransportationType = .automobile,
            adjustmentType: TimeAdjustmentType = .reminder
        ) {
            self.fromLocation = fromLocation
            self.toLocation = toLocation
            self.transportationType = transportationType
            self.adjustmentType = adjustmentType
        }
    }

    /// Travel time estimation
    public struct TravelTimeEstimation: Sendable {
        public let distance: Double
        public let estimatedDuration: TimeInterval
        public let withTraffic: TimeInterval?
        public let transportationType: LocationTrigger.TransportationType
        public let route: [CLLocationCoordinate2D]?

        public init(
            distance: Double,
            estimatedDuration: TimeInterval,
            withTraffic: TimeInterval? = nil,
            transportationType: LocationTrigger.TransportationType,
            route: [CLLocationCoordinate2D]? = nil
        ) {
            self.distance = distance
            self.estimatedDuration = estimatedDuration
            self.withTraffic = withTraffic
            self.transportationType = transportationType
            self.route = route
        }
    }
}

// MARK: - Proximity Alarm Manager

/// Manages proximity alarms and location-based scheduling
public struct ICalProximityAlarmManager: Sendable {

    private let geofenceRadius: Double
    private let locationAccuracy: ICalProximityAlarms.ProximityTrigger.LocationAccuracy

    public init(
        geofenceRadius: Double = 100.0,
        locationAccuracy: ICalProximityAlarms.ProximityTrigger.LocationAccuracy = .nearestTenMeters
    ) {
        self.geofenceRadius = geofenceRadius
        self.locationAccuracy = locationAccuracy
    }

    /// Calculate distance between two coordinates
    public func distance(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }

    /// Check if location is within region
    public func isLocation(
        _ location: CLLocationCoordinate2D,
        withinRegion region: ICalProximityAlarms.GeographicRegion
    ) -> Bool {
        let distance = self.distance(from: location, to: region.center)
        return distance <= region.radiusInMeters
    }

    /// Evaluate proximity conditions
    public func evaluateConditions(
        _ conditions: [ICalProximityAlarms.ProximityCondition],
        context: [String: Any]
    ) -> Bool {
        for condition in conditions {
            guard let contextValue = context[condition.type.rawValue] else {
                return false
            }

            let satisfied = evaluateCondition(condition, contextValue: contextValue)
            if !satisfied {
                return false
            }
        }
        return true
    }

    private func evaluateCondition(
        _ condition: ICalProximityAlarms.ProximityCondition,
        contextValue: Any
    ) -> Bool {
        let stringValue = String(describing: contextValue)
        let conditionValue = condition.value

        switch condition.`operator` {
        case .equals:
            return stringValue == conditionValue
        case .notEquals:
            return stringValue != conditionValue
        case .contains:
            return stringValue.contains(conditionValue)
        case .notContains:
            return !stringValue.contains(conditionValue)
        case .greaterThan:
            if let numValue = Double(stringValue), let condValue = Double(conditionValue) {
                return numValue > condValue
            }
            return false
        case .lessThan:
            if let numValue = Double(stringValue), let condValue = Double(conditionValue) {
                return numValue < condValue
            }
            return false
        case .greaterThanOrEqual:
            if let numValue = Double(stringValue), let condValue = Double(conditionValue) {
                return numValue >= condValue
            }
            return false
        case .lessThanOrEqual:
            if let numValue = Double(stringValue), let condValue = Double(conditionValue) {
                return numValue <= condValue
            }
            return false
        }
    }

    /// Estimate travel time between locations
    public func estimateTravelTime(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D,
        transportationType: ICalProximityAlarms.LocationTrigger.TransportationType = .automobile
    ) -> ICalProximityAlarms.TravelTimeEstimation {
        let distance = self.distance(from: from, to: to)

        // Simplified travel time estimation
        let baseSpeed: Double  // meters per second
        switch transportationType {
        case .walking:
            baseSpeed = 1.4  // ~5 km/h
        case .bicycle:
            baseSpeed = 4.17  // ~15 km/h
        case .automobile:
            baseSpeed = 13.89  // ~50 km/h
        case .transit:
            baseSpeed = 8.33  // ~30 km/h
        case .any:
            baseSpeed = 10.0  // mixed average
        }

        let estimatedDuration = distance / baseSpeed

        // Add traffic buffer for automobile
        let withTraffic = transportationType == .automobile ? estimatedDuration * 1.3 : nil

        return ICalProximityAlarms.TravelTimeEstimation(
            distance: distance,
            estimatedDuration: estimatedDuration,
            withTraffic: withTraffic,
            transportationType: transportationType
        )
    }

    /// Generate geofence regions from proximity alarms
    public func generateGeofenceRegions(
        from alarms: [ICalProximityAlarms.ProximityAlarm]
    ) -> [CLCircularRegion] {
        alarms.compactMap { alarm in
            let region = CLCircularRegion(
                center: alarm.region.center,
                radius: alarm.region.radiusInMeters,
                identifier: alarm.id
            )

            switch alarm.proximityType {
            case .entering, .within, .approaching:
                region.notifyOnEntry = true
                region.notifyOnExit = false
            case .leaving, .outside, .moving_away:
                region.notifyOnEntry = false
                region.notifyOnExit = true
            }

            return region
        }
    }

    /// Create location-based reminder
    public func createLocationBasedReminder(
        for event: ICalEvent,
        region: ICalProximityAlarms.GeographicRegion,
        proximityType: ICalProximityAlarms.ProximityType = .entering,
        leadTime: TimeInterval = 900  // 15 minutes
    ) -> ICalAlarm {
        var alarm = ICalAlarm()
        alarm.action = .display
        alarm.trigger = "-PT\(Int(leadTime))S"

        // Add proximity metadata
        alarm.setPropertyValue("X-PROXIMITY-REGION-ID", value: region.id)
        alarm.setPropertyValue("X-PROXIMITY-TYPE", value: proximityType.rawValue)
        alarm.setPropertyValue("X-PROXIMITY-LATITUDE", value: String(region.center.latitude))
        alarm.setPropertyValue("X-PROXIMITY-LONGITUDE", value: String(region.center.longitude))
        alarm.setPropertyValue("X-PROXIMITY-RADIUS", value: String(region.radius))
        alarm.setPropertyValue("X-PROXIMITY-UNIT", value: region.unit.rawValue)

        if let regionName = region.name {
            alarm.description = "Reminder: \(event.summary ?? "Event") when \(proximityType.rawValue.lowercased()) \(regionName)"
        } else {
            alarm.description = "Location-based reminder for \(event.summary ?? "Event")"
        }

        return alarm
    }

    /// Create travel time alarm
    public func createTravelTimeAlarm(
        for event: ICalEvent,
        from: CLLocationCoordinate2D,
        transportationType: ICalProximityAlarms.LocationTrigger.TransportationType = .automobile,
        bufferTime: TimeInterval = 600  // 10 minutes
    ) -> ICalAlarm? {
        guard let eventLocation = event.location,
            let _ = event.dateTimeStart
        else {
            return nil
        }

        // For this example, we'll use a simple coordinate parsing
        // In a real implementation, you'd want proper geocoding
        let coordinates = eventLocation.split(separator: ",")
        guard coordinates.count >= 2,
            let lat = Double(coordinates[0].trimmingCharacters(in: .whitespaces)),
            let lon = Double(coordinates[1].trimmingCharacters(in: .whitespaces))
        else {
            return nil
        }

        let to = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let travelEstimation = estimateTravelTime(from: from, to: to, transportationType: transportationType)

        let totalTravelTime = (travelEstimation.withTraffic ?? travelEstimation.estimatedDuration) + bufferTime

        var alarm = ICalAlarm()
        alarm.action = .display
        alarm.trigger = "-PT\(Int(totalTravelTime))S"
        alarm.description =
            "Time to leave for \(event.summary ?? "Event") (estimated travel time: \(Int(travelEstimation.estimatedDuration / 60)) minutes)"

        // Add travel metadata
        alarm.setPropertyValue("X-TRAVEL-FROM-LAT", value: String(from.latitude))
        alarm.setPropertyValue("X-TRAVEL-FROM-LON", value: String(from.longitude))
        alarm.setPropertyValue("X-TRAVEL-TO-LAT", value: String(to.latitude))
        alarm.setPropertyValue("X-TRAVEL-TO-LON", value: String(to.longitude))
        alarm.setPropertyValue("X-TRAVEL-TRANSPORT", value: transportationType.rawValue)
        alarm.setPropertyValue("X-TRAVEL-DISTANCE", value: String(travelEstimation.distance))
        alarm.setPropertyValue("X-TRAVEL-DURATION", value: String(travelEstimation.estimatedDuration))

        return alarm
    }
}

// MARK: - Extensions for Proximity Alarm Support

extension ICalEvent {
    /// Add proximity alarm to event
    public mutating func addProximityAlarm(_ alarm: ICalProximityAlarms.ProximityAlarm) {
        let icalAlarm = ICalProximityAlarmManager().createLocationBasedReminder(
            for: self,
            region: alarm.region,
            proximityType: alarm.proximityType
        )

        alarms.append(icalAlarm)

        // Add proximity metadata to event
        setPropertyValue("X-HAS-PROXIMITY-ALARMS", value: "TRUE")

        let existingAlarmIds = getPropertyValue("X-PROXIMITY-ALARM-IDS") ?? ""
        let updatedIds = existingAlarmIds.isEmpty ? alarm.id : "\(existingAlarmIds),\(alarm.id)"
        setPropertyValue("X-PROXIMITY-ALARM-IDS", value: updatedIds)
    }

    /// Get proximity alarms for event
    public var proximityAlarmIds: [String] {
        guard let idsString = getPropertyValue("X-PROXIMITY-ALARM-IDS") else { return [] }
        return idsString.split(separator: ",").map(String.init)
    }

    /// Check if event has proximity alarms
    public var hasProximityAlarms: Bool {
        getPropertyValue("X-HAS-PROXIMITY-ALARMS") == "TRUE"
    }

    /// Set location-based scheduling
    public mutating func setLocationBasedScheduling(_ schedule: ICalProximityAlarms.LocationBasedSchedule) {
        setPropertyValue("X-LOCATION-SCHEDULING-ID", value: schedule.id)
        setPropertyValue("X-AUTO-ADJUST-TRAFFIC", value: schedule.autoAdjustForTraffic ? "TRUE" : "FALSE")

        if let bufferTime = schedule.travelTimeBuffer {
            setPropertyValue("X-TRAVEL-BUFFER-TIME", value: String(bufferTime))
        }

        // Store location triggers
        for (index, trigger) in schedule.locationTriggers.enumerated() {
            let prefix = "X-LOCATION-TRIGGER-\(index)"
            setPropertyValue("\(prefix)-TO-LAT", value: String(trigger.toLocation.latitude))
            setPropertyValue("\(prefix)-TO-LON", value: String(trigger.toLocation.longitude))
            setPropertyValue("\(prefix)-TRANSPORT", value: trigger.transportationType.rawValue)
            setPropertyValue("\(prefix)-ADJUSTMENT", value: trigger.adjustmentType.rawValue)

            if let fromLocation = trigger.fromLocation {
                setPropertyValue("\(prefix)-FROM-LAT", value: String(fromLocation.latitude))
                setPropertyValue("\(prefix)-FROM-LON", value: String(fromLocation.longitude))
            }
        }
    }
}

extension ICalAlarm {
    /// Check if alarm is proximity-based
    public var isProximityAlarm: Bool {
        getPropertyValue("X-PROXIMITY-REGION-ID") != nil
    }

    /// Get proximity region ID
    public var proximityRegionId: String? {
        getPropertyValue("X-PROXIMITY-REGION-ID")
    }

    /// Get proximity type
    public var proximityType: ICalProximityAlarms.ProximityType? {
        guard let value = getPropertyValue("X-PROXIMITY-TYPE") else { return nil }
        return ICalProximityAlarms.ProximityType(rawValue: value)
    }

    /// Check if alarm is travel time based
    public var isTravelTimeAlarm: Bool {
        getPropertyValue("X-TRAVEL-FROM-LAT") != nil
    }

    /// Get travel time metadata
    public var travelTimeMetadata:
        (from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, transportationType: ICalProximityAlarms.LocationTrigger.TransportationType)?
    {
        guard let fromLatStr = getPropertyValue("X-TRAVEL-FROM-LAT"),
            let fromLonStr = getPropertyValue("X-TRAVEL-FROM-LON"),
            let toLatStr = getPropertyValue("X-TRAVEL-TO-LAT"),
            let toLonStr = getPropertyValue("X-TRAVEL-TO-LON"),
            let transportStr = getPropertyValue("X-TRAVEL-TRANSPORT"),
            let fromLat = Double(fromLatStr),
            let fromLon = Double(fromLonStr),
            let toLat = Double(toLatStr),
            let toLon = Double(toLonStr),
            let transport = ICalProximityAlarms.LocationTrigger.TransportationType(rawValue: transportStr)
        else {
            return nil
        }

        let from = CLLocationCoordinate2D(latitude: fromLat, longitude: fromLon)
        let to = CLLocationCoordinate2D(latitude: toLat, longitude: toLon)

        return (from: from, to: to, transportationType: transport)
    }
}

// MARK: - CLLocationCoordinate2D Extensions

extension CLLocationCoordinate2D: @retroactive Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension CLLocationCoordinate2D: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}
