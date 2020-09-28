//
//  StepCountManager.swift
//  HealthMonitor
//
//  Created by apple on 07/09/20.
//  Copyright © 2020 knila. All rights reserved.
//

import Foundation
import HealthKit
import UserNotifications

class HealthKitDataFetcher {
    static let shared = HealthKitDataFetcher()
    
    private init() {}
    
    private let defaults = UserDefaults.standard
    private let hkStore = HKHealthStore()
    private let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private let timeManager = TimeIntervalManager.shared
    
    func getStepsForLastInterval(_ completion: @escaping (Int) -> Void) {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            fatalError("*** Unable to get the step count type ***")
        }
        
        let interval = timeManager.timeInterval.components()
        let endTime = Date()
        let startTime = endTime.byReducingInterval(timeManager.timeInterval)
     
        let query = HKStatisticsCollectionQuery.init(quantityType: stepCountType,
                                                     quantitySamplePredicate: nil,
                                                     options: .cumulativeSum,
                                                     anchorDate: startTime,
                                                     intervalComponents: interval)
                
        query.initialResultsHandler = {
            query, results, error in
                 
            results?.enumerateStatistics(from: startTime,
                                         to: endTime, with: { (result, stop) in
                                            let count = result.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                                            completion(Int(count))
                })
        }
        
        hkStore.execute(query)
    }
    
    func getStepsForEachHour(_ date: Date, _ completion: @escaping ([String]) -> Void) {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            fatalError("*** Unable to get the step count type ***")
        }
        
        let interval = timeManager.timeInterval.components()
        let (wakeTime, bedTime) = timeManager.getWakeAndBedTimeAsDate(date)
     
        let query = HKStatisticsCollectionQuery.init(quantityType: stepCountType,
                                                     quantitySamplePredicate: nil,
                                                     options: .cumulativeSum,
                                                     anchorDate: wakeTime,
                                                     intervalComponents: interval)
        
        var stepsCount = [String]()
        
        query.initialResultsHandler = {
            query, results, error in
                 
            results?.enumerateStatistics(from: wakeTime,
                                         to: bedTime, with: { (result, stop) in
                                            stepsCount.append("\(result.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0)")
                                            
                                            if result.endDate > bedTime {
                                                completion(stepsCount)
                                            }
                })
        }
        
        hkStore.execute(query)
    }
    
    func getHeartRateForEachHour(_ date: Date, _ completion: @escaping ([Int]) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            fatalError("*** Unable to get the heart rate count type ***")
        }
        
        let interval = timeManager.timeInterval.components()
        let (wakeTime, bedTime) = timeManager.getWakeAndBedTimeAsDate(date)
     
        let query = HKStatisticsCollectionQuery.init(quantityType: heartRateType,
                                                     quantitySamplePredicate: nil,
                                                     options: .discreteAverage,
                                                     anchorDate: wakeTime,
                                                     intervalComponents: interval)
        
        var heartRateCount = [Int]()
        
        query.initialResultsHandler = {
            query, results, error in
                 
            results?.enumerateStatistics(from: wakeTime,
                                         to: bedTime, with: { (result, stop) in
                                            let beats: Double = result.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) ?? 0
                                            heartRateCount.append(Int(beats))
                                            
                                            if result.endDate > bedTime {
                                                completion(heartRateCount)
                                            }
                })
        }
        
        hkStore.execute(query)
    }
    
    func getFullDistance(_ date: Date, _ completion: @escaping (Double) -> Void) {
        guard let type = HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            fatalError("*** Unable to get the walking / running type ***")
        }
        let (wakeTime, bedTime) = timeManager.getWakeAndBedTimeAsDate(date)

        let predicate = HKQuery.predicateForSamples(withStart: wakeTime, end: bedTime, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: [.cumulativeSum]) { (query, statistics, error) in
            var value: Double = 0

            if error != nil {
                print("HealthKit error \(error.debugDescription)")
            } else if let quantity = statistics?.sumQuantity() {
                value = quantity.doubleValue(for: HKUnit.mile())
            }
            
            DispatchQueue.main.async {
                completion(value)
            }
        }
        
        hkStore.execute(query)
    }
    
    func getData(forType type: ActivityType, andDate date: Date, options: HKStatisticsOptions = .cumulativeSum, _ completion: @escaping (Double, ActivityType) -> Void) {
        guard let sampleType = type.sampleType else {
            fatalError("*** Unable to get the walking / running type ***")
        }
        let (wakeTime, bedTime) = timeManager.getWakeAndBedTimeAsDate(date)

        let predicate = HKQuery.predicateForSamples(withStart: wakeTime, end: bedTime, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: sampleType, quantitySamplePredicate: predicate, options: [options]) { (query, statistics, error) in
            var value: Double = 0

            if error != nil {
                print("HealthKit error \(error.debugDescription)")
            } else if let quantity = type.value(forStatistics: statistics) {
                value = quantity
            }
            
            DispatchQueue.main.async {
                completion(value, type)
            }
        }
        
        hkStore.execute(query)
    }
}

class StepsModel {
    internal init(intervalStartTime: String? = nil, stepsCount: Int? = nil, heartRate: Int? = nil) {
        self.intervalStartTime = intervalStartTime
        self.stepsCount = stepsCount
        self.heartRate = heartRate
    }
    
    var intervalStartTime: String?
    var stepsCount: Int?
    var heartRate: Int?
}
