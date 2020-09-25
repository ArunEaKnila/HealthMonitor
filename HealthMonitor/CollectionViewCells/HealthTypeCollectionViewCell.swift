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
    }
    
    private var shadowLayer: CAShapeLayer!
    private var cornerRadius: CGFloat = 25.0
    private var fillColor: UIColor = .blue // the color applied to the shadowLayer, rather than the view's backgroundColor
     
    override func layoutSubviews() {
        super.layoutSubviews()

        if hasSet == false {
            self.contentView.layer.cornerRadius = 10.0
            self.contentView.layer.borderWidth = 0.3
            self.contentView.layer.borderColor = UIColor.clear.cgColor
            self.contentView.layer.masksToBounds = false

            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            self.layer.shadowRadius = 2.0
            self.layer.shadowOpacity = 0.2
            self.layer.masksToBounds = false
            self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.contentView.layer.cornerRadius).cgPath
            
            hasSet = true
        }
    }
}
