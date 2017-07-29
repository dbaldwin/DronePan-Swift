//
//  MapViewController.swift
//  DronePan-Swift
//
//  Created by Dennis Baldwin on 5/20/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import GoogleMaps
import DJISDK

class MapViewController: UIViewController {
    
    @IBOutlet weak var googleMapView: GMSMapView!
    
    @IBOutlet weak var buttonNavView: UIView!

    @IBOutlet weak var panoramaDetailView: UIView!
    @IBOutlet weak var panoramaAltitudeLabel: UILabel!
    @IBOutlet weak var panoramaLatLongLabel: UILabel!
    @IBOutlet weak var panoramaDateLabel: UILabel!
    @IBOutlet weak var panoramaRowsColsLabel: UILabel!
    @IBOutlet weak var panoramaYawTypeLabel: UILabel!
    @IBOutlet weak var panoramaSkyRowLabel: UILabel!
    
    var telemetryViewController: TelemetryViewController!
    
    var aircraftLocation: CLLocationCoordinate2D?
    var aircraftHeading: Double?
    
    // for the aircraft marker
    let aircraftMarker = GMSMarker()
    
    //for selectedMarker on map
    var selectedMarker = GMSMarker()
    
    // for BoundBox
    var bounds = GMSCoordinateBounds()
    
    // selectedPanorama for mission
    var selectedPanorama:Panorama?
    
    // All pano marker so we can enumerate and un-highlight
    var panoMarkers = [GMSMarker]()
    
