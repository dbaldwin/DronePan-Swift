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
    
    let enableBridgeMode = false
    let bridgeAppIP = "10.0.1.19"
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DJISDKManager.registerApp(with: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

extension ViewController: DJISDKManagerDelegate {
    
    func appRegisteredWithError(_ error: Error?) {
        
        NSLog("SDK Registered with error \(String(describing: error?.localizedDescription))")
        
        if enableBridgeMode {
            
            DJISDKManager.enableBridgeMode(withBridgeAppIP: bridgeAppIP)
            
        } else {
            
            DJISDKManager.startConnectionToProduct()
            
        }
        
    }
    
    // Called when we establish a connection with the aircraft
    func productConnected(_ product: DJIBaseProduct?) {
        
        guard let newProduct = DJISDKManager.product() else {
            print("Product is connected but DJISDKManager.product is nil -> something is wrong")
            return;
        }
        
        print("Product is connected: \(newProduct.model)")
        
        let camera: DJICamera? = fetchCamera()
        
        // Setup video feed
        /*VideoPreviewer.instance().setView(cameraView)
        DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
        VideoPreviewer.instance().start()*/
        
    }
    
    func productDisconnected() {
    }
    
    func componentConnected(withKey key: String?, andIndex index: Int) {
    }
    
    func componentDisconnected(withKey key: String?, andIndex index: Int) {
    }
}
