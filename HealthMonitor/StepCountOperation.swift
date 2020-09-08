//
//  StepCountOperation.swift
//  HealthMonitor
//
//  Created by apple on 07/09/20.
//  Copyright © 2020 knila. All rights reserved.
//

import Foundation
import BackgroundTasks

class StepCountManager {
    static let shared = StepCountManager()
    
    private init() {}
    
    private let defaults = UserDefaults.standard
    private let timeIntervalToCheck: TimeInterval = 10 * 60
    
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
            return 0
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
        } catch {
            print(error)
        }
    }
}
