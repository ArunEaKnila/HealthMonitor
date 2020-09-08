//
//  LocalStorageManager.swift
//  HealthMonitor
//
//  Created by apple on 08/09/20.
//  Copyright © 2020 knila. All rights reserved.
//

import Foundation

struct StorageManager {
    private static let defaults = UserDefaults.standard
    
    static var deviceToken: String {
        get {
            return defaults.string(forKey: "deviceToken") ?? ""
        }
        set {
            defaults.set(newValue, forKey: "deviceToken")
        }
    }
    
    static var hasRegisteredAPNS: Bool {
        return !deviceToken.isEmpty
    }
}
