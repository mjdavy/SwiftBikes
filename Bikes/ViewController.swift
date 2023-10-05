//
//  ViewController.swift
//  Bikes
//
//  Created by Martin Davy on 7/10/18.
//  Copyright © 2018 Martin Davy. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {

    let baseUrl = "https://api.citybik.es"
    let bikeNetworks = BikeNetworks()
    let locationManager = CLLocationManager()
    let regionRadius: CLLocationDistance = 10000
    var timer = Timer()
    var locationEstablished = false
    var currentLocation: CLLocation?
    var myNetwork : String?
    var myUrl: URL?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var myLocationButton: UIButton!
    @IBOutlet weak var nearestBikeButton: UIButton!
    @IBOutlet weak var nearestDockButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enableLocationServices()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func centerMapOnUserButtonClicked() {
        mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: true)
    }
    
    func startTimer() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { (mytimer) in
            
            guard let url = self.myUrl else {
                return;
            }
            
            self.bikeNetworks.startLoad(url: url, completionHandler: {(bikeNetwork : [String:Network]?) in
                guard let myNetwork = bikeNetwork?["network"], let myStations = myNetwork.stations else {
                    return
                }
                
                var stationDictionary = [String:Network.Station]()
                for station in myStations {
                    stationDictionary[station.id] = station
                }
                
                var modified = [StationPin]()
                for annotation in self.mapView.annotations as [MKAnnotation]
                {
                    guard let pin = annotation as? StationPin else
                    {
                        continue
                    }
                    
                    if let station = stationDictionary[pin.id]
                    {
                        if pin.freeBikes != station.free_bikes || pin.freeSlots != station.empty_slots
                        {
                            pin.freeBikes = station.free_bikes
                            pin.freeSlots = station.empty_slots
                            modified.append(pin)
                        }
                    }
                }
                
                if modified.count > 0 {
                    DispatchQueue.main.async {
                        for pin in modified {
                            self.mapView.removeAnnotation(pin)
                            self.mapView.addAnnotation(pin)
                        }
                    }
                }
            })
            
        })
    }
    
    @objc func nearestBikeButtonClicked()
    {
        selectNearestPin(location: self.currentLocation) { (annotation) -> Bool in
            guard let pin = annotation as? StationPin
            else {
                return false
            }
            return pin.freeBikes > 0
        }
    }
    
    @objc func nearestDockButtonClicked() {
        selectNearestPin(location: self.currentLocation) { (annotation) -> Bool in
            guard let pin = annotation as? StationPin
            else {
                return false
            }
            return pin.freeSlots > 0
        }
    }
    
    func selectNearestPin(location: CLLocation?, query: (MKAnnotation) -> Bool)
    {
        if let mylocation = location {
            let matching = mapView.annotations.filter(query).sorted { (item1, item2) -> Bool in
                let pin1 = item1 as! StationPin
                let pin2 = item2 as! StationPin
                let distance1 = mylocation.distance(from: CLLocation(latitude: pin1.coordinate.latitude, longitude: pin1.coordinate.longitude))
                let distance2 = mylocation.distance(from: CLLocation(latitude: pin2.coordinate.latitude, longitude: pin2.coordinate.longitude))
                return distance1 < distance2
            }
            
            if let nearestPin = matching.first {
                mapView.deselectAnnotation(nearestPin, animated: false)
                mapView.selectAnnotation(nearestPin, animated: true)
            }
        }
    }
    
    func enableLocationBasedFeatures()
    {
        mapView.showsUserLocation = true
        myLocationButton.addTarget(self, action: #selector(ViewController.centerMapOnUserButtonClicked), for:.touchUpInside)
        nearestBikeButton.addTarget(self, action: #selector(ViewController.nearestBikeButtonClicked), for: .touchUpInside)
        nearestDockButton.addTarget(self, action: #selector(ViewController.nearestDockButtonClicked), for: .touchUpInside)
        mapView.register(StationPinView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        startReceivingLocationChanges()
        startTimer()
    }
    
    func enableLocationServices()
    {
        locationManager.delegate = self
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            // Disable location features
            //disableMyLocationBasedFeatures()
            break
            
        case .authorizedWhenInUse:
            // Enable basic location features
            enableLocationBasedFeatures()
            break
            
        case .authorizedAlways:
            // Enable any of your app's location features
            enableLocationBasedFeatures()
            break
        @unknown default:
            break
        }
    }
    
    func requireLocationBasedFeatures()
    {
        let alertController = UIAlertController(title: "Location Access Disabled", message: "This app requires location services to work. Please enable location services in Settings.", preferredStyle: .alert)
                    
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openSettingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(openSettingsAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        switch status {
            case .restricted, .denied:
                // Encourage the user to change location settings
                requireLocationBasedFeatures()
                break
            
            case .authorizedWhenInUse:
                // Enable only your app's when-in-use features.
                enableLocationBasedFeatures()
                break
            
            case .authorizedAlways:
                // Enable any of your app's location services.
                enableLocationBasedFeatures()
                break
            
            case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if (!locationEstablished)
        {
            if (!locationEstablished)
            {
                self.currentLocation = locations.last!
                
                let url = URL(string:self.baseUrl + "/v2/networks")!
                
                bikeNetworks.startLoad(url: url, completionHandler: {(result : Networks?) in
                    if let allNetworks = result,
                        let myNetwork = self.bikeNetworks.FindClosestBikeNetwork(networks: allNetworks, location: self.currentLocation!),
                        let myUrl = URL(string:self.baseUrl + myNetwork)
                    {
                        self.addBikeLocationsToMap(url: myUrl)
                        self.myUrl = myUrl
                        self.myNetwork = myNetwork
                    }
                })
            }
            
            locationEstablished = true;
        }
        
        locationEstablished = true;
    }
    
    func startReceivingLocationChanges()
    {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus != .authorizedWhenInUse && authorizationStatus != .authorizedAlways
        {
            // User has not authorized access to location information.
            return
        }
        
        // Configure and start the service.
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1.0  // In meters.
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    func centerMapOnLocation(location: CLLocation)
    {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func addBikeLocationsToMap(url: URL)
    {
        bikeNetworks.startLoad(url: url, completionHandler: {(bikeNetwork : [String:Network]?) in
            if let myNetwork = bikeNetwork?["network"],
                let myStations = myNetwork.stations {
                
                DispatchQueue.main.async {
                    for station in myStations {
                        let stationPin = StationPin(station: station)
                        self.mapView.addAnnotation(stationPin)
                    }
                   
                    let networkLocation = CLLocation(latitude: (myNetwork.location.latitude), longitude: (myNetwork.location.longitude))
                    self.centerMapOnLocation(location: networkLocation)
                }
            }
        })
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        let location = view.annotation as! StationPin
        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeWalking]
        location.mapItem().openInMaps(launchOptions: launchOptions)
    }
    
}



extension ViewController: MKMapViewDelegate {
    // 1
    /*
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 2
        guard let annotation = annotation as? StationPin else { return nil }
        // 3
        let identifier = "marker"
        var view: MKMarkerAnnotationView
        // 4
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            // 5
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        return view
    }
 */
}