    //for showing date in Panorama
    lazy var dateFormate:DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss"
        return formatter
    }()

    //MARK:- UIView Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 32, longitude: -98, zoom: 16)
        googleMapView.camera = camera
        googleMapView.isMyLocationEnabled = true
        googleMapView.mapType = GMSMapViewType.hybrid
        googleMapView.delegate = self
        googleMapView.settings.rotateGestures = false
        googleMapView.settings.tiltGestures = false
        googleMapView.settings.myLocationButton = true
        
        /*aircraftMarker.position = CLLocationCoordinate2D(latitude: 32, longitude: -98)
        aircraftMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        aircraftMarker.icon = UIImage(named: "aircraft_marker")
        aircraftMarker.map = googleMapView*/

        //initilizing the bounds
        //bounds = GMSCoordinateBounds(coordinate: self.aircraftMarker.position, coordinate: self.aircraftMarker.position)
        
        // Listen for location updates so we can display aircraft on the map
        let locationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation)
        DJISDKManager.keyManager()?.startListeningForChanges(on: locationKey!, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            
            if newValue != nil {
                
                if (self.aircraftLocation == nil) {
                    
                    self.aircraftLocation = (newValue!.value! as! CLLocation).coordinate
                    self.aircraftMarker.position = CLLocationCoordinate2D(latitude: 32, longitude: -98)
                    self.aircraftMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
                    self.aircraftMarker.icon = UIImage(named: "aircraft_marker")
                    self.aircraftMarker.zIndex = 1000
                    self.aircraftMarker.map = self.googleMapView
                    
                }
                self.aircraftLocation = (newValue!.value! as! CLLocation).coordinate
                self.aircraftMarker.position = self.aircraftLocation!
                
            }
        })
        
        let headingKey = DJIFlightControllerKey(param: DJIFlightControllerParamCompassHeading)
        DJISDKManager.keyManager()?.startListeningForChanges(on: headingKey!, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            
            if newValue != nil {
                
                if (self.aircraftLocation != nil) {
                    
                    self.aircraftHeading = newValue!.value! as? Double
                    self.aircraftMarker.rotation = self.aircraftHeading!
                    
                }
                
            }
            
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getAndShowSavedPanorama()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func getAndShowSavedPanorama() {
        // Get all saved pano from DB
        if let panoramas:[Panorama] = DataBaseHelper.sharedInstance.allRecordsSortByAttribute(inTable: "Panorama") as? [Panorama]
        {
            for panorama in panoramas
            {
                // Add pano marker in mapview
                let panoMarker = self.addPanoMarker(latitude:panorama.droneCurrentLatitude , longitude: panorama.droneCurrentLongitude,identifier:panorama.countId)
                panoMarkers.append(panoMarker)
            }
        }
        //including marker in boundBox
        self.googleMapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 270))
    }
    

    //MARK:- UIButton Action methods
    @IBAction func toggleNavButtonView(_ sender: Any) {
        buttonNavView.isHidden = !buttonNavView.isHidden
    }
    
    // Dismiss the view to get back to camera view
    @IBAction func cameraViewButtonClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func launchButtonClicked(_ sender: UIButton) {
        
        let alertView = UIAlertController(title: "Confirm", message: "Are you ready to start the panorama mission?", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler:{ (action) in
        })
        
        let start = UIAlertAction(title: "Start", style: UIAlertActionStyle.default, handler:{(action) in
            self.startPanoramaMission()
        })
        
        alertView.addAction(cancel)
        alertView.addAction(start)
        
        present(alertView, animated: true, completion: nil)
        
    }
    
    @IBAction func deletePanoButtonClicked(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Message", message: "Do you want to delete panorama", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Accept", style: .default) { (action) in
            
            if let coundID = self.selectedPanorama?.countId {
                
                let resultPredicate = NSPredicate(format: "countId = %@", "\(coundID)")
                if( DataBaseHelper.sharedInstance.deleteRecordInTable(inTable: "Panorama", wherePredicate: resultPredicate))
                {
                    debugPrint("Penorma deleted SuccsesFully")
                    self.selectedMarker.map = nil
                    self.googleMapView.sendSubview(toBack: self.panoramaDetailView)
                }
                else
                {
                    debugPrint("Somthing went wroung")
                }
                
            }
            
        }
        let noAction = UIAlertAction(title:"Cancel", style: .cancel, handler: nil)
        alert.addAction(yesAction)
        alert.addAction(noAction)
        self.present(alert, animated: true, completion: nil)
        
    }

    //MARK:- Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        buttonNavView.isHidden = true
        
        if segue.identifier == "telemetryViewSegue" {
            
            if let vc = segue.destination as? TelemetryViewController {
                
                telemetryViewController = vc
                
            }
        }
        
    }
    
    //MARK:- Private methods
    private func startPanoramaMission()
    {
        if let selectedPanorama = self.selectedPanorama {
            
            
            let destinationLocation = CLLocationCoordinate2D(latitude: selectedPanorama.droneCurrentLatitude, longitude: selectedPanorama.droneCurrentLongitude)
            
            
            //find how much aircraft want to move
            let heading = self.calculateHeading(forDestination: destinationLocation)
            
            debugPrint("Starting autonomous pano mission at \(destinationLocation.latitude), \(destinationLocation.longitude) and altitude \(selectedPanorama.altitude) and heading \(selectedPanorama.airCraftHeading)")
            
            if  let takeOffToCoordinate = DJIGoToAction(coordinate: destinationLocation) {
                
                if let yawAction  = DJIAircraftYawAction(relativeAngle: heading, andAngularVelocity: 20) {
                    
                    // Clear everything out
                    DJISDKManager.missionControl()?.stopTimeline()
                    DJISDKManager.missionControl()?.unscheduleEverything()
                    
                    // Need to only do this if aircraft is not in the air - leaving out for now
                    
                    if  let takeOffWithAltitude = DJIGoToAction(altitude: selectedPanorama.altitude) {
                        _ = DJISDKManager.missionControl()?.scheduleElement(takeOffWithAltitude)
                        
                    }
                    
                    let error =  DJISDKManager.missionControl()?.scheduleElement(takeOffToCoordinate)
                    
                    
                    //add heading for panorma
                    _ =  DJISDKManager.missionControl()?.scheduleElement(yawAction)
                    
                    // Build the pano logic
                    let pano = PanoramaController()
                    var elements : [DJIMissionControlTimelineElement] = []
                    
                    if  selectedPanorama.yawType == "1" {
                        elements = pano.buildPanoWithGimbalYaw(rows: Int(selectedPanorama.rows), cols: Int(selectedPanorama.columns), skyRow: selectedPanorama.skyRow == 1 ? true : false)
                    }else{
                        elements = pano.buildPanoWithAircraftYaw(rows: Int(selectedPanorama.rows), cols: Int(selectedPanorama.columns), skyRow: selectedPanorama.skyRow == 1 ? true : false, altitude: selectedPanorama.altitude)
                    }
                    //add newcode for photoCount
                    let totalPhotoCount = Int(selectedPanorama.rows) * Int(selectedPanorama.columns) + 1
                    AppDelegate.totalPhotoCount = totalPhotoCount
                    AppDelegate.currentPhotoCount = 0
                    // Initialize the photo counter
                    telemetryViewController.resetAndStartCounting(photoCount: totalPhotoCount)
                    
                    
                    let panoError = DJISDKManager.missionControl()?.scheduleElements(elements)
                    
                    if error != nil {
                        showAlert(title: "Error", message: String(describing: error?.localizedDescription))
                        return;
                    }else if panoError != nil {
                        showAlert(title: "Error", message: String(describing: panoError?.localizedDescription))
                        return;
                    }
                    
                    // Not necessary at the moment
                    //ProductCommunicationManager.shared.fetchFlightController()?.delegate = self
                    
                    DJISDKManager.missionControl()?.startTimeline()
                    
                }
            }
        }
        
    }
    
    
    private func calculateHeading(forDestination:CLLocationCoordinate2D)-> Double
    {
        // Find the bearing for destination location if its not zero will be taken into consideration
        let bearing = self.getBearingBetweenTwoPoints1(point1:  CLLocation(latitude: (self.aircraftLocation?.latitude ?? 0.0), longitude: (self.aircraftLocation?.longitude ?? 0.0)), point2:  CLLocation(latitude: forDestination.latitude, longitude: forDestination.longitude))
        if bearing == 0
        {
            //Bearing is zero so we need to take the current aircraft heading into calculation to achieve the saved heading
            return (selectedPanorama!.airCraftHeading - (self.aircraftHeading ?? 0) )
        }
        else
        {
            //Bearing is not zero so current aircradt heeading will be same as bearing will be taken into calculation for achieving the saved heading
            return (selectedPanorama!.airCraftHeading - bearing)
        }
        
        //For e.g
        /*
         
         {
         
         
         headingToMove = savedHeading - currentAircraftHeading (Bearing is zero)
         
         case 1. Saved heading is 50, and Bearing is zero (destination location is same as current location or current location and destination location have zero bearing related to north) & aircraft heading is 90 so we need to go 40 anticlockwise to achieve heading 50.
         
         Result = 50 - 90 => -40 so this will rotate the aircraft 40 degree anticlockwise
         
         case 2. Saved heading is 90, and Bearing is zero (destination location is same as current location or current location and destination location have zero bearing related to north) & aircraft heading is 90 so we need to go 40 anticlockwise to achieve heading 50.
         
         Result = 90 - 50 => 40 so this will rotate the aircraft 40 degree clockwise
         
         
         }
         
         {
         
         case 3. Bearing is not zero, so when aircraft will fly to destination from current location so aircraft will change its yaw according to destination i.e bearing , So this bearing will be aircraft current heading after reaching the destination. So calculations will be same as in above cases but here bearing is the current heading of aircraft.
         
         }
         
         */
    }

    
    private func addPanoMarker(latitude:CLLocationDegrees,longitude:CLLocationDegrees,identifier:Any) -> GMSMarker{
        let panoMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        panoMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        panoMarker.icon = UIImage(named: "pano_marker")
        panoMarker.map = googleMapView
        panoMarker.userData = identifier
        bounds = bounds.includingCoordinate(panoMarker.position)
        
        return panoMarker
    }
    
    func unHighlightPanoMarkers() {
        
        for marker in panoMarkers {

            marker.icon = UIImage(named: "pano_marker")
            
        }
        
    }
    
    
    
}

