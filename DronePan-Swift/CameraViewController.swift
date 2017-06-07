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
    
    var telemetryViewController: TelemetryViewController!
    
    var totalPhotoCount: Int = 7 // This is the default 4 rows and 7 columns with 1 nadir
    var currentPhotoCount: Int = 0
    
    var gimbal: DJIGimbal?
    
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
        
        /* Can't seem to get this working so we'll revisit. We set the virtual stick mode right after setting up the delegate
        guard let virtualStickKey = DJIFlightControllerKey(param: DJIFlightControllerParamVirtualStickAdvancedControlModeEnabled) else {
            return;
        }
        
        DJISDKManager.keyManager()?.setValue(NSNumber(value: true), for: virtualStickKey, withCompletion: { (error: Error?) in
            
            if error != nil {
                
                print("Error setting virtual stick mode")
                
            }
            
        })*/
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Setup video feed
        VideoPreviewer.instance().setView(cameraView)
        DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
        VideoPreviewer.instance().start()
        
        // Add listener so we can get mission status updates
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
                // For some reason this gets called more than once
                //self.panoFinished()
                print("Finished")
            default:
                print("Defaut")
            }
        })
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        VideoPreviewer.instance().unSetView()
        DJISDKManager.videoFeeder()?.primaryVideoFeed.remove(self)
        
        DJISDKManager.missionControl()?.removeListener(self)
        
        super.viewWillDisappear(animated)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("SDK version: \(DJISDKManager.sdkVersion())")
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override var prefersStatusBarHidden: Bool {
        
        return true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startPano(_ sender: Any) {
        
        // Test to see if this works. For some reason it works when bridging but not with the actual device. Adding here to test.
        // Setting up camera delegate
        let camera: DJICamera? = fetchCamera()
        
        if camera != nil {
            print("camera delegate is setup")
            camera?.delegate = self
        }
        
        let defaults = UserDefaults.standard
        
        // We should figure out how to update these immediately after the settings are saved and get rid of all this code
        var rows = defaults.integer(forKey: "rows")
        
        if rows == 0 {
            rows = 4
        }
        
        var cols = defaults.integer(forKey: "columns")
        
        if cols == 0 {
            cols = 7
        }
        
        let skyRow = defaults.integer(forKey: "skyRow")
        
        if skyRow == 1 {
            
            rows = rows + 1
            
        }
        
        currentPhotoCount = 0
        
        print("Total number of rows \(rows), \(cols)")
        totalPhotoCount = rows * cols + 1
        
        telemetryViewController.photoCountLabel.text = "\(currentPhotoCount)/\(totalPhotoCount)"
        
        // Clear out previous missions
        DJISDKManager.missionControl()?.stopTimeline()
        DJISDKManager.missionControl()?.unscheduleEverything()
        
        // Reset the gimbal
        gimbal?.reset(completion: nil)
        
        // Build the pano logic
        let pano = PanoramaController()
        let error = DJISDKManager.missionControl()?.scheduleElements(pano.buildPanoAtCurrentLocation())
        
        if error != nil {
            showAlert(title: "Error", message: String(describing: error))
            return;
        }
        
        DJISDKManager.missionControl()?.startTimeline()
    }
    
    func panoFinished() {
        
        showAlert(title: "Success", message: "Your panorama was successfully captured!")
        
        // Reset the gimbal. For some reason with Inspire 1 this doesn't reset the pitch...only the yaw
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
         
            self.gimbal?.reset(completion: nil)
            
        }
        
    }
    
    func showAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(ok)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func showButtonNav(_ sender: Any) {
        
        buttonNavView.isHidden = !buttonNavView.isHidden
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        buttonNavView.isHidden = true
        
        if segue.identifier == "telemetryViewSegue" {
            
            if let vc = segue.destination as? TelemetryViewController {
                
                telemetryViewController = vc
                
            }
        }
        
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
        
        // Setting up gimbal delegate
        gimbal = fetchGimbal()
        
        if gimbal != nil {
            gimbal?.delegate = self
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
    
    func camera(_ camera: DJICamera, didGenerateNewMediaFile newMedia: DJIMediaFile) {
        
        // Here we can increment the photo counter
        currentPhotoCount = currentPhotoCount + 1
        telemetryViewController.photoCountLabel.text = "\(currentPhotoCount)/\(totalPhotoCount)"
        
        if currentPhotoCount == totalPhotoCount {
            self.panoFinished()
        }
        
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

extension CameraViewController: DJIGimbalDelegate {
    
}
