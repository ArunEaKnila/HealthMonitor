//
//  StepIntervalCollectionCell.swift
//  HealthMonitor
//
//  Created by apple on 10/09/20.
//  Copyright © 2020 knila. All rights reserved.
//

import UIKit

class StepIntervalCollectionCell: UICollectionViewCell {
    @IBOutlet weak var stepsLabel: UILabel!
    
    func configure(_ stepsText: String) {
        self.stepsLabel.text = stepsText
    }
}
