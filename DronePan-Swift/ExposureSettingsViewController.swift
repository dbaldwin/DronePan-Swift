//
//  ExposureSettingsViewController.swift
//  DronePan-Swift
//
//  Created by Dennis Baldwin on 5/21/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit

class ExposureSettingsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
        
    }
    
    override var prefersStatusBarHidden: Bool {
        
        return true
        
    }
}
