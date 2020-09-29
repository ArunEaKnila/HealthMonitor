//
//  HealthListController.swift
//  WatchMonitor WatchKit Extension
//
//  Created by apple on 28/09/20.
//  Copyright © 2020 Knila IT Solutions. All rights reserved.
//

import WatchKit
import Foundation


class HealthListController: WKInterfaceController {
    @IBOutlet weak var healthInfoTable: WKInterfaceTable!
    
    private var activityValues: [ActivityType: String]?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        self.activityValues = context as? [ActivityType: String]
        self.refreshTable()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    private func refreshTable() {
        guard let activityValues = self.activityValues else {
            return
        }
        
        healthInfoTable.setNumberOfRows(activityValues.count, withRowType: "healthInfo")
        
        for idx in 0 ..< healthInfoTable.numberOfRows {
            guard let row = healthInfoTable.rowController(at: idx) as? HealthInfoRowController else {
                break
            }
            
            let activity = activityValues[idx]
            row.healthInfoLabel.setText(activity.key.titleLabel)
            row.valueLabel.setText(activity.value + " " + activity.key.subTitleLabel)
            row.sideImageView.setImage(UIImage(named: activity.key.imageName))
        }
    }
}
