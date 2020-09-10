//
//  TimeIntervalManager.swift
//  HealthMonitor
//
//  Created by apple on 10/09/20.
//  Copyright © 2020 knila. All rights reserved.
//

import Foundation

struct TimeIntervalManager {
    static let shared = TimeIntervalManager()
    let calendar = Calendar.current
    
    var timeInterval: TimeInterval = 45 * 60
    var wakeTime: Date {
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 8
        components.minute = 30
        
        return calendar.date(from: components) ?? Date()
    }
    
    var bedTime: Date {
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 21
        components.minute = 30
        
        return calendar.date(from: components) ?? Date()
    }
    
    func getTimeIntervals() -> [String] {
        var iterDate = wakeTime
        var timeIntervals = [String]()
        
        while iterDate < bedTime {
            timeIntervals.append(iterDate.time)
            
            iterDate = iterDate.addingTimeInterval(timeInterval)
        }
        
        return timeIntervals
    }
}

private extension Date {
    var time: String {
        get {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            
            return formatter.string(from: self)
        }
    }
}
