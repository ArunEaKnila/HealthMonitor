//
//  InterfaceController.swift
//  WatchMonitor WatchKit Extension
//
//  Created by apple on 28/09/20.
//  Copyright © 2020 Knila IT Solutions. All rights reserved.
//

import WatchKit
import Foundation


class MainPageController: WKInterfaceController {

    @IBOutlet weak var previousTimeLabel: WKInterfaceLabel!
    @IBOutlet weak var nextTimeLabel: WKInterfaceLabel!
    @IBOutlet weak var currentStartTimeLabel: WKInterfaceLabel!
    @IBOutlet weak var currentEndTimeLabel: WKInterfaceLabel!
    @IBOutlet weak var watchLinesImage: WKInterfaceImage!
    @IBOutlet weak var stepsLabel: WKInterfaceLabel!
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var distanceLabel: WKInterfaceLabel!
    
    let timeManager = TimeIntervalManager.shared
    var intervalsArray = [StepsModel]()
    var currentTimeIndex: Int?
    var displayTimeIndex: Int?
    var activityValues: [ActivityType: String]?
    
    override func awake(withContext context: Any?) {
        let allIntervals = timeManager.getTimeIntervals()
        self.intervalsArray = allIntervals.map({
            return StepsModel(intervalStartTime: $0, stepsCount: 0, heartRate: 0)
        })
        
        authorizeHealthKit()
        observeIntervalChanges()
    }
    
    override func willActivate() {
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
    }
    
    private func observeIntervalChanges() {
        NotificationCenter.default.addObserver(forName: .intervalChanged, object: timeManager, queue: nil) { [weak self] (notification) in
            if let allIntervals = self?.timeManager.getTimeIntervals() {
                self?.intervalsArray = allIntervals.map({
                    return StepsModel(intervalStartTime: $0, stepsCount: 0, heartRate: 0)
                })
                
                self?.refreshHealthKitData()
            }
        }
    }
    
    @IBAction func goToNextScreenAction() {
        presentController(withName: "HealthList", context: self.activityValues)
    }
    
    @IBAction func swipeUpAction(_ sender: Any) {
        if (displayTimeIndex ?? 0) < (currentTimeIndex ?? 0) {
            displayTimeIndex = (displayTimeIndex ?? 0) + 1
            
            reloadTimeData()
        }
    }
    
    @IBAction func swipeDownAction(_ sender: Any) {
        if displayTimeIndex != 0 {
            displayTimeIndex = (displayTimeIndex ?? 0) - 1
            
            reloadTimeData()
        }
    }
    
    private func startLoadingAnimation() {
        self.watchLinesImage.setImageNamed("load")
        self.watchLinesImage.startAnimatingWithImages(in: NSRange(location: 0, length: 3), duration: 1, repeatCount: 0)
    }
    
    private func stopLoadingAnimation() {
        self.watchLinesImage.setImageNamed("watch_line")
    }
    
    private func reloadTimeData() {
        guard let index = self.displayTimeIndex else { return }
        
        let stepsModel = intervalsArray[index]
        
        animate(withDuration: 1) { [weak self] in
            guard let intervalsArray = self?.intervalsArray else { return }
            
            self?.stepsLabel.setText(String(stepsModel.stepsCount ?? 0))
            
            self?.currentStartTimeLabel.setText(stepsModel.intervalStartTime)
            self?.currentEndTimeLabel.setText(intervalsArray[safe: index+1]?.intervalStartTime)
            self?.previousTimeLabel.setText(intervalsArray[safe: index-1]?.intervalStartTime)
            self?.nextTimeLabel.setText(intervalsArray[safe: index+2]?.intervalStartTime)
        }
    }
}

// MARK: HealthKit Related
extension MainPageController {
    private func authorizeHealthKit() {
        HealthKitSetupAssistant.authorizeHealthKit {[weak self] (granted, error) in
            if granted {
                self?.refreshHealthKitData()
                self?.fetchOtherHealthData()
            } else {
                // TODO: Handle it!!
                print("Error authorizing health kit")
            }
        }
    }
    
    private func refreshHealthKitData() {
        HealthKitDataFetcher.shared.getStepsForEachHour(Date()) { (results) in
            for index in 0..<self.intervalsArray.count {
                let stepsModel = self.intervalsArray[index]
                stepsModel.stepsCount = Int(Double(results[safe: index] ?? "0") ?? 0)
            }
            
            self.refreshStepsAndTimeLabels()
        }
    }
    
    private func refreshStepsAndTimeLabels() {
        if intervalsArray.isEmpty { return }
        
        for index in 0..<intervalsArray.count {
            let stepsModel = intervalsArray[index]
            let isNow = TimeIntervalManager.shared.isDateInRange(stepsModel.intervalStartTime?.date ?? Date())
            
            if isNow {
                animate(withDuration: 1) { [weak self] in
                    guard let intervalsArray = self?.intervalsArray else { return }
                    
                    self?.stepsLabel.setText(String(stepsModel.stepsCount ?? 0))
                    
                    self?.currentStartTimeLabel.setText(stepsModel.intervalStartTime)
                    self?.currentEndTimeLabel.setText(intervalsArray[safe: index+1]?.intervalStartTime)
                    self?.previousTimeLabel.setText(intervalsArray[safe: index-1]?.intervalStartTime)
                    self?.nextTimeLabel.setText(intervalsArray[safe: index+2]?.intervalStartTime)
                }
                
                currentTimeIndex = index
                displayTimeIndex = index
                
                break
            }
        }
    }
    
    private func fetchOtherHealthData() {
        ActivityDataSource.shared.fetchDataForAllTypes(Date()) { [weak self] (activityValues) in
            if activityValues[.heartRate] == "0" {
                self?.heartRateLabel.setText("NO DATA")
            } else {
                self?.heartRateLabel.setText(activityValues[.heartRate])
            }
            
            self?.distanceLabel.setText("\(activityValues[.walkingDistance] ?? "0") mil")
            self?.activityValues = activityValues
        }
    }
}
