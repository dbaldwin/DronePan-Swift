//
//  CameraSettingsViewController.swift
//  DronePan-Swift
//
//  Created by Dennis Baldwin on 9/5/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit

class CameraSettingsViewController: UIViewController {
    
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

