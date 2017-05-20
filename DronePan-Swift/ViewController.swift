//
//  ViewController.swift
//  DronePan-Swift
//
//  Created by Dennis Baldwin on 5/19/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import DJISDK
import VideoPreviewer

class ViewController: UIViewController {
    
    @IBOutlet weak var cameraView: UIView!
    
    // Following this approach from the DJI SDK example
    override func viewWillAppear(_ animated: Bool) {
        
        // Setup the connection key
        guard let connectedKey = DJIProductKey(param: DJIParamConnection) else {
            return;
        }
        
        // Delay and then call the connection function
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            DJISDKManager.keyManager()?.startListeningForChanges(on: connectedKey, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue : DJIKeyedValue?) in
                if newValue != nil {
                    if newValue!.boolValue {
                        
                        DispatchQueue.main.async {
                            self.productConnected()
                        }
                        
                    }
                }
            })
        }
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Setup video feed
        VideoPreviewer.instance().setView(cameraView)
        DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
        VideoPreviewer.instance().start()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        VideoPreviewer.instance().unSetView()
        
        super.viewWillDisappear(animated)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func productConnected() {
        
        guard let newProduct = DJISDKManager.product() else {
            print("Product is connected but DJISDKManager.product is nil -> something is wrong")
            return;
        }
        
        //Updates the product's model
        print("Model: \((newProduct.model)!)")
        
        //Updates the product's firmware version - COMING SOON
        newProduct.getFirmwarePackageVersion{ (version:String?, error:Error?) -> Void in
            
            print("Firmware package version is: \(version ?? "Unknown")")
        }
        
        //Updates the product's connection status
        print("Product Connected")
        
        // Setting up camera delegate
        let camera: DJICamera? = fetchCamera()
        
        if camera != nil {
            print("camera delegate is setup")
            camera?.delegate = self
        }
        
    }

    func fetchCamera() -> DJICamera? {
        
        if DJISDKManager.product() == nil {
            return nil
        }
        
        if DJISDKManager.product() is DJIAircraft {
            return (DJISDKManager.product() as! DJIAircraft).camera
        } else if DJISDKManager.product() is DJIHandheld {
            return (DJISDKManager.product() as! DJIHandheld).camera
        }
        
        return nil
    }

}

// Get the video feed update
extension ViewController: DJIVideoFeedListener {
    
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
        
        videoData.withUnsafeBytes {
            (ptr: UnsafePointer<UInt8>) in
            
            let mutablePointer = UnsafeMutablePointer(mutating: ptr)
            
            VideoPreviewer.instance().push(mutablePointer, length: Int32(videoData.count))
        }
    }
    
}

extension ViewController: DJICameraDelegate {
    
    // This code does not work in SDK 4.0.1
    func camera(_ camera: DJICamera, didGenerateNewMediaFile newMedia: DJIMediaFile) {
        
        print("THIS NEVER GETS CALLED")
        
    }
    

}
