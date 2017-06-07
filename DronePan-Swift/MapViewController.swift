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
        
        // Add the aircraft marker
        let aircraftMarker = GMSMarker()
        aircraftMarker.position = CLLocationCoordinate2D(latitude: 32, longitude: -98)
        aircraftMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        aircraftMarker.icon = UIImage(named: "aircraft_marker")
        aircraftMarker.map = googleMapView
        
        // Add the pano marker
        let panoMarker = GMSMarker()
        panoMarker.position = CLLocationCoordinate2D(latitude: 32.001, longitude: -98.001)
        panoMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        panoMarker.icon = UIImage(named: "pano_marker")
        panoMarker.map = googleMapView
        
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
    
    @IBAction func toggleNavButtonView(_ sender: Any) {
        
        buttonNavView.isHidden = !buttonNavView.isHidden
        
        print(buttonNavView.isHidden)
        
        
    }
    
    // Dismiss the view to get back to camera view
    @IBAction func cameraViewButtonClicked(_ sender: Any) {

        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        buttonNavView.isHidden = true
        
    }
    
}

extension MapViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        print("You tapped at \(marker.position.latitude), \(marker.position.longitude)")
        
        return true
    }

}
