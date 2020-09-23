//
//  Extensions.swift
//  HealthMonitor
//
//  Created by apple on 23/09/20.
//  Copyright © 2020 Knila IT Solutions. All rights reserved.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
