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
    var locationEstablished = false
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enableLocationServices()
        mapView.showsUserLocation = true
        startReceivingLocationChanges()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            //enableMyWhenInUseFeatures()
            break
            
        case .authorizedAlways:
            // Enable any of your app's location features
            //enableMyAlwaysFeatures()
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        switch status {
            case .restricted, .denied:
                // Disable your app's location features
                //disableMyLocationBasedFeatures()
                break
            
            case .authorizedWhenInUse:
                // Enable only your app's when-in-use features.
                //enableMyWhenInUseFeatures()
                break
            
            case .authorizedAlways:
                // Enable any of your app's location services.
                //enableMyAlwaysFeatures()
                break
            
            case .notDetermined:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if (!locationEstablished)
        {
            let currentLocation = locations.last!
            
            centerMapOnLocation(location: currentLocation)
            let url = URL(string:self.baseUrl + "/v2/networks")!
            
            bikeNetworks.startLoad(url: url, completionHandler: {(result : Networks?) in
                if let allNetworks = result,
                    let myNetwork = self.bikeNetworks.FindClosestBikeNetwork(networks: allNetworks, location: currentLocation)
                {
                    self.addBikeLocationsToMap(url: URL(string:self.baseUrl + myNetwork)!)
                }
            })
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
        // Do not start services that aren't available.
        if !CLLocationManager.locationServicesEnabled()
        {
            // Location services is not available.
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
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
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

}

