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
    
    @IBOutlet weak var panpramaDetailView: UIView!
    @IBOutlet weak var panoramaPitchLabel: UILabel!
    @IBOutlet weak var panoramaHeadingLabel: UILabel!
    @IBOutlet weak var panormaAltitudeLabel: UILabel!
    @IBOutlet weak var panoramaLatLongLabel: UILabel!
    @IBOutlet weak var panoramaDateLabel: UILabel!
    
    // for the aircraft marker
    let aircraftMarker = GMSMarker()
    
    // for BoundBox
    var bounds = GMSCoordinateBounds()
    
    //selectedPanorma for mission
    var selectedPanorma:Panorama?
    
    //for showingDate in Panorama
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
        
        aircraftMarker.position = CLLocationCoordinate2D(latitude: 32, longitude: -98)
        aircraftMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        aircraftMarker.icon = UIImage(named: "aircraft_marker")
        aircraftMarker.map = googleMapView
        
        // Add the pano marker
        /*let panoMarker = GMSMarker()
        panoMarker.position = CLLocationCoordinate2D(latitude: 32.001, longitude: -98.001)
        panoMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        panoMarker.icon = UIImage(named: "pano_marker")
        panoMarker.map = googleMapView*/
        
        //initilizing the bounds
        
        bounds = GMSCoordinateBounds(coordinate: self.aircraftMarker.position, coordinate: self.aircraftMarker.position)
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
        if let totalpanorma:[Panorama] = DataBaseHelper.sharedInstance.allRecordsSortByAttribute(inTable: "Panorama") as? [Panorama]
        {
            for panorma in totalpanorma
            {
                // Add pano marker in mapview
                self.addPanoMarker(latitude:panorma.dronCurrentLatitude , longitude: panorma.dronCurrentLongitude,identifier:panorma.countId)
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
        let alertView = UIAlertController(title: "", message:"Are you ready to begin the panorama mission?", preferredStyle: .alert)
        
        let yes = UIAlertAction(title: "Yes", style: UIAlertActionStyle.cancel, handler:{ (action) in
            self.startPanormaMission()
        })
        alertView.addAction(yes)
        let no = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler:nil)
        alertView.addAction(no)
        present(alertView, animated: true, completion: nil)
    }
    
    //MARK:- Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        buttonNavView.isHidden = true
    }

    //MARK:- Private methods
    private func startPanormaMission()
    {
        if let selectedPanorma = self.selectedPanorma
        {
            let destinationLocation = CLLocationCoordinate2D(latitude: selectedPanorma.dronCurrentLatitude, longitude: selectedPanorma.dronCurrentLongitude)
            if  let takeOffToCoordinate = DJIGoToAction.init(coordinate: destinationLocation) {
                
                DJISDKManager.missionControl()?.scheduleElement(DJITakeOffAction.init())

                var timeActionsCount = 0
                if  let takeOffWithAltitude = DJIGoToAction.init(altitude: selectedPanorma.altitude) {
                    let error = DJISDKManager.missionControl()?.scheduleElement(takeOffWithAltitude)
                    if error == nil {
                        timeActionsCount = 1
                    }
                }

                let error =  DJISDKManager.missionControl()?.scheduleElement(takeOffToCoordinate)
                if error == nil {
                    timeActionsCount += 1
                }
                
                // Build the pano logic
                let pano = PanoramaController()
                var elements : [DJIMissionControlTimelineElement] = []
                
                if  selectedPanorma.yawType == "1" {
                    elements = pano.buildPanoWithGimbalYaw(rows: Int(selectedPanorma.rows), cols: Int(selectedPanorma.columns), skyRow: selectedPanorma.skyRow == 1 ? true : false)
                }else{
                    elements = pano.buildPanoWithAircraftYaw(rows: Int(selectedPanorma.rows), cols: Int(selectedPanorma.columns), skyRow: selectedPanorma.skyRow == 1 ? true : false)
                }
                
                let panoError = DJISDKManager.missionControl()?.scheduleElements(elements)
                
                if error != nil {
                    showAlert(title: "Error", message: String(describing: error?.localizedDescription))
                    return;
                }else if panoError != nil {
                    showAlert(title: "Error", message: String(describing: panoError?.localizedDescription))
                    return;
                }
                
                ProductCommunicationManager.shared.fetchFlightController()?.delegate = self
                
                DJISDKManager.missionControl()?.startTimeline()
                var finishedEventCount = 0
                let totalEventCount = elements.count + 1 + timeActionsCount //{ (Panoromo Mission Elements) + (Take off mission element + Go to Alitude + Go To Location Element) }
                DJISDKManager.missionControl()?.addListener(self, toTimelineProgressWith: { (timeLineEvent, missionControl, error, other) in
                    
                    self.panoramaHeadingLabel.text = "Heading:\(ProductCommunicationManager.shared.fetchFlightController()?.compass?.heading ?? 0)"
                    
                    switch(timeLineEvent)
                    {
                    case .started:
                        print(missionControl  ?? "")
                        break
                    case .progressed:
                        print(missionControl  ?? "")
                        break
                    case .finished:
                        finishedEventCount += 1
                        if finishedEventCount == totalEventCount {
                            self.showAlert(title: "Panorama complete!", message: "You can now take manual control of your aircraft.")
                        }
                        break
                    default:
                        break
                    }
                    
                })
                
            }
        }
        
    }
    
    private func addPanoMarker(latitude:CLLocationDegrees,longitude:CLLocationDegrees,identifier:Any){
        let panoMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        panoMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        panoMarker.icon = UIImage(named: "pano_marker")
        panoMarker.map = googleMapView
        panoMarker.userData = identifier
        bounds = bounds.includingCoordinate(panoMarker.position)
    }
    
    
}

//MARK:- Map View Delegate
extension MapViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        debugPrint("You tapped at \(marker.position.latitude), \(marker.position.longitude)")
        debugPrint("identifier here\(marker.userData ?? "")")
        
        //get selected marker Value
        if let p_markerId = marker.userData
        {
            if let tappedPanorama:[Panorama] = DataBaseHelper.sharedInstance.allRecordsSortByAttribute(inTable: "Panorama", whereKey: "countId", contains: p_markerId) as? [Panorama]
            {
              if let firstObject = tappedPanorama.first
                {
                    self.selectedPanorma = firstObject
                    mapView.bringSubview(toFront: self.panpramaDetailView)
                    self.panoramaLatLongLabel.text = "Lat:\(firstObject.dronCurrentLatitude), Lon:\(firstObject.dronCurrentLongitude)"
                    self.panoramaDateLabel.text = dateFormate.string(from: firstObject.captureDate! as Date)
                    self.panormaAltitudeLabel.text = "Altitude:0"
                    self.panoramaHeadingLabel.text = "Heading:0"
                    self.panoramaPitchLabel.text = "Pitch:0"
                    debugPrint("panoramalongitute:\(firstObject.dronCurrentLongitude)\ndronCurrentLatitude\(firstObject.dronCurrentLatitude)")
                }
            }
            return true
        }
        else
        {
            self.selectedPanorma = nil
            mapView.sendSubview(toBack: self.panpramaDetailView)
        }
      return true
    }

}

//MARK:- Dji Gimble Delegate
extension MapViewController : DJIFlightControllerDelegate {

    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        self.panoramaPitchLabel.text = "Pitch:\(state.attitude.pitch)"
        self.panormaAltitudeLabel.text = "Altitude:\(state.altitude)"
    }
}
