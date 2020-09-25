//
//  ActivityDataSource.swift
//  HealthMonitor
//
//  Created by apple on 25/09/20.
//  Copyright © 2020 Knila IT Solutions. All rights reserved.
//

import Foundation

class ActivityDataSource {
    static let shared = ActivityDataSource()
    
    private init() {}
    
    func fetchDataForAllTypes(_ date: Date, _ completion: @escaping ([ActivityType: String])->Void) {
        let group = DispatchGroup()
        var activityValues = [ActivityType: String]()

        ActivityType.allCases.forEach { (type) in
            group.enter()
            
            print("Entered for loop for type \(type.titleLabel)")
            
            HealthKitDataFetcher.shared.getData(forType: type, andDate: date, options: type.option) { (value, type) in
                print("Fetched value for type \(type.titleLabel) value : \(type.formatValue(value))")
                
                DispatchQueue.main.async {
                    activityValues[type] = type.formatValue(value)
                }
                
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            completion(activityValues)
        }
    }
}
