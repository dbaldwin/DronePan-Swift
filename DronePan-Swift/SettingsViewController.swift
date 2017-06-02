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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Settings view loaded")
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
    
}
