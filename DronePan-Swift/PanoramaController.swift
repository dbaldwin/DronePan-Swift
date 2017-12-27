//
//  PanoramaController.swift
//  DronePan-Swift
//
//  Created by Dennis Baldwin on 5/22/17.
//  Modified by Kilian Eisenegger on 12/24/17
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
    func buildPanoAtCurrentLocation(aircraftModel: String) -> [DJIMissionControlTimelineElement] {
        
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
            
            return buildPanoWithAircraftYaw(rows: rows, cols: cols, skyRow: skyRow, aircraftModel: aircraftModel)
        }
        
    }
    
    //Aircraft yaw
    func buildPanoWithAircraftYaw(rows: Int, cols: Int, skyRow: Bool, aircraftModel: String) -> [DJIMissionControlTimelineElement] {
        
        // Get gimbal capabilities
        // Not doing anything with this at the moment
        /*if let gimbal = ProductCommunicationManager.shared.fetchGimbal()
         {
         let capability: DJIParamCapability = gimbal.capabilities[DJIGimbalParamAdjustPitch] as! DJIParamCapability
         let minMax: DJIParamCapabilityMinMax = capability as! DJIParamCapabilityMinMax
         print("Gimbal pitch max: \(minMax.max)")
         print("Gimbal pitch min: \(minMax.min)")
         }*/
        
        
        // Initialize the timeline array
        var elements = [DJIMissionControlTimelineElement]()
        
        // Loop and build the pano sequence
        for column in 0..<cols {
            
            var gimbalPitch: Float = 0
            
            for row in 0..<rows {
                
                // Set the gimbal pitch
                // With sky row the total vertical range is from +30 to -90 which is 120 degrees
                if skyRow {
                    
                    // For mavic pro let's limit to +20 due to gimbal errors
                    // TODO: We may need to range vertical range for MP to 110 (+20 to -90)
                    if aircraftModel.lowercased().contains("mavic") {
                        
                        gimbalPitch = 20 - Float(120/rows) * Float(row)
                        
                    } else {
                        
                        gimbalPitch = 30 - Float(120/rows) * Float(row)
                        
                    }
                    
                // Non sky row case
                } else {
                    
                    gimbalPitch = 0 - Float(90/rows) * Float(row)
                    
                }
                
                // take only in every second row the last picture = better stitching = faster
                if (row == (rows - 1) && column % 2 == 0) || (row < (rows - 1)) {
                    print("Pitching gimbal to \(gimbalPitch) degrees")
                    
                    let attitude = DJIGimbalAttitude(pitch: gimbalPitch, roll: 0.0, yaw: 0.0)
                    let pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
                    elements.append(pitchAction)
                    
                    let photoAction: DJIShootPhotoAction = DJIShootPhotoAction(singleShootPhoto:())!
                    elements.append(photoAction)
                }
                
            }
            
            // let's win some time and take the nadir shot in the first column, we only need one
            if column == 0 {
                
                print("Nadir shot")
                
                let attitude = DJIGimbalAttitude(pitch: -90, roll: 0.0, yaw: 0.0)
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
        // var attitude = DJIGimbalAttitude(pitch: -90.0, roll: 0.0, yaw: 0.0)
        // var pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
        // elements.append(pitchAction)
        
        // Take the nadir shot
        // let photoAction: DJIShootPhotoAction = DJIShootPhotoAction(singleShootPhoto:())!
        // elements.append(photoAction)
        
        // Reset the gimbal to starting position
        let attitude = DJIGimbalAttitude(pitch: 0.0, roll: 0.0, yaw: 0.0)
        let pitchAction = DJIGimbalAttitudeAction(attitude: attitude)!
        elements.append(pitchAction)
        
        // Raise altitude by 1m to get around being stuck in joystick mode at the end of the mission
        // This will force the aircraft back into GPS mode
        // Removing this for now. In some cases it causes the drone to go to the ground. I'm assuming there is not a valid start altitude.
        /*let gotoAction: DJIGoToAction = DJIGoToAction(altitude: altitude+1)!
         elements.append(gotoAction)*/
        
        return elements
        
    }
    
    // Gimbal yaw requires absolute angles for each gimbal position
    // Inspire 1 and Inspire 2 users
    func buildPanoWithGimbalYaw(rows: Int, cols: Int, skyRow: Bool) -> [DJIMissionControlTimelineElement] {
        
        let yawAngle = 360/cols
        
        // Initialize the timeline array
        var elements = [DJIMissionControlTimelineElement]()
        
        // +30° pitch is nonsens with gimbal yaw, let's take the first row with drone yaw
        if skyRow {
            
            let gimbalPitch: Float = 30
            print("Pitching gimbal to \(gimbalPitch) degrees")
            
            let attitude = DJIGimbalAttitude(pitch: gimbalPitch, roll: 0.0, yaw: 0.0)
            let pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
            elements.append(pitchAction)
            
            for _ in 0..<cols {
                
                let photoAction: DJIShootPhotoAction = DJIShootPhotoAction(singleShootPhoto:())!
                elements.append(photoAction)
                
                let yaw: Float = Float(360/cols)
                print("Yawing aircraft \(yaw) degrees")
                
                let yawAction: DJIAircraftYawAction = DJIAircraftYawAction(relativeAngle: Double(yaw), andAngularVelocity: 30)!
                elements.append(yawAction)
                
            }
            
        }
        
            // Loop through the columns (gimbal yaw)
        for column in 0..<cols {
                
            var yaw = yawAngle * column
                
            // Now account for the gimbal yaw offset since I1/I2 uses an absolute reference
            // Uncomment this once we figure out how the different aircraft handle the initial yaw
            //yaw = yaw + Int(startingYaw)
                
            if yaw > 180 {
                    
                // yaw = -1 * (180 + (180 - yaw))
                yaw = yaw - 360 // that's simplier
                    
            }
                
            var gimbalPitch: Float = 0 // should be defined outside the loop
                
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
                    
                // First row at +30° with drone yaw
                if gimbalPitch != 30 {
                        
                    // take only in every second row the last = better stitching = faster
                    if (row == (rows - 1) && column % 2 == 0) || (row < (rows - 1)) {
                            
                        print("Pitching gimbal to \(gimbalPitch) degrees and yawing gimbal to \(yaw) degrees")
                            
                        let attitude = DJIGimbalAttitude(pitch: gimbalPitch, roll: 0.0, yaw: Float(yaw))
                        let pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
                        elements.append(pitchAction)
                            
                        let photoAction: DJIShootPhotoAction = DJIShootPhotoAction(singleShootPhoto:())!
                        elements.append(photoAction)
                            
                    }
                        
                }
                    
                // let's win some time and take the nadir shot in the first column, we only need one
                if column == 0 {
                        
                    print("Nadir shot")
                        
                    let attitude = DJIGimbalAttitude(pitch: -90, roll: 0.0, yaw: Float(yaw))
                    let pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
                    elements.append(pitchAction)
                        
                    let photoAction: DJIShootPhotoAction = DJIShootPhotoAction(singleShootPhoto:())!
                    elements.append(photoAction)
                    }
                    
                }
                
            }
            
            // Let's add nadir shots (start with one and add more later)
            // var attitude = DJIGimbalAttitude(pitch: -90.0, roll: 0.0, yaw: -180)
            // var pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
            // elements.append(pitchAction)
            
            // Take the nadir shot
            // let photoAction: DJIShootPhotoAction = DJIShootPhotoAction(singleShootPhoto:())!
            // elements.append(photoAction)
            
            // Let's send the gimbal back to +90 otherwise it will try to continue to rotate counter clockwise
            var attitude = DJIGimbalAttitude(pitch: 0, roll: 0.0, yaw: 90)
            var pitchAction = DJIGimbalAttitudeAction(attitude: attitude)!
            elements.append(pitchAction)
            
            // Now send it back to 0
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
