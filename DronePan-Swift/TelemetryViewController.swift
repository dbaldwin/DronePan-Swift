//
//  TelemetryViewController.swift
//  DronePan-Swift
//
//  Created by Dennis Baldwin on 6/5/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import DJISDK

class TelemetryViewController: UIViewController {
    
    @IBOutlet weak var photoCountLabel: UILabel!
    
    
    override func viewDidLoad() {
        
        print("Telemetry view controller view did load")
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ProductCommunicationManager.shared.fetchCamera()?.delegate = self
        updatePhotoCountLabel()
    }
    
    func resetAndStartCounting(photoCount: Int) {
        AppDelegate.isStartingNewTaskOfPano = true
    }
    
    func updatePhotoCountLabel() {
        
        photoCountLabel.text = "\(AppDelegate.currentPhotoCount)/\(AppDelegate.totalPhotoCount)"
        
        
    }
    
}

extension TelemetryViewController: DJICameraDelegate {
    
    func camera(_ camera: DJICamera, didGenerateNewMediaFile newMedia: DJIMediaFile) {
        
        print("TelemetryViewController didGenerateNewMediaFile")
        if(AppDelegate.isStartingNewTaskOfPano)
        {
            AppDelegate.currentPhotoCount += 1
        }
        if AppDelegate.currentPhotoCount == AppDelegate.totalPhotoCount {
            AppDelegate.currentPhotoCount = 0
            AppDelegate.totalPhotoCount = 0
            AppDelegate.isStartingNewTaskOfPano = false
            self.showAlert(title: "Panorama complete!", message: "You can now take manual control of your aircraft.")
        }
        self.updatePhotoCountLabel()
    }
    
}
