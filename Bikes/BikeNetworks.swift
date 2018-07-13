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

    func startLoad(completionHandler: @escaping (NSDictionary??) -> Void) {
        let url = URL(string: "https://api.citybik.es/v2/networks")!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            let networks = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary
            completionHandler(networks)
        }
        
        task.resume()
    }
    
    func FindClosestBikeNetwork(networks: NSDictionary, lat : Double, long: Double) -> (String, String) {
        let networkArray = networks["networks"] as! NSArray
        let myLocation = CLLocation(latitude: lat, longitude: long)
        var closest = 1000000.0
        for network in networkArray {
            let networkDictionary = network as! NSDictionary
            let locationDictionary = networkDictionary["location"]  as! NSDictionary
            let locLng = locationDictionary.value(forKey: "longitude") as! Double
            let locLat = locationDictionary.value(forKey: "latitude") as! Double
            print(locLat,locLng)
        }
        
        return ("foo", "bar")
    }
}
