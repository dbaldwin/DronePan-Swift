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
    
    let enableBridgeMode = true
    var aircraftLocation : CLLocationCoordinate2D?
    let bridgeAppIP = "192.168.1.100"
    
    static let shared = ProductCommunicationManager()
    
    func registerWithSDK() {
        DJISDKManager.registerApp(with: self)
    }
    
    //Check Connection To Product
    func isProductConnected() -> Bool {
        if DJISDKManager.product() == nil {
            return false
        }
        return true
    }
    
    //MARK:- Camera
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
    
    //MARK:- Flight Controller
    func fetchFlightController() -> DJIFlightController? {
        
        if DJISDKManager.product() == nil {
            return nil
        }
        
        if DJISDKManager.product() is DJIAircraft {
            return (DJISDKManager.product() as! DJIAircraft).flightController
        }
        return nil
    }
    
    //MARK:- Flight Gimbal
    func fetchGimbal() -> DJIGimbal? {
        
        if DJISDKManager.product() == nil {
            return nil
        }
        
        if DJISDKManager.product() is DJIAircraft {
            return (DJISDKManager.product() as! DJIAircraft).gimbal
        } else if DJISDKManager.product() is DJIHandheld {
            return (DJISDKManager.product() as! DJIHandheld).gimbal
        }
        
        return nil
        
    }

    
}

extension ProductCommunicationManager : DJISDKManagerDelegate,DJIFlightControllerDelegate {
    
    func appRegisteredWithError(_ error: Error?) {
        
        if error == nil {
            
            if enableBridgeMode {
                DJISDKManager.enableBridgeMode(withBridgeAppIP: bridgeAppIP)
            } else {
                DJISDKManager.startConnectionToProduct()
            }
            
        }else{
            
            (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController?.showAlert(title: "Message", message: "Registration Failed - \(String(describing: error?.localizedDescription))")
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
    
    // Recording the Currect Location Of Aircraft
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        self.aircraftLocation = state.aircraftLocation?.coordinate
    }
}


extension UIViewController {
    
    func showAlert(title:String?,message:String?) -> Void {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction((UIAlertAction(title: "OK", style: .cancel, handler: nil)))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showAlert(title:String?,message:String?,withCompletion completion:@escaping ((_ action:AnyObject)->Void)) -> Void {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
            completion(action)
        }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}



