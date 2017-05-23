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
    
    // Basic test for pitching and shooting
    func pitchGimbal() -> [DJIMissionControlTimelineElement] {
        
        var elements = [DJIMissionControlTimelineElement]()
        var gimbalPitch: Float = 0
        
        for i in 0..<4 {
            
            // Set the gimbal pitch
            gimbalPitch = 0 - Float(90/4) * Float(i)
            
            print("Pitching gimbal to \(gimbalPitch)")
            
            let attitude = DJIGimbalAttitude(pitch: gimbalPitch, roll: 0.0, yaw: 0.0)
            let pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
            elements.append(pitchAction)
            
            let photoAction: DJIShootPhotoAction = DJIShootPhotoAction(singleShootPhoto:())!
            elements.append(photoAction)
            
        }
        
        return elements
    }
    
    // Execute pano at the current location
    func buildPanoAtCurrentLocation() -> [DJIMissionControlTimelineElement] {
        
        let rows: Int = 4
        let cols: Int = 7
        
        var elements = [DJIMissionControlTimelineElement]()
        
        for _ in 0..<cols {
            
            var gimbalPitch: Float = 0
            
            for row in 0..<rows {
                
                // Set the gimbal pitch
                gimbalPitch = 0 - Float(90/rows) * Float(row)
                
                print("Pitching gimbal to \(gimbalPitch)")
                
                let attitude = DJIGimbalAttitude(pitch: gimbalPitch, roll: 0.0, yaw: 0.0)
                let pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
                elements.append(pitchAction)
                
                let photoAction: DJIShootPhotoAction = DJIShootPhotoAction(singleShootPhoto:())!
                elements.append(photoAction)
                
            }
            
            let yaw: Float = Float(360/cols)
            
            // Let's do gimbal yaw for I1/I2 users
            if isGimbalYaw {
                
                print("Yawing gimbal \(yaw) degrees")
                
                let attitude = DJIGimbalAttitude(pitch: gimbalPitch, roll: 0.0, yaw: yaw)
                let pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
                elements.append(pitchAction)
            
            // Let's do aircraft yaw
            } else {
            
                print("Yawing aircraft \(yaw) degrees")
        
                let yawAction: DJIAircraftYawAction = DJIAircraftYawAction(relativeAngle: Double(yaw), andAngularVelocity: 30)!
                elements.append(yawAction)
            }
        }
        
        return elements
        
    }
    
    // Start a pano from a saved waypoint
    func buildPanoAtPreviousLocation() {
        
    }
    
    
    
}
