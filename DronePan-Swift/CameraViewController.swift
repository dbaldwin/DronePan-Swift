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

class CameraViewController: UIViewController {
    
    @IBOutlet weak var cameraView: UIView!
    
    @IBOutlet weak var hamburgerButton: UIButton!
    
    @IBOutlet weak var buttonNavView: UIView!
    
    var aircraftLocation: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    
    // Following this approach from the DJI SDK example
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // Setup the connection key
        guard let connectedKey = DJIProductKey(param: DJIParamConnection) else {
            return;
        }
        
        // Delay and then call the connection function
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            
            DJISDKManager.keyManager()?.startListeningForChanges(on: connectedKey, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue : DJIKeyedValue?) in
                
                if newValue != nil {
                    if newValue!.boolValue {
                        
                        DispatchQueue.main.async {
                            
                            self.productConnected()

                        }
                        
                    }
                }
            })
        }
        
        // Enable virtual stick mode so that timeline yaws will work. This bug has been acknowledged here:
        // https://github.com/dji-sdk/Mobile-SDK-iOS/issues/104
        /*guard let virtualStickKey = DJIFlightControllerKey(param: DJIFlightControllerParamVirtualStickAdvancedControlModeEnabled) else {
            return;
        }
        
        DJISDKManager.keyManager()?.setValue(true, for: virtualStickKey, withCompletion: { (error: Error?) in
            
            if error != nil {
                
                print("Error setting virtual stick mode")
                
            }
            
        })*/
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Setup video feed
        VideoPreviewer.instance().setView(cameraView)
        //DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
        //VideoPreviewer.instance().start()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        VideoPreviewer.instance().unSetView()
        DJISDKManager.videoFeeder()?.primaryVideoFeed.remove(self)
        
        super.viewWillDisappear(animated)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("SDK version: \(DJISDKManager.sdkVersion())")
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startPano(_ sender: Any) {
        
        // Clear out previous missions
        DJISDKManager.missionControl()?.stopTimeline()
        DJISDKManager.missionControl()?.unscheduleEverything()
        DJISDKManager.missionControl()?.removeAllListeners()
        
        DJISDKManager.missionControl()?.addListener(self, toTimelineProgressWith: { (event: DJIMissionControlTimelineEvent, element: DJIMissionControlTimelineElement?, error: Error?, info: Any?) in
            
            print("Mission control event \(String(describing: DJIMissionControlTimelineEvent(rawValue: event.rawValue)))")
            
            switch event {
                
            case .started:
                print("Started")
            case .startError:
                print("Start error")
            case .progressed:
                print("Progressed")
            case .paused:
                print("Paused")
            case .pauseError:
                print("Pause error")
            case .resumed:
                print("Resumed")
            case .resumeError:
                print("Resume error")
            case .stopped:
                print("Stopped")
            case .stopError:
                print("Stop error")
            case .finished:
                print("Finished")
            default:
                print("Defaut")
            }
        })
        
        /*let pano = PanoramaController()
        let error = DJISDKManager.missionControl()?.scheduleElements(pano.pitchGimbal())
        
        if error != nil {
            print("Error scheduling elements \(String(describing: error))")
            return;
        }*/
        
        var elements = [DJIMissionControlTimelineElement]()
        
        let attitude = DJIGimbalAttitude(pitch: -45, roll: 0.0, yaw: 0.0)
        let pitchAction: DJIGimbalAttitudeAction = DJIGimbalAttitudeAction(attitude: attitude)!
        elements.append(pitchAction)
        
        let yawAction: DJIAircraftYawAction = DJIAircraftYawAction(relativeAngle: 60, andAngularVelocity: 30)!
        elements.append(yawAction)
        
        let error = DJISDKManager.missionControl()?.scheduleElements(elements)
        
        if error != nil {
            print("Error scheduling elements \(String(describing: error))")
            return;
        }
        
        DJISDKManager.missionControl()?.startTimeline()
    }
    
    @IBAction func showButtonNav(_ sender: Any) {
        
        buttonNavView.isHidden = !buttonNavView.isHidden
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        buttonNavView.isHidden = true
        
    }
    
    func productConnected() {
        
        guard let newProduct = DJISDKManager.product() else {
            print("Product is connected but DJISDKManager.product is nil -> something is wrong")
            return;
        }
        
        //Updates the product's model
        print("Model: \((newProduct.model)!)")
        
        //Updates the product's firmware version - COMING SOON
        newProduct.getFirmwarePackageVersion{ (version:String?, error:Error?) -> Void in
            
            print("Firmware package version is: \(version ?? "Unknown")")
        }
        
        //Updates the product's connection status
        print("Product Connected")
        
        // Setting up camera delegate
        let camera: DJICamera? = fetchCamera()
        
        if camera != nil {
            print("camera delegate is setup")
            camera?.delegate = self
        }
        
        // Setting up flight controller delegate
        let fc: DJIFlightController? = fetchFlightController()
        
        if fc != nil {
            fc?.delegate = self
        }
        
        // Enable virtual stick mode so that the aircraft can yaw
        fc?.setVirtualStickModeEnabled(true, withCompletion: nil)
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
    
    func fetchFlightController() -> DJIFlightController? {
        
        if DJISDKManager.product() == nil {
            return nil
        }
        
        if DJISDKManager.product() is DJIAircraft {
            return (DJISDKManager.product() as! DJIAircraft).flightController
        }
        
        return nil
    }

}

// Get the video feed update
extension CameraViewController: DJIVideoFeedListener {
    
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
        
        videoData.withUnsafeBytes {
            (ptr: UnsafePointer<UInt8>) in
            
            let mutablePointer = UnsafeMutablePointer(mutating: ptr)
            
            VideoPreviewer.instance().push(mutablePointer, length: Int32(videoData.count))
        }
    }
    
}

extension CameraViewController: DJICameraDelegate {
    
    // This code does not work in SDK 4.0.1
    func camera(_ camera: DJICamera, didGenerateNewMediaFile newMedia: DJIMediaFile) {
        
        print("THIS NEVER GETS CALLED")
        
    }
    

}

// Keep track of the current aircraft location
extension CameraViewController: DJIFlightControllerDelegate {
    
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        
        self.aircraftLocation = (state.aircraftLocation?.coordinate)!

        // Send the location update to the map view
        //self.cameraVCDelegate?.updateAircraftLocation(location: self.aircraftLocation, heading: self.aircraftHeading)
        
    }
    
}
