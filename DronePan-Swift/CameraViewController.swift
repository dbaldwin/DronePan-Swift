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
    @IBOutlet weak var panoButton: UIButton!
    @IBOutlet weak var sdkVersionLabel: UILabel!
    
    var aircraftLocation: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    var aircraftAltitude:Double = 0
    var aircraftHeading:Double = 0
    
    var telemetryViewController: TelemetryViewController!
    
    var totalPhotoCount: Int = 7 // This is the default 4 rows and 7 columns with 1 nadir
    var currentPhotoCount: Int = 0
    
    // Handles the pano status
    var panoInProgress: Bool = false
    
    var gimbal: DJIGimbal?
    
       
    // Following this approach from the DJI SDK example
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // Notification for updating drone model label
        NotificationCenter.default.addObserver(self, selector: #selector(productConnected), name: NSNotification.Name(rawValue: "gotConnection"), object: nil)
        
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
            
            if error != nil {
                
                self.showAlert(title: "Timeline Error", message: String(describing: error!))
                self.resetPanoProgress()
                
            }
            
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
                print("Mission stopped successfully")
            case .stopError:
                print("Stop error")
            case .finished:
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
        
        // Put this here so it only loads once and prevent it from loading again when a user switches to another screen and back
        sdkVersionLabel.text = "SDK: \(DJISDKManager.sdkVersion())"
    }
    
    override var prefersStatusBarHidden: Bool {
        
        return true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startPano(_ sender: Any) {
        
        // Give the user the start pano option
        if !panoInProgress {
            
            let alertView = UIAlertController(title: "Confirm", message: "Are you ready to start the panorama sequence?", preferredStyle: .alert)
            
            let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler:{ (action) in
            })
            
            let start = UIAlertAction(title: "Start", style: UIAlertActionStyle.default, handler:{(action) in
                
                // Start the pano
                self.startPanoNow()
                
            })
            
            alertView.addAction(cancel)
            alertView.addAction(start)
            
            present(alertView, animated: true, completion: nil)
        
        // Give the user the stop pano option
        } else {
         
            let alertView = UIAlertController(title: "Confirm", message: "Are you sure you want to stop the panorama sequence?", preferredStyle: .alert)
            
            let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler:{ (action) in
            })
            
            let stop = UIAlertAction(title: "Stop", style: UIAlertActionStyle.default, handler:{(action) in
                
                // Stop the mission
                DJISDKManager.missionControl()?.stopTimeline()
                
                // Reset the pano progress
                self.resetPanoProgress()
                
            })
            
            alertView.addAction(cancel)
            alertView.addAction(stop)
            
            present(alertView, animated: true, completion: nil)
            
        }
    
    
    
    }
    
    func startPanoNow() {
        
        // Change the start button to a stop button
        self.panoButton.setImage(UIImage(named: "stop_photo_button"), for: UIControlState.normal)
        self.panoButton.setImage(UIImage(named: "stop_photo_button_pressed"), for: UIControlState.highlighted)
        
        // Set the pano status
        panoInProgress = true
        
        let defaults = UserDefaults.standard
        
        // We should figure out how to update these immediately after the settings are saved and get rid of all this code
        var rows:Int = defaults.integer(forKey: "rows")
        
        if rows == 0 {
            rows = 4
            //save row if not set
            defaults.set(rows, forKey: "rows")
        }
        
        var cols:Int = defaults.integer(forKey: "columns")
        
        if cols == 0 {
            cols = 7
            //save colums if not set
            defaults.set(cols, forKey: "columns")
        }
        
        let skyRow:Int = defaults.integer(forKey: "skyRow")
        
        if skyRow == 1 {
            
            rows = rows + 1
            
            //save skyRow if not set
            defaults.set(skyRow, forKey: "skyRow")
        }
        
        let yawType = defaults.integer(forKey: "yawType") 
        print(yawType)
        
        currentPhotoCount = 0
        print("Total number of rows \(rows), \(cols),\(skyRow),\(String(describing: gimbal))")
        // Generate unique id for a panorama
        let arrayValue = DataBaseHelper.sharedInstance.allRecordsSortByAttribute(inTable: "Panorama")
        
        
        // Save pano to database
        let panoramaDict:[String:Any] = ["captureDate":Date(),"rows":rows,"columns":cols,"droneCurrentLatitude":self.aircraftLocation.latitude,"droneCurrentLongitude":self.aircraftLocation.longitude,"skyRow":skyRow,"countId":(arrayValue.count + 1),"yawType":"\(yawType)","altitude":aircraftAltitude,"airCraftHeading":self.aircraftHeading]
        
        //  let panoramaDict:[String:Any] = ["captureDate":Date(),"rows":rows,"columns":cols,"droneCurrentLatitude":32.25686,"droneCurrentLongitude":-120.26,"skyRow":skyRow,"countId":(arrayValue.count + 1),"yawType":"\(yawType)","altitude": 100,"airCraftHeading":self.aircraftHeading]
        
        // let panoramaDict:[String:Any] = ["captureDate":Date(),"rows":rows,"columns":cols,"droneCurrentLatitude":22.78,"droneCurrentLongitude":74.2485,"skyRow":skyRow,"countId":(arrayValue.count + 1),"yawType":"\(yawType)","altitude":10,"airCraftHeading":-120]
        debugPrint(panoramaDict)
        
        // Write to database
        _ = DataBaseHelper.sharedInstance.insertRecordInTable(tableName: "Panorama", attributes: panoramaDict)
        
        totalPhotoCount = rows * cols + 1
        //set PhotoCount
        AppDelegate.totalPhotoCount = totalPhotoCount
        AppDelegate.currentPhotoCount = 0
        
        // Initialize the photo counter
        telemetryViewController.resetAndStartCounting(photoCount: totalPhotoCount)
        
        // Trying to set virtual stick mode the old fashioned way
        let fc = fetchFlightController()
        
        fc?.setVirtualStickModeEnabled(true, withCompletion: { (error: Error?) in
            
            if error != nil {
                self.showAlert(title: "Virtual Stick Error", message: "Error setting virtual stick mode.")
            }
            
        })
        
        // Force virtual stick mode
        /*guard let virtualStickKey = DJIFlightControllerKey(param: DJIFlightControllerParamVirtualStickAdvancedControlModeEnabled) else {
            return;
        }
        
        DJISDKManager.keyManager()?.setValue(NSNumber(value: true), for: virtualStickKey, withCompletion: { (error: Error?) in
            if error != nil {
                self.showAlert(title: "Virtual Stick Error", message: "Error setting virtual stick mode.")
            }
        })*/
        
        // Check to see if timeline is running before we try to stop
        if let isRunning = DJISDKManager.missionControl()?.isTimelineRunning, isRunning == true {
            
            DJISDKManager.missionControl()?.stopTimeline()
            
        }
        
        // Remove timeline elements
        DJISDKManager.missionControl()?.unscheduleEverything()
        
        // Reset the gimbal
        //gimbal?.reset(completion: nil)
        
        // Build the pano logic
        let pano = PanoramaController()
        let error = DJISDKManager.missionControl()?.scheduleElements(pano.buildPanoAtCurrentLocation(altitude: self.aircraftAltitude))
        
        if error != nil {
            showAlert(title: "Error Building Pano", message: String(describing: error))
            resetPanoProgress()
            return;
        }
        
        DJISDKManager.missionControl()?.startTimeline()
        
    }
    
    // Reset the pano progress if an error occurs
    func resetPanoProgress() {
        panoInProgress = false
        self.panoButton.setImage(UIImage(named: "photo_button"), for: UIControlState.normal)
        self.panoButton.setImage(UIImage(named: "photo_button_pressed"), for: UIControlState.highlighted)
    }
    
    // Navigation menu
    @IBAction func showButtonNav(_ sender: Any) {
        
        buttonNavView.isHidden = !buttonNavView.isHidden
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        buttonNavView.isHidden = true
        
        if segue.identifier == "telemetryViewSegue" {
            
            if let vc = segue.destination as? TelemetryViewController {
                
                telemetryViewController = vc
                vc.delegate = self
                
            }
        }
        
    }
    
    func productConnected(notification: NSNotification) {
        
        guard let newProduct = DJISDKManager.product() else {
            print("Product is connected but DJISDKManager.product is nil -> something is wrong")
            return;
        }
        
        // Display SDK and model
        sdkVersionLabel.text = "SDK: \(DJISDKManager.sdkVersion()), Model: \(newProduct.model!)"
        
        //Updates the product's firmware version - COMING SOON
        newProduct.getFirmwarePackageVersion{ (version:String?, error:Error?) -> Void in
            
            print("Firmware package version is: \(version ?? "Unknown")")
        }
        
        //Updates the product's connection status
        print("Product Connected")
        
        // Trying to manage this in telemetry view controller
        // Setting up camera delegate
        /*let camera: DJICamera? = fetchCamera()
        
        if camera != nil {
            print("camera delegate is setup")
            camera?.delegate = self
        }*/
        
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

// Keep track of the current aircraft location
extension CameraViewController: DJIFlightControllerDelegate {
    
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        
        if let cordinate = state.aircraftLocation?.coordinate
        {
            self.aircraftLocation = cordinate
        }

        self.aircraftAltitude = state.altitude

        //Change aircraft heading
        if let heading = fc.compass?.heading
        {
            self.aircraftHeading = heading
        }
        // Send the location update to the map view
        //self.cameraVCDelegate?.updateAircraftLocation(location: self.aircraftLocation, heading: self.aircraftHeading)
        
    }
    
}

extension CameraViewController: DJIGimbalDelegate {
    
}

extension CameraViewController: TelemetryViewControllerDelegate {
    
    // Pano is complete so reset some vars
    func panoComplete() {
        self.resetPanoProgress()
    }
    
}
