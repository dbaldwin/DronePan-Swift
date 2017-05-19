//
//  ViewController.swift
//  DronePan-Swift
//
//  Created by Dennis Baldwin on 5/19/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import DJISDK

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
    
    func productConnected(_ product: DJIBaseProduct?) {
        
    }
    
    func productDisconnected() {
    }
    
    func componentConnected(withKey key: String?, andIndex index: Int) {
    }
    
    func componentDisconnected(withKey key: String?, andIndex index: Int) {
    }
}
