//
//  BikeNetworks.swift
//  Bikes
//
//  Created by Martin Davy on 7/12/18.
//  Copyright © 2018 Martin Davy. All rights reserved.
//

import Foundation
import MapKit

class BikeNetworks {

    func startLoad(url: URL, completionHandler: @escaping (NSDictionary??) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            let result = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary
            completionHandler(result)
        }
        
        task.resume()
    }
    
    func FindClosestBikeNetwork(networks: NSDictionary, lat : Double, long: Double) -> (String?) {
        let networkArray = networks["networks"] as! NSArray
        let myLocation = CLLocation(latitude: lat, longitude: long)
        var closest = 1000000.0
        var closestBikeNetwork = String()
    
        for network in networkArray {
            let networkDictionary = network as! NSDictionary
            let locationDictionary = networkDictionary["location"]  as! NSDictionary
            let locLng = locationDictionary.value(forKey: "longitude") as! Double
            let locLat = locationDictionary.value(forKey: "latitude") as! Double
            let networkLocation = CLLocation(latitude: locLat, longitude: locLng)
            let distance = networkLocation.distance(from: myLocation)
            
            if (distance < closest)
            {
                closestBikeNetwork = networkDictionary["href"] as! String
                closest = distance
            }
            
        }
        
        return closestBikeNetwork
    }
}
