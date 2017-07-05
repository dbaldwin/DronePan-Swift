//
//  MapViewController.swift
//  DronePan-Swift
//
//  Created by Dennis Baldwin on 5/20/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import GoogleMaps

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
    
    //for showingDate in Panorama
    lazy var dateFormate:DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss"
        return formatter
    }()
    


    override func viewDidLoad() {
        super.viewDidLoad()
        
        //let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 32, longitude: -98, zoom: 16)
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
       
        let alert = UIAlertController(title: "Coming Soon", message: "We are currently working on waypoint functionality. This is just a static view and will be active in an upcoming beta.", preferredStyle: UIAlertControllerStyle.alert)
        let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(ok)
        
        present(alert, animated: true, completion: nil)
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
    

      
    @IBAction func toggleNavButtonView(_ sender: Any) {
        
        buttonNavView.isHidden = !buttonNavView.isHidden
        
        debugPrint(buttonNavView.isHidden)
        
        
    }
    
    // Dismiss the view to get back to camera view
    @IBAction func cameraViewButtonClicked(_ sender: Any) {

        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        buttonNavView.isHidden = true
        
    }
    
    @IBAction func launchButtonClicked(_ sender: UIButton) {
        
        
    }
    
    func  addPanoMarker(latitude:CLLocationDegrees,longitude:CLLocationDegrees,identifier:Any)
        
    {
        
        let panoMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        
        panoMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        
        panoMarker.icon = UIImage(named: "pano_marker")
        
        panoMarker.map = googleMapView
        
        panoMarker.userData = identifier
        
        bounds = bounds.includingCoordinate(panoMarker.position)
        
    }
    

}

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
                    mapView.bringSubview(toFront: self.panpramaDetailView)
                    self.panoramaLatLongLabel.text = "Lat:\(firstObject.dronCurrentLatitude), Lon:\(firstObject.dronCurrentLongitude)"
                    self.panoramaDateLabel.text = dateFormate.string(from: firstObject.captureDate! as Date)
                    self.panormaAltitudeLabel.text = "rows:\(firstObject.rows)"
                    self.panoramaHeadingLabel.text = "columns:\(firstObject.columns)"
                    self.panoramaPitchLabel.text = "skyRow:\(firstObject.columns)"
                    debugPrint("panoramalongitute:\(firstObject.dronCurrentLongitude)\ndronCurrentLatitude\(firstObject.dronCurrentLatitude)")
                }
            }
        }
    return true
    }

}
