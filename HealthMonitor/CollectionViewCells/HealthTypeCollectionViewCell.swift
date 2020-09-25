//
//  HealthTypeCollectionViewCell.swift
//  HealthMonitor
//
//  Created by apple on 25/09/20.
//  Copyright © 2020 Knila IT Solutions. All rights reserved.
//

import UIKit

class HealthTypeCollectionViewCell: UICollectionViewCell {
    static let reuseId = "HealthTypeCollectionViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var unitsLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    private var hasSet: Bool  = false
    
    func configure(title: String, value: String, units: String) {
        titleLabel.text = title
        valueLabel.text = value
        unitsLabel.text = units
        
        setShadow()
    }
    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//
//        setShadow()
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//
//        setShadow()
//    }
    
    private func setShadow() {
        if hasSet { return }
        
        containerView.layer.backgroundColor = UIColor.clear.cgColor
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowRadius = 4.0
        
        hasSet = true
    }
}
