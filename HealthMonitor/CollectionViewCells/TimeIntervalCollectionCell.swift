//
//  TimeIntervalCollectionCell.swift
//  HealthMonitor
//
//  Created by apple on 10/09/20.
//  Copyright © 2020 knila. All rights reserved.
//

import UIKit

class TimeIntervalCollectionCell: UICollectionViewCell {
    @IBOutlet weak var timeLabel: UILabel!
    
    func configure(_ timeText: String) {
        self.timeLabel.text = timeText
    }
}
