//
//  DashboardViewController.swift
//  HealthMonitor
//
//  Created by apple on 03/09/20.
//  Copyright © 2020 knila. All rights reserved.
//

import UIKit
import UserNotifications
import Charts
import FSCalendar

class DashboardViewController: UIViewController {
    
    let timeManager = TimeIntervalManager.shared
    var intervalsArray = [StepsModel]()
    var todayIndexPath: IndexPath? {
        didSet {
            if let indexPath = todayIndexPath {
                dayCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
    }
    lazy var infoCollectionController = HealthInfoCollectionController(self, collectionView: self.healthInfoCollectionView)

    @IBOutlet weak var heartRateView: LineChartView!
    @IBOutlet weak var dayCollectionView: UICollectionView!
    @IBOutlet weak var healthInfoCollectionView: UICollectionView!
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet weak var totalStepsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let allIntervals = timeManager.getTimeIntervals()
        self.intervalsArray = allIntervals.map({
            return StepsModel(intervalStartTime: $0, stepsCount: 0, heartRate: 0)
        })
        
        initializeCalendar()
        initializeCharts()
        setupInfoCollectionView()
        refreshHealthKitData()
        observeIntervalChanges()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if intervalsArray.isEmpty { return }
        
        for index in 0..<intervalsArray.count {
            let stepsModel = intervalsArray[index]
            let isNow = TimeIntervalManager.shared.isDateInRange(stepsModel.intervalStartTime?.date ?? Date())
            if isNow {
                todayIndexPath = IndexPath(item: index*2+1, section: 0)
                break
            }
        }
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
}

// MARK: Health Kit
extension DashboardViewController {
    private func refreshHealthKitData() {
        HealthKitDataFetcher.shared.getStepsForEachHour(self.calendarView.selectedDate ?? Date()) { (results) in
            for index in 0..<self.intervalsArray.count {
                let stepsModel = self.intervalsArray[index]
                stepsModel.stepsCount = Int(Double(results[safe: index] ?? "0") ?? 0)
            }
            
            DispatchQueue.main.async {
                let totalSteps = self.intervalsArray.reduce(0, { (subTotal, model) -> Int in
                    return subTotal + (model.stepsCount ?? 0)
                })
                self.totalStepsLabel.text = String(totalSteps)
                self.dayCollectionView.reloadData()
                self.refreshChartsData()
            }
        }
        
        infoCollectionController.displayDate = self.calendarView.selectedDate ?? Date()
    }
}

// MARK: Day Collection View
extension DashboardViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !intervalsArray.isEmpty {
            return intervalsArray.count * 2 - 1
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = indexPath.row % 2 == 0 ? "timeCell" : "stepCell"

        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? TimeIntervalCollectionCell {
            let stepsModel = intervalsArray[indexPath.row / 2]
            cell.configure(stepsModel.intervalStartTime ?? "Time")
            
            return cell
        }
        else if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? StepIntervalCollectionCell {
            let stepsModel = intervalsArray[indexPath.row / 2]
            if let interval = stepsModel.intervalStartTime, let date = interval.date {
                let isNow = Calendar.current.isDateInToday(calendarView.selectedDate ?? Date()) && TimeIntervalManager.shared.isDateInRange(date)
                                
                cell.configure("\(stepsModel.stepsCount ?? 0)", isToday: isNow)
            }
            
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

// MARK: Charts - Heart Rate
extension DashboardViewController: ChartViewDelegate {
    private func initializeCharts() {
        self.heartRateView.delegate = self
        self.heartRateView.xAxis.granularity = 1
        self.heartRateView.noDataText = "No Heart Data available, Please allow us to access the heart data"
        self.heartRateView.xAxis.labelPosition = .bottom
        self.heartRateView.autoScaleMinMaxEnabled = false
        self.heartRateView.drawGridBackgroundEnabled = false
        self.heartRateView.rightAxis.enabled = false
        self.heartRateView.xAxis.drawGridLinesEnabled = false
        self.heartRateView.leftAxis.drawGridLinesEnabled = false
    }
    private func refreshChartsData() {
        if intervalsArray.isEmpty { return }
        
        let allIntervals = intervalsArray.map({ return $0.intervalStartTime ?? "Time" })
        self.heartRateView.xAxis.valueFormatter = IndexAxisValueFormatter(values: allIntervals)
        
        var heartRateEntries = [ChartDataEntry]()
        for index in 0..<intervalsArray.count {
            let heartRate = Double(intervalsArray[index].heartRate ?? 0)
            if heartRate > 0 {
                let value = ChartDataEntry(x: Double(index), y: heartRate)
                heartRateEntries.append(value)
            }
        }
        
        let line1 = LineChartDataSet(entries: heartRateEntries, label: "Heart Rate")
        line1.drawCircleHoleEnabled = false
        line1.drawCirclesEnabled = false
        line1.drawValuesEnabled = false
        line1.colors = [.red]
        
        var stepEntries = [ChartDataEntry]()
        for index in 0..<intervalsArray.count {
            let stepsCount = Double(intervalsArray[index].stepsCount ?? 0)
            let value = ChartDataEntry(x: Double(index), y: stepsCount)
            stepEntries.append(value)
        }
        
        let line2 = LineChartDataSet(entries: stepEntries, label: "Steps")
        line2.circleRadius = 3
        line2.circleColors = [.systemTeal]
        line2.drawCircleHoleEnabled = false
        line2.colors = [.systemTeal]
        
        let data = LineChartData()
        data.addDataSet(line1)
        data.addDataSet(line2)
        heartRateView.data = data
    }
}

// MARK: Calendar
extension DashboardViewController: FSCalendarDataSource, FSCalendarDelegate {
    func initializeCalendar() {
        self.calendarView.setScope(.week, animated: false)
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        refreshHealthKitData()
    }
    
    func maximumDate(for calendar: FSCalendar) -> Date {
        return Date()
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendarHeightConstraint.constant = bounds.size.height
        view.layoutIfNeeded()
        view.setNeedsLayout()
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        calendarView.select(calendar.currentPage, scrollToDate: false)
        refreshHealthKitData()
    }
}

// MARK: Info CollectionView setup
extension DashboardViewController: CollectionControllerDelegate {
    func setupInfoCollectionView() {
//        let flowLayout = SnappingFlowLayout()
//        flowLayout.scrollDirection = .horizontal
//
//        healthInfoCollectionView.collectionViewLayout = flowLayout
        healthInfoCollectionView.isPagingEnabled = false
        healthInfoCollectionView.decelerationRate = .fast
        
        healthInfoCollectionView.dataSource = infoCollectionController
        healthInfoCollectionView.delegate = infoCollectionController
    }
    
    func reloadData() {
        healthInfoCollectionView.reloadData()
    }
}
