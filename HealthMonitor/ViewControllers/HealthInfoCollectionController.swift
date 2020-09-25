//
//  HealthInfoCollectionController.swift
//  HealthMonitor
//
//  Created by apple on 24/09/20.
//  Copyright © 2020 Knila IT Solutions. All rights reserved.
//

import UIKit

protocol CollectionControllerDelegate: UIViewController {
    func reloadData()
}

class HealthInfoCollectionController: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private let itemsPerRow: CGFloat = 1.5
    
    init(_ controller: CollectionControllerDelegate) {
        super.init()
        
        self.controller = controller
    }
    
    weak var controller: CollectionControllerDelegate?
    
    var displayDate: Date = Date() {
        didSet {
            ActivityDataSource.shared.fetchDataForAllTypes(self.displayDate) { [weak self] (activityValues) in
                self?.activityValues = activityValues
                
                self?.controller?.reloadData()
            }
        }
    }
    
    private var activityTypes = ActivityType.allCases
    private var activityValues: [ActivityType: String]?
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return activityTypes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HealthTypeCollectionViewCell.reuseId, for: indexPath) as? HealthTypeCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let activityType = activityTypes[indexPath.item]
        let value = self.activityValues?[activityType] ?? "--"
        cell.configure(title: activityType.titleLabel, value: value, units: activityType.subTitleLabel)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let controller = controller else { return CGSize.zero}
        
        let padding: CGFloat = 40
        let widthPerItem = (controller.view.frame.width - padding) / itemsPerRow
        return CGSize(width: widthPerItem, height: 110)
    }
    
    // Remove Inter Item Spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
}