//MARK:- Map View Delegate
extension MapViewController: GMSMapViewDelegate {
    
    // Map tapped
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        mapView.sendSubview(toBack: self.panoramaDetailView)
        unHighlightPanoMarkers()
    }
    
    // Pano marker tapped
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        debugPrint("You tapped at \(marker.position.latitude), \(marker.position.longitude)")
        debugPrint("identifier here\(marker.userData ?? "")")
        
        //get selected marker Value
        if let p_markerId = marker.userData
        {
            // Un-highlight all pano markers
            self.unHighlightPanoMarkers()
            
            // Highlight the selected marker
            marker.icon = UIImage(named: "pano_marker_selected")
            
            if let tappedPanorama:[Panorama] = DataBaseHelper.sharedInstance.allRecordsSortByAttribute(inTable: "Panorama", whereKey: "countId", contains: p_markerId) as? [Panorama]
            {
              if let firstObject = tappedPanorama.first
                {
                    self.selectedPanorama = firstObject
                    self.selectedMarker = marker
                    mapView.bringSubview(toFront: self.panoramaDetailView)
                    self.panoramaLatLongLabel.text = "Lat: \(firstObject.droneCurrentLatitude), Lon: \(firstObject.droneCurrentLongitude)"
                    self.panoramaDateLabel.text = dateFormate.string(from: firstObject.captureDate! as Date)
                    self.panoramaAltitudeLabel.text = "Altitude: \(firstObject.altitude) m"
                    self.panoramaRowsColsLabel.text = "Rows: \(firstObject.rows), Columns: \(firstObject.columns)"
                    self.panoramaYawTypeLabel.text = "Yaw type: \(firstObject.yawType == "0" ? "Aircraft" : "Gimbal")"
                    self.panoramaSkyRowLabel.text = "Sky row: \(firstObject.skyRow == 1 ? "Enabled" : "Disabled")"
                    
                    debugPrint("panoramalongitude:\(firstObject.droneCurrentLongitude)\ndroneCurrentLatitude\(firstObject.droneCurrentLatitude)")
                }
            }
            return true
        }
        else
        {
            self.selectedPanorama = nil
            mapView.sendSubview(toBack: self.panoramaDetailView)
        }
      return true
    }

}


//MARK:- Find Bearing
extension MapViewController{
    
    func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }
    
    func getBearingBetweenTwoPoints1(point1 : CLLocation, point2 : CLLocation) -> Double {
        
        let lat1 = degreesToRadians(degrees: point1.coordinate.latitude)
        let lon1 = degreesToRadians(degrees: point1.coordinate.longitude)
        
        let lat2 = degreesToRadians(degrees: point2.coordinate.latitude)
        let lon2 = degreesToRadians(degrees: point2.coordinate.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return radiansToDegrees(radians: radiansBearing)
    }
}


//MARK:- Dji Gimble Delegate
/*extension MapViewController : DJIFlightControllerDelegate {

    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        
    }
}*/

