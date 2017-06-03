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
        
        // Get the defaults from storage
        let defaults = UserDefaults.standard
        
        let rows = defaults.integer(forKey: "rows")
        let cols = defaults.integer(forKey: "columns")
        let yawType = defaults.integer(forKey: "yawType") // 0 is aircraft and 1 is gimbal
        let skyRow = defaults.bool(forKey: "skyRow") // 0 is disabled and 1 is enabled
        
        print("Shooting pano with \(rows) rows and \(cols) cols, yaw type: \(yawType), sky row: \(skyRow)")
        
        // Initialize the timeline array
        var elements = [DJIMissionControlTimelineElement]()
        
        // Reset the gimbal for gimbal yaw scenario
        if yawType == 1 {
            
            let attitude = DJIGimbalAttitude(pitch: 0.0, roll: 0.0, yaw: 0.0)
            let pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
            elements.append(pitchAction)
            
        }
        
        // Loop and build the pano sequence
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
            if yawType == 1 {
                
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
        
        // Let's add nadir shots (start with one and add more later)
        let attitude = DJIGimbalAttitude(pitch: -90.0, roll: 0.0, yaw: 0.0)
        let pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
        elements.append(pitchAction)
        
        // Take the nadir shot
        let photoAction: DJIShootPhotoAction = DJIShootPhotoAction(singleShootPhoto:())!
        elements.append(photoAction)
        
        return elements
        
    }
    
    func buildPanoAtCurrentLocationWithWaypointMission(currentLocation: CLLocationCoordinate2D) -> DJIMutableWaypointMission {
    
        var mission = DJIMutableWaypointMission()
        
        
        
        var waypoint = DJIWaypoint(coordinate: currentLocation)
        
        
        var waypoint2 = DJIWaypoint(coordinate: currentLocation)
        
        return mission
    }
    
    // Start a pano from a saved waypoint
    func buildPanoAtPreviousLocation() {
        
    }
    
    
    
}
