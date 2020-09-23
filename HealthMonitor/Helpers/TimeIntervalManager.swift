//
//  TimeIntervalManager.swift
//  HealthMonitor
//
//  Created by apple on 10/09/20.
//  Copyright © 2020 knila. All rights reserved.
//

import Foundation

class TimeIntervalManager {
    static let shared = TimeIntervalManager()
    
    private init() {}
    
    let calendar = Calendar.current
    
    var timeInterval: TimeInterval = 45 * 60 {
        didSet {
            NotificationCenter.default.post(name: .intervalChanged, object: self)
        }
    }
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
        
        // Add bed time if last interval is less than bedTime
        if iterDate >= bedTime {
            timeIntervals.append(bedTime.time)
        }
        
        return timeIntervals
    }
    
    func getWakeAndBedTimeAsDate(_ anchorDate: Date) -> (wakeTime: Date, bedTime: Date) {
        var wakeComponents = calendar.dateComponents([.year, .month, .day], from: anchorDate)
        let wakeTime = calendar.dateComponents([.hour, .minute], from: self.wakeTime)
        wakeComponents.hour = wakeTime.hour
        wakeComponents.minute = wakeTime.minute
        
        let wakeDate = calendar.date(from: wakeComponents)
        
        let bedTime = calendar.dateComponents([.hour, .minute], from: self.bedTime)
        wakeComponents.hour = bedTime.hour
        wakeComponents.minute = bedTime.minute
        
        let bedDate = calendar.date(from: wakeComponents)
        
        return (wakeDate ?? Date(), bedDate ?? Date())
    }
    
    func isDateInRange(_ startDate: Date) -> Bool {
        let now = Date()
        let addedDate = startDate.addingTimeInterval(timeInterval)
        
        return now > startDate && now <= addedDate
    }
    
    func chooseIntervalData(_ hour: Int = 0) -> (hours: [Int], minutes: [Int]) {
        if hour == 0 {
            return ([0, 1, 2, 3, 4, 5], [45])
        }
        else {
            return ([0, 1, 2, 3, 4, 5], [0, 15, 30, 45])
        }
    }
}

extension TimeInterval {
    func components() -> DateComponents {
        let sysCalendar = Calendar.current
        let date1 = Date()
        let date2 = Date(timeInterval: self, since: date1)
        
        return sysCalendar.dateComponents([.hour, .minute], from: date1, to: date2)
    }
    
    var displayString: String {
        let components = self.components()
        
        var value = ""
        if let hour = components.hour, hour > 0 {
            value += components.hour == 1 ? "\(hour) hour" : "\(hour) hours"
            
            if let minute = components.minute, minute > 0 {
                value += " and \(minute) minutes"
            }
        }
        else if let minute = components.minute, minute > 0 {
            value += "\(minute) minutes"
        }
        
        return value
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
    
    func byReducingInterval(_ timeInterval: TimeInterval) -> Date {
        let calendar = Calendar.current
        let components = timeInterval.components()
        
        var newDate = calendar.date(byAdding:.hour, value: -(components.hour ?? 0), to: self)
        newDate = calendar.date(byAdding:.minute, value: -(components.minute ?? 0), to: self)
        
        return newDate ?? self
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
