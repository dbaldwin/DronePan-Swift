//
//  PanoramaController.swift
//  DronePan-Swift
//
//  Created by Dennis Baldwin on 5/22/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import DJISDK

class PanoramaController {
    
    
    
    func startPanoAtCurrentLocation() {
        
        // Clear out previous missions
        DJISDKManager.missionControl()?.stopTimeline()
        DJISDKManager.missionControl()?.unscheduleEverything()
        
        let rows: Int = 4
        let cols: Int = 7
        
        for _ in 0..<cols {
            
            for row in 0..<rows {
                
                // Set the gimbal pitch
                let pitch: Float = Float(90/rows) * Float(row)
                
                print("Pitching gimbal to \(pitch)")
                
                let attitude = DJIGimbalAttitude(pitch: pitch, roll: 0.0, yaw: 0.0)
                let pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
                
                var error = DJISDKManager.missionControl()?.scheduleElement(pitchAction)
                
                if error != nil {
                    print("Error scheduling element \(error)")
                    return;
                }
                
                let photoAction: DJIShootPhotoAction = DJIShootPhotoAction(singleShootPhoto:())!
                
                error = DJISDKManager.missionControl()?.scheduleElement(photoAction)
                
                if error != nil {
                    print("Error scheduling element \(error)")
                    return;
                }
                
            }
            
            let yaw: Double = Double(360/cols)
            
            print("Yawing aircraft \(yaw) degrees")
        
            let yawAction: DJIAircraftYawAction = DJIAircraftYawAction(relativeAngle: yaw, andAngularVelocity: 30)!
            let error = DJISDKManager.missionControl()?.scheduleElement(yawAction)
            
            if error != nil {
                print("Error scheduling element \(error)")
                return;
            }
        }
        
        
    }
    
    // Start a pano from a saved waypoint
    func startPanoAtPreviousLocation() {
        
    }
    
    
    
}
