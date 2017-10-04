//
//  TelemetryViewController.swift
//  DronePan-Swift
//
//  Created by Dennis Baldwin on 6/5/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import DJISDK

protocol TelemetryViewControllerDelegate {
    func panoComplete()
}

class TelemetryViewController: UIViewController {
    
    @IBOutlet weak var photoCountLabel: UILabel!
    var delegate: TelemetryViewControllerDelegate?
    
    override func viewDidLoad() {
        
        print("Telemetry view controller view did load")
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func resetAndStartCounting(photoCount: Int) {
        AppDelegate.isStartingNewTaskOfPano = true
        ProductCommunicationManager.shared.fetchCamera()?.delegate = self
        updatePhotoCountLabel()
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
            self.showAlert(title: "Panorama complete!", message: "You can now take manual control of your aircraft. If you have any problems taking manual control please toggle your flight mode switch away from GPS mode and back. Then you should have control again.")
            
            // Tell the parent
            self.delegate?.panoComplete()
        }
        self.updatePhotoCountLabel()
    }
    
}
