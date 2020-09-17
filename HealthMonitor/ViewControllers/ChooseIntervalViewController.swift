//
//  ChooseIntervalViewController.swift
//  HealthMonitor
//
//  Created by apple on 17/09/20.
//  Copyright © 2020 Knila IT Solutions. All rights reserved.
//

import UIKit

class ChooseIntervalViewController: UIViewController {

    @IBOutlet weak var hoursPickerView: UIPickerView!
    @IBOutlet weak var minutePickerView: UIPickerView!
    
    var timeManager = TimeIntervalManager.shared
    var selectedHour: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let components = timeManager.timeInterval.components()
        selectedHour = components.hour ?? 0
        
        minutePickerView.reloadAllComponents()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let components = timeManager.timeInterval.components()
        let minuteIndex = (components.minute ?? 0) / 15
        
        hoursPickerView.selectRow(components.hour ?? 0, inComponent: 0, animated: true)
        minutePickerView.selectRow(minuteIndex, inComponent: 0, animated: true)
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        let (hours, minutes) = timeManager.chooseIntervalData(selectedHour)
        
        let hour = hours[selectedHour]
        let minute = minutes[minutePickerView.selectedRow(inComponent: 0)]
        
        timeManager.timeInterval = TimeInterval((hour * 60 + minute) * 60)
        
        self.navigationController?.popViewController(animated: true)
    }
}

extension ChooseIntervalViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let (hours, minutes) = timeManager.chooseIntervalData(selectedHour)
        
        return pickerView == hoursPickerView ? hours.count : minutes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let (hours, minutes) = timeManager.chooseIntervalData(selectedHour)
        
        return pickerView == hoursPickerView ? String(hours[row]) : String(minutes[row])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == hoursPickerView {
            selectedHour = row
            minutePickerView.reloadAllComponents()
        }
    }
}
