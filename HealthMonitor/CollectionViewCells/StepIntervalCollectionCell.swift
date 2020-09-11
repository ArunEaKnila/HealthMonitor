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
    @IBOutlet weak var stepsBgView: UIView!
    
    func configure(_ stepsText: String, isToday: Bool = false) {
        self.stepsLabel.text = stepsText
        stepsBgView.backgroundColor = isToday ? #colorLiteral(red: 0.3449999988, green: 0.3370000124, blue: 0.8389999866, alpha: 1) : #colorLiteral(red: 0.6859999895, green: 0.3219999969, blue: 0.8709999919, alpha: 1)
    }
}
