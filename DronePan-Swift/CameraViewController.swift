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
    
    //======================================
    //MARK: =========== Properties ========
    //======================================
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var hamburgerButton: UIButton!
    @IBOutlet weak var buttonNavView: UIView!
    @IBOutlet weak var sdkVersionLabel: UILabel!

    var aircraftLocation: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    var aircraftAltitude:Double = 0.0
    var aircraftHeading:Double = 0.0
    var telemetryViewController: TelemetryViewController!
    var totalPhotoCount: Int = 7 // This is the default 4 rows and 7 columns with 1 nadir
    var currentPhotoCount: Int = 0
    var gimbal: DJIGimbal?
    
   
    
    //======================================
    //MARK: =========== View's life cycle ========
    //======================================
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
                
                self.showAlert(title: "Error", message: String(describing: error!))
                
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
                print("Stopped")
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
        sdkVersionLabel.text = "SDK: \(DJISDKManager.sdkVersion())"
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //======================================
    //MARK: =========== Button Action ========
    //======================================
    @IBAction func startPano(_ sender: Any) {
        
        let alertView = UIAlertController(title: "Confirm", message: "Are you ready to start the panorama sequence?", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler:nil)
        let start = UIAlertAction(title: "Start", style: UIAlertActionStyle.default, handler:{(action) in
            self.startPanoNow()
        })
        alertView.addAction(cancel)
        alertView.addAction(start)
        present(alertView, animated: true, completion: nil)
    }
    
    func startPanoNow()
    {
        
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

        
        // Save pano to database(add timeStamp for uniqueness with firebase)
        let panoramaDict:[String:Any] = [SerializationKeys.timeStamp:Date().timeIntervalSince1970,
                                          SerializationKeys.rows:rows,
                                          SerializationKeys.columns:cols,
                                         SerializationKeys.airCraftLatitude:self.aircraftLocation.latitude,
                                         SerializationKeys.airCraftLongitude:self.aircraftLocation.longitude,
                                         SerializationKeys.skyRow:skyRow,
                                         SerializationKeys.yawType:"\(yawType)",
                                         SerializationKeys.airCraftAltitude:aircraftAltitude,
                                         SerializationKeys.airCraftHeading:self.aircraftHeading]
        
    
       /* let panoramaDict:[String:Any] = [SerializationKeys.timeStamp:Date().timeIntervalSince1970,
                                         SerializationKeys.rows:rows,
                                         SerializationKeys.columns:cols,
                                         SerializationKeys.airCraftLatitude:64.25686,
                                         SerializationKeys.airCraftLongitude:-120.26,
                                         SerializationKeys.skyRow:skyRow,
                                         SerializationKeys.yawType:"\(yawType)",
            SerializationKeys.airCraftAltitude:50.0,
            SerializationKeys.airCraftHeading:-135.0]*/

        
        debugPrint(panoramaDict)
        
        
        //save to fireBase if user exist
        if (userID != nil)
        {
            let panorma = PanoramaModel.init(panoramaDict as Dictionary<String, AnyObject>)
            self.addPanoramaToCloudStoraga(panorama:[panorma])
        }
        else// Write to database
        {
             _ = DataBaseHelper.sharedInstance.insertRecordInTable(tableName: "Panorama", attributes: panoramaDict)
        }
 
        totalPhotoCount = rows * cols + 1
        //set PhotoCount
        AppDelegate.totalPhotoCount = totalPhotoCount
        AppDelegate.currentPhotoCount = 0
        
        // Initialize the photo counter
        telemetryViewController.resetAndStartCounting(photoCount: totalPhotoCount)
        
        // Clear out previous missions
        DJISDKManager.missionControl()?.stopTimeline()
        DJISDKManager.missionControl()?.unscheduleEverything()
        
        // Reset the gimbal
        gimbal?.reset(completion: nil)
        
        // Build the pano logic
        let pano = PanoramaController()
        let error = DJISDKManager.missionControl()?.scheduleElements(pano.buildPanoAtCurrentLocation(altitude: self.aircraftAltitude))
        
        if error != nil {
            showAlert(title: "Error", message: String(describing: error))
            return;
        }
        
        DJISDKManager.missionControl()?.startTimeline()
    }
    
    @IBAction func showButtonNav(_ sender: Any) {
        
        buttonNavView.isHidden = !buttonNavView.isHidden
        
    }
    
    //======================================
    //MARK: =========== Navigation ========
    //======================================
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        buttonNavView.isHidden = true
        
        if segue.identifier == "telemetryViewSegue" {
            
            if let vc = segue.destination as? TelemetryViewController {
                
                telemetryViewController = vc
                
            }
        }
        
    }
    
    //======================================
    //MARK: =========== Other function ========
    //======================================
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

//======================================
//MARK: =========== DJIVideoFeedListener ========
//======================================
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

//======================================
//MARK: =========== DJIFlightControllerDelegate ========
//======================================
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

//======================================
//MARK: =========== DJIGimbalDelegate ========
//======================================
extension CameraViewController: DJIGimbalDelegate {
    
}
