//
//  SettingsViewController.swift
//  DronePan-Swift
//
//  Created by Dennis Baldwin on 5/20/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    
    @IBOutlet weak var rowLabel: UILabel!
    @IBOutlet weak var rowSlider: UISlider!
    @IBOutlet weak var columnLabel: UILabel!
    @IBOutlet weak var columnSlider: UISlider!
    @IBOutlet weak var yawTypeLabel: UILabel!
    @IBOutlet weak var yawTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var skyRowLabel: UILabel!
    @IBOutlet weak var skyRowSwitch: UISwitch!
    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        
        let rows = defaults.integer(forKey: "rows")
        rowLabel.text = String(rows)
        rowSlider.setValue(Float(rows), animated: false)
        
        let columns = defaults.integer(forKey: "columns")
        columnLabel.text = String(columns)
        columnSlider.setValue(Float(columns), animated: false)
        
        let yawType = defaults.integer(forKey: "yawType")
        yawTypeLabel.text = yawTypeSegmentedControl.titleForSegment(at: yawType)
        yawTypeSegmentedControl.selectedSegmentIndex = yawType
        
        let skyRow = defaults.bool(forKey: "skyRow")
        skyRowLabel.text = skyRow ? "Enabled" : "Disabled"
        skyRowSwitch.isOn = skyRow
        
        
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func rowSliderChanged(_ sender: UISlider) {
        
        rowLabel.text = "\(Int(sender.value))"
        
    }
    
    
    @IBAction func columnSliderChanged(_ sender: UISlider) {
        
        columnLabel.text = "\(Int(sender.value))"
        
    }
    
    
    @IBAction func yawTypeChanged(_ sender: UISegmentedControl) {
        
        yawTypeLabel.text = sender.titleForSegment(at: sender.selectedSegmentIndex)
        
    }
    
    @IBAction func skyRowChanged(_ sender: UISwitch) {
        
        if sender.isOn {
            skyRowLabel.text = "Enabled"
        } else {
            skyRowLabel.text = "Disabled"
        }
        
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let defaults = UserDefaults.standard
        
        let rows = Int(rowSlider.value)
        let cols = Int(columnSlider.value)
        let yawType = Int(yawTypeSegmentedControl.selectedSegmentIndex)
        let skyRow = Bool(skyRowSwitch.isOn)
        
        // Save the data
        defaults.set(rows, forKey: "rows")
        defaults.set(cols, forKey: "columns")
        defaults.set(yawType, forKey: "yawType")
        defaults.set(skyRow, forKey: "skyRow")
        
    }
}
