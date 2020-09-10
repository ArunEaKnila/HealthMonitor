//
//  ViewController.swift
//  HealthMonitor
//
//  Created by apple on 03/09/20.
//  Copyright © 2020 knila. All rights reserved.
//

import UIKit
import HealthKit
import UserNotifications

class ViewController: UIViewController {
    
    let stepsType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
    let hkStore = HKHealthStore()
    var stepsObserverQuery: HKObserverQuery?
    let kUserDefaultsAnchorKey = "kUserDefaultsAnchorKey"
    let timeManager = TimeIntervalManager.shared
    var intervalsArray: [String]?

    @IBOutlet weak var dayCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let center = UNUserNotificationCenter.current()
        self.intervalsArray = timeManager.getTimeIntervals()

        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                print("Yay!")
                
                HealthKitSetupAssistant.authorizeHealthKit { (granted, error) in
                    if granted {
                        //self.startObserving()
                    }
                    else {
                        print(error)
                    }
                }
            } else {
                print("D'oh")
            }
        }
    }
    
    @IBAction func showNotification(_ sender: Any) {
        self.scheduleNotification()
    }
    
    func startObserving() {
        print("startObserving")
        stepsObserverQuery = HKObserverQuery(
            sampleType: stepsType,
            predicate: nil) { [weak self] (query, completion, error) in
                self?.stepsObserverQueryTriggered()
        }

        hkStore.execute(stepsObserverQuery!)
        hkStore.enableBackgroundDelivery(for: stepsType, frequency: .immediate) { (granted, error) in
            if granted {
                print("BG notifications enabled")
            }
        }
    }
    
    func stepsObserverQueryTriggered() {
        print("stepsObserverQueryTriggered")
        let oneHourAgo = Date().addingTimeInterval(-(60*60))
        let lastHourPredicate = NSPredicate(format: "endDate > %@", oneHourAgo as NSDate)
        
        let stepsSampleQuery = HKSampleQuery(
                sampleType: stepsType,
                predicate: lastHourPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil,
                resultsHandler: { [weak self] (query, samples, error) in
                    self?.stepsSampleQueryFinished(samples: samples)
            })
        hkStore.execute(stepsSampleQuery)
    }

    func stepsSampleQueryFinished(samples: [HKSample]?) {
        
        samples?.forEach({ (sample) in
            guard let sample = sample as? HKQuantitySample else {
                return
            }
            
            print("SAMPLE DETAILS \(sample.quantity) \(sample.sampleType) at \(sample.endDate)")
        })
        
        print("stepsSampleQueryFinished")
        scheduleNotification()
    }
    
    func storeAnchor(anchor: HKQueryAnchor?) {
        guard let anchor = anchor else { return }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: kUserDefaultsAnchorKey)
        } catch {
            print("Unable to store new anchor")
        }
    }

    func retrieveAnchor() -> HKQueryAnchor? {
        guard let data = UserDefaults.standard.data(forKey: kUserDefaultsAnchorKey) else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
        } catch {
            print("Unable to retrieve an anchor")
            return nil
        }
    }
    
    func scheduleNotification() {
        let content = UNMutableNotificationContent()

        content.title = "Title"
        content.body = "body"
        content.categoryIdentifier = "CALLINNOTIFICATION"
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 10, repeats: false)
        let identifier = "id_Title"
        let request = UNNotificationRequest.init(identifier: identifier, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            print("Error in scheduling noti ", error?.localizedDescription ?? "")
        }
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let intervalCount = intervalsArray?.count {
            return intervalCount * 2 - 1
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = indexPath.row % 2 == 0 ? "timeCell" : "stepCell"

        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? TimeIntervalCollectionCell {
            if let interval = intervalsArray?[indexPath.row / 2] {
                cell.configure(interval)
            }
            
            return cell
        }
        else if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? StepIntervalCollectionCell {
            cell.configure("\(Int.random(in: 50..<500))")
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return indexPath.row % 2 == 0 ? CGSize(width: 80, height: 150) : CGSize(width: 50, height: 150)
    }
    
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
