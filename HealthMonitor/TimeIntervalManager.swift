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
        components.hour = 9
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
    
    func isDateInRange(_ date: Date) -> Bool {
        let now = Date()
        let addedDate = now.addingTimeInterval(timeInterval)
        
        return date > now && date <= addedDate
    }
}

extension Date {
    var time: String {
        get {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            
            return formatter.string(from: self)
        }
    }
}

extension String {
    var date: Date? {
        get {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            let timeDate = formatter.date(from: self) ?? Date()
            
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: timeDate)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            
            return Calendar.current.date(from: components)
        }
    }
}
