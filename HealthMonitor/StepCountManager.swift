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

class StepCountManager {
    static let shared = StepCountManager()
    
    private init() {}
    
    private let defaults = UserDefaults.standard
    private let hkStore = HKHealthStore()
    private let timeIntervalToCheck: TimeInterval = 60 * 60
    private let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
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
}
