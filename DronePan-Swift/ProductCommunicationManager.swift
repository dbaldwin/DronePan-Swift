//
//  ProductCommunicationManager.swift
//  DronePan-Swift
//
//  Created by Dennis Baldwin on 5/19/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import DJISDK

class ProductCommunicationManager: NSObject {
    
    let enableBridgeMode = false
    let bridgeAppIP = "10.0.1.23"
    
    func registerWithSDK() {
        
        DJISDKManager.registerApp(with: self)
        
    }
    
}

extension ProductCommunicationManager : DJISDKManagerDelegate {
    
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



