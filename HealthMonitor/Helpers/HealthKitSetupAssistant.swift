import HealthKit

enum HealthkitSetupError: Error {
    case notAvailableOnDevice
    case stepCountNotSupported
    case heartRateNotSupported
    case distanceNotSupported
    case flightNotSupported
    case cyclingNotSupported
    case caloriesNotSupported
}

enum ActivityType: CaseIterable {
    case stepCount, heartRate, walkingDistance, flightsClimbed, cycling, caloriesBurned
    
    static let cases = [heartRate, walkingDistance, flightsClimbed, cycling, .caloriesBurned]
    
    static let supportedTypes: Set<HKObjectType> = {
        var objectSet = Set<HKObjectType>()
        
        for type in ActivityType.allCases {
            if let type = type.sampleType {
                objectSet.insert(type)
            }
        }
        
        return objectSet
    }()
        
    var error: HealthkitSetupError {
        switch self {
        case .stepCount:
            return .stepCountNotSupported
        case .heartRate:
            return .heartRateNotSupported
        case .walkingDistance:
            return .distanceNotSupported
        case .flightsClimbed:
            return .flightNotSupported
        case .cycling:
            return .cyclingNotSupported
        case .caloriesBurned:
            return .caloriesNotSupported
        }
    }
    
    var sampleType: HKQuantityType? {
        switch self {
        case .stepCount:
            return HKObjectType.quantityType(forIdentifier: .stepCount)
        case .heartRate:
            return HKObjectType.quantityType(forIdentifier: .heartRate)
        case .walkingDistance:
            return HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)
        case .flightsClimbed:
            return HKObjectType.quantityType(forIdentifier: .flightsClimbed)
        case .cycling:
            return HKObjectType.quantityType(forIdentifier: .distanceCycling)
        case .caloriesBurned:
            return HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        }
    }
    
    var option: HKStatisticsOptions {
        switch self {
        case .stepCount, .walkingDistance, .flightsClimbed, .cycling, .caloriesBurned:
            return .cumulativeSum
        case .heartRate:
            return .discreteAverage
        }
    }
    
    var unit: HKUnit {
        switch self {
        case .stepCount, .flightsClimbed:
            return HKUnit.count()
        case .heartRate:
            return HKUnit.count().unitDivided(by: HKUnit.minute())
        case .walkingDistance, .cycling:
            return .mile()
        case .caloriesBurned:
            return .kilocalorie()
        }
    }
    
    func value(forStatistics statistics: HKStatistics?) -> Double? {
        switch self {
        case .stepCount, .walkingDistance, .flightsClimbed, .cycling, .caloriesBurned:
            return statistics?.sumQuantity()?.doubleValue(for: self.unit)
        case .heartRate:
            return statistics?.averageQuantity()?.doubleValue(for: self.unit)
        }
    }
    
    var titleLabel: String {
        switch self {
        case .stepCount:
            return "TOTAL STEPS"
        case .heartRate:
            return "HEART RATE"
        case .walkingDistance:
            return "DISTANCE"
        case .flightsClimbed:
            return "FLIGHTS CLIMBED"
        case .cycling:
            return "CYCLING"
        case .caloriesBurned:
            return "CALORIES BURNED"
        }
    }
    
    var subTitleLabel: String {
        switch self {
        case .stepCount:
            return "STEPS"
        case .heartRate:
            return "BPM"
        case .walkingDistance:
            return "MILES"
        case .flightsClimbed:
            return "FLIGHTS"
        case .cycling:
            return "MILES"
        case .caloriesBurned:
            return "KCAL"
        }
    }
    
    func formatValue(_ value: Double) -> String {
        switch self {
        case .stepCount, .heartRate, .flightsClimbed:
            return String(format: "%.0f", value)
        case .walkingDistance, .cycling, .caloriesBurned:
            return String(format: "%.1f", value)
        }
    }
}

class HealthKitSetupAssistant {
    class func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
        
        //1. Check to see if HealthKit Is Available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthkitSetupError.notAvailableOnDevice)
            return
        }
        
        //4. Request Authorization
        HKHealthStore().requestAuthorization(toShare: nil,
                                             read: ActivityType.supportedTypes) { (success, error) in
                                                completion(success, error)
        }
    }
}
