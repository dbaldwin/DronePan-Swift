//
//  PanoramaController.swift
//  DronePan-Swift
//
//  Created by Dennis Baldwin on 5/22/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import DJISDK

class PanoramaController {
    
    var isGimbalYaw = false
    
    func startPanoAtCurrentLocation() {
        
        // Clear out previous missions
        DJISDKManager.missionControl()?.stopTimeline()
        DJISDKManager.missionControl()?.unscheduleEverything()
        
        let rows: Int = 4
        let cols: Int = 7
        
        for _ in 0..<cols {
            
            var gimbalPitch: Float = 0
            
            for row in 0..<rows {
                
                // Set the gimbal pitch
                gimbalPitch = Float(90/rows) * Float(row)
                
                print("Pitching gimbal to \(gimbalPitch)")
                
                var elements = [DJIMissionControlTimelineElement]()
                
                let attitude = DJIGimbalAttitude(pitch: gimbalPitch, roll: 0.0, yaw: 0.0)
                let pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
                elements.append(pitchAction)
                
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
            
            let yaw: Float = Float(360/cols)
            
            // Let's do gimbal yaw for I1/I2 users
            if isGimbalYaw {
                
                print("Yawing gimbal \(yaw) degrees")
                
                let attitude = DJIGimbalAttitude(pitch: gimbalPitch, roll: 0.0, yaw: yaw)
                
            
            // Let's do aircraft yaw
            } else {
            
                print("Yawing aircraft \(yaw) degrees")
        
                let yawAction: DJIAircraftYawAction = DJIAircraftYawAction(relativeAngle: Double(yaw), andAngularVelocity: 30)!
                let error = DJISDKManager.missionControl()?.scheduleElement(yawAction)
                
                if error != nil {
                    print("Error scheduling element \(error)")
                    return;
                }
                
            }
        }
        
        
    }
    
    // Start a pano from a saved waypoint
    func startPanoAtPreviousLocation() {
        
    }
    
    
    
}
