//
//  StepCountManager.swift
//  HealthMonitor
//
//  Created by apple on 07/09/20.
//  Copyright © 2020 knila. All rights reserved.
//

import Foundation
import HealthKit
import BackgroundTasks
import UserNotifications

class HealthKitDataFetcher {
    static let shared = HealthKitDataFetcher()
    
    private init() {}
    
    private let defaults = UserDefaults.standard
    private let hkStore = HKHealthStore()
    private let timeIntervalToCheck: TimeInterval = 60 * 60
    private let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private let timeManager = TimeIntervalManager.shared
    private var stepsCompletion: (([HKSample]?) -> ())?
        
    var backgroundTask: BGAppRefreshTask?
    
    var lastCheckedTime: Date {
        get {
            let timeInterval = defaults.double(forKey: "lastCheckedTime")
            return Date(timeIntervalSinceReferenceDate: timeInterval)
        }
        set {
            let timeInterval = newValue.timeIntervalSinceReferenceDate
            defaults.set(timeInterval, forKey: "lastCheckedTime")
        }
    }
    
    private var scheduleTime: TimeInterval {
        let timeDiff = Date().timeIntervalSinceReferenceDate - lastCheckedTime.timeIntervalSinceReferenceDate
        if timeDiff >= timeIntervalToCheck || timeDiff < 0 {
            return 5
        }
        else {
            return timeIntervalToCheck - timeDiff
        }
    }
    
    func scheduleAppRefresh() {
        do {
            let request = BGAppRefreshTaskRequest(identifier: "com.knila.HealthMonitor.checkSteps")
            request.earliestBeginDate = Date(timeIntervalSinceNow: scheduleTime)
            try BGTaskScheduler.shared.submit(request)
            
            print("Scheduled a step check \(scheduleTime) seconds from now")
        } catch {
            print("Unable to submit task: \(error.localizedDescription)")
        }
    }
    
    func getStepsFromLastChecked(_ task: BGTask) {
        let oneHourAgo = Date().addingTimeInterval(-timeIntervalToCheck)
        let lastHourPredicate = NSPredicate(format: "endDate > %@", oneHourAgo as NSDate)
        
        let stepsSampleQuery = HKSampleQuery(
                sampleType: stepsType,
                predicate: lastHourPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil,
                resultsHandler: { [weak self] (query, samples, error) in
                    self?.stepsSampleQueryFinished(samples: samples)
            })
        hkStore.execute(stepsSampleQuery)
    }
    
    func getSteps(_ completion: @escaping ([HKSample]?) -> ()) {
        let oneHourAgo = Date().addingTimeInterval(-timeIntervalToCheck)
        let lastHourPredicate = NSPredicate(format: "endDate > %@", oneHourAgo as NSDate)
        
        let stepsSampleQuery = HKSampleQuery(
                sampleType: stepsType,
                predicate: lastHourPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil,
                resultsHandler: { [weak self] (query, samples, error) in
                    self?.stepsSampleQueryFinished(samples: samples)
            })
        hkStore.execute(stepsSampleQuery)
        
        self.stepsCompletion = completion
    }

    func stepsSampleQueryFinished(samples: [HKSample]?) {
        
        samples?.forEach({ (sample) in
            guard let sample = sample as? HKQuantitySample else {
                return
            }
            
            print("SAMPLE DETAILS \(sample.quantity) \(sample.sampleType) at \(sample.endDate)")
        })
        
        print("stepsSampleQueryFinished hi")
        self.lastCheckedTime = Date()
//        scheduleNotification("From Background")
//        scheduleAppRefresh()
        
        stepsCompletion?(samples)
    }
    
    func scheduleNotification(_ message: String) {
        let content = UNMutableNotificationContent()

        content.title = "Yay"
        content.body = message
        content.categoryIdentifier = "CALLINNOTIFICATION"
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1, repeats: false)
        let identifier = "id_Title"
        let request = UNNotificationRequest.init(identifier: identifier, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            print("Error in scheduling noti ", error?.localizedDescription ?? "")
        }
        
        self.backgroundTask?.setTaskCompleted(success: true)
    }
    
    func getStepsForEachHour(_ date: Date, _ completion: @escaping ([String]) -> Void) {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            fatalError("*** Unable to get the step count type ***")
        }
        
        let calendar = Calendar.current
        let interval = timeManager.timeInterval.components()
        let (wakeTime, bedTime) = timeManager.getWakeAndBedTimeAsDate(date)
        let anchorDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date)
     
        let query = HKStatisticsCollectionQuery.init(quantityType: stepCountType,
                                                     quantitySamplePredicate: nil,
                                                     options: .cumulativeSum,
                                                     anchorDate: anchorDate!,
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
        
        let calendar = Calendar.current
        let interval = timeManager.timeInterval.components()
        let (wakeTime, bedTime) = timeManager.getWakeAndBedTimeAsDate(date)
        let anchorDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date)
     
        let query = HKStatisticsCollectionQuery.init(quantityType: heartRateType,
                                                     quantitySamplePredicate: nil,
                                                     options: .discreteAverage,
                                                     anchorDate: anchorDate!,
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
}
