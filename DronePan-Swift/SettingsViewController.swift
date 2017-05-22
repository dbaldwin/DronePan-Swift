//
//  SettingsViewController.swift
//  DronePan-Swift
//
//  Created by Dennis Baldwin on 5/20/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Settings view loaded")
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
        
    }
    /*@IBAction func closeButtonClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }*/
}
