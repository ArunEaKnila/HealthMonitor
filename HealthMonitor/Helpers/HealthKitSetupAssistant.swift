import HealthKit

enum HealthkitSetupError: Error {
    case notAvailableOnDevice
    case stepCountNotSupported
    case heartRateNotSupported
    case distanceNotSupported
}

enum ActivityType: CaseIterable {
    case stepCount, heartRate, walkingDistance
    
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
        }
    }
    
    var option: HKStatisticsOptions {
        switch self {
        case .stepCount:
            return .cumulativeSum
        case .heartRate:
            return .discreteAverage
        case .walkingDistance:
            return .cumulativeSum
        }
    }
    
    var unit: HKUnit {
        switch self {
        case .stepCount:
            return HKUnit.count()
        case .heartRate:
            return HKUnit.count().unitDivided(by: HKUnit.minute())
        case .walkingDistance:
            return HKUnit.mile()
        }
    }
    
    func value(forStatistics statistics: HKStatistics?) -> Double? {
        switch self {
        case .stepCount:
            return statistics?.sumQuantity()?.doubleValue(for: self.unit)
        case .heartRate:
            return statistics?.averageQuantity()?.doubleValue(for: self.unit)
        case .walkingDistance:
            return statistics?.sumQuantity()?.doubleValue(for: self.unit)
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
        }
    }
    
    func formatValue(_ value: Double) -> String {
        switch self {
        case .stepCount:
            return String(format: "%.0f", value)
        case .heartRate:
            return String(format: "%.1f", value)
        case .walkingDistance:
            return String(format: "%.2f", value)
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
