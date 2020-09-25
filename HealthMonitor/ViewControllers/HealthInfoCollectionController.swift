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
    private let itemsPerRow: CGFloat = 1.75
    
    init(_ controller: CollectionControllerDelegate, collectionView: UICollectionView) {
        super.init()
        
        self.controller = controller
        self.collectionView = collectionView
    }
    
    weak var controller: CollectionControllerDelegate?
    weak var collectionView: UICollectionView?
    
    var displayDate: Date = Date() {
        didSet {
            ActivityDataSource.shared.fetchDataForAllTypes(self.displayDate) { [weak self] (activityValues) in
                self?.activityValues = activityValues
                
                self?.controller?.reloadData()
            }
        }
    }
    
    private var activityTypes = ActivityType.cases
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
    }
    
    func snapToCenter() {
        guard let view = controller?.view, let collectionView = collectionView else { return }
        
        let centerPoint = view.convert(view.center, to: collectionView)
        if let centerIndexPath = collectionView.indexPathForItem(at: centerPoint) {
            collectionView.scrollToItem(at: centerIndexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        snapToCenter()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            snapToCenter()
        }
    }
}
