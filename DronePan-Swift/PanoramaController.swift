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
    
    //Execute pano at the current location
    func buildPanoAtCurrentLocation() -> [DJIMissionControlTimelineElement] {
        
        // Get the defaults from storage
        let defaults = UserDefaults.standard
        
        let rows = defaults.integer(forKey: "rows")
        let cols = defaults.integer(forKey: "columns")
        let yawType = defaults.integer(forKey: "yawType") // 0 is aircraft and 1 is gimbal
        let skyRow = defaults.bool(forKey: "skyRow") // 0 is disabled and 1 is enabled
        
        print("Shooting pano with \(rows) rows and \(cols) cols, yaw type: \(yawType), sky row: \(skyRow)")
        
        if yawType == 1 {
            
            return buildPanoWithGimbalYaw(rows: rows, cols: cols, skyRow: skyRow)
            
        } else {
            
            return buildPanoWithAircraftYaw(rows: rows, cols: cols, skyRow: skyRow)
        }
        
    }
    
    //Aircraft yaw
    func buildPanoWithAircraftYaw(rows: Int, cols: Int, skyRow: Bool) -> [DJIMissionControlTimelineElement] {
        
        // Get gimbal min
        let gimbal = ProductCommunicationManager.shared.fetchGimbal()
        
        gimbal?.getEndpointFor(DJIGimbalEndpointDirection.pitchUp, withCompletion: <#T##(Int, Error?) -> Void#>)
        
        // Initialize the timeline array
        var elements = [DJIMissionControlTimelineElement]()
        
        // Loop and build the pano sequence
        for _ in 0..<cols {
            
            var gimbalPitch: Float = 0
            
            for row in 0..<rows {
                
                // Set the gimbal pitch
                // With sky row the total vertical range is from +30 to -90 which is 120 degrees
                if skyRow {
                    
                    gimbalPitch = 30 - Float(120/rows) * Float(row)
                    
                    // Non sky row case
                } else {
                    
                    gimbalPitch = 0 - Float(90/rows) * Float(row)
                    
                }
                
                print("Pitching gimbal to \(gimbalPitch) degrees")
                
                let attitude = DJIGimbalAttitude(pitch: gimbalPitch, roll: 0.0, yaw: 0.0)
                let pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
                elements.append(pitchAction)
                
                let photoAction: DJIShootPhotoAction = DJIShootPhotoAction(singleShootPhoto:())!
                elements.append(photoAction)
                
            }
            
            let yaw: Float = Float(360/cols)
            print("Yawing aircraft \(yaw) degrees")
            
            let yawAction: DJIAircraftYawAction = DJIAircraftYawAction(relativeAngle: Double(yaw), andAngularVelocity: 30)!
            elements.append(yawAction)
            
        }
        
        // Let's add nadir shots (start with one and add more later)
        let attitude = DJIGimbalAttitude(pitch: -80.0, roll: 0.0, yaw: 0.0)
        let pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
        elements.append(pitchAction)
        
        // Take the nadir shot
        let photoAction: DJIShootPhotoAction = DJIShootPhotoAction(singleShootPhoto:())!
        elements.append(photoAction)
        
        return elements
        
    }
    
    // Gimbal yaw requires absolute angles for each gimbal position
    // Inspire 1 and Inspire 2 users
    func buildPanoWithGimbalYaw(rows: Int, cols: Int, skyRow: Bool) -> [DJIMissionControlTimelineElement] {
        
        let yawAngle = 360/cols
        
        // Initialize the timeline array
        var elements = [DJIMissionControlTimelineElement]()
        
        // Loop through the columns (gimbal yaw)
        for column in 0..<cols {
            
            var yaw = yawAngle * column
            
            if yaw > 180 {
                
                yaw = -1 * (180 + (180 - yaw))
                
            }
            
            var gimbalPitch: Float = 0
            
            // Loop through the rows (gimbal pitch)
            for row in 0..<rows {
                
                // Set the gimbal pitch
                // With sky row the total vertical range is from +30 to -90 which is 120 degrees
                if skyRow {
                    
                    gimbalPitch = 30 - Float(120/rows) * Float(row)
                    
                    // Non sky row case
                } else {
                    
                    gimbalPitch = 0 - Float(90/rows) * Float(row)
                    
                }
                
                print("Pitching gimbal to \(gimbalPitch) degrees and yawing gimbal to \(yaw) degrees")
                
                let attitude = DJIGimbalAttitude(pitch: gimbalPitch, roll: 0.0, yaw: Float(yaw))
                let pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
                elements.append(pitchAction)
                
                let photoAction: DJIShootPhotoAction = DJIShootPhotoAction(singleShootPhoto:())!
                elements.append(photoAction)
                
            }
            
        }
        
        // Let's add nadir shots (start with one and add more later)
        var attitude = DJIGimbalAttitude(pitch: -90.0, roll: 0.0, yaw: -180)
        var pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
        elements.append(pitchAction)
        
        // Take the nadir shot
        let photoAction: DJIShootPhotoAction = DJIShootPhotoAction(singleShootPhoto:())!
        elements.append(photoAction)
        
        // Let's send the gimbal back to the starting position
        attitude = DJIGimbalAttitude(pitch: 0, roll: 0.0, yaw: 0)
        pitchAction = DJIGimbalAttitudeAction(attitude: attitude)!
        elements.append(pitchAction)
        
        return elements
        
    }
    
    func buildPanoAtCurrentLocationWithWaypointMission(currentLocation: CLLocationCoordinate2D) -> DJIMutableWaypointMission {
    
        let mission = DJIMutableWaypointMission()
        _ = DJIWaypoint(coordinate: currentLocation)
        _ = DJIWaypoint(coordinate: currentLocation)
        
        return mission
    }
    
    // Start a pano from a saved waypoint
    func buildPanoAtPreviousLocation() {
        
    }
    
    
    
}
