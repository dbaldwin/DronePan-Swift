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
    
    var totalPhotoCount: Int = 0 {
        
        didSet {
            
            updatePhotoCountLabel()
            
        }
        
    }
    
    var currentPhotoCount: Int = 0 {
     
        didSet {
            
            updatePhotoCountLabel()
            
        }
    }
    
    override func viewDidLoad() {
        
        print("Telemetry view controller view did load")
        
        super.viewDidLoad()
        
    }
    
    func resetAndStartCounting(photoCount: Int) {
        
        currentPhotoCount = 0
        totalPhotoCount = photoCount
        ProductCommunicationManager.shared.fetchCamera()?.delegate = self
        
    }
    
    private func updatePhotoCountLabel() {
        
        photoCountLabel.text = "\(currentPhotoCount)/\(totalPhotoCount)"
        
    }
    
}

extension TelemetryViewController: DJICameraDelegate {
    
    func camera(_ camera: DJICamera, didGenerateNewMediaFile newMedia: DJIMediaFile) {
        
        print("TelemetryViewController didGenerateNewMediaFile")
        currentPhotoCount += 1
    }
    
}
