//
//  BikeNetworks.swift
//  Bikes
//
//  Created by Martin Davy on 7/12/18.
//  Copyright © 2018 Martin Davy. All rights reserved.
//

import Foundation
import MapKit


struct Network : Codable {
    let company : [String]
    let href : String
    let id: String
    let location : Location
    let name : String
}

struct Location : Codable {
    let city : String
    let country : String
    let latitude : Double
    let longitude : Double
}

struct Networks : Codable {
    let networks: [Network]
}



class BikeNetworks {

    func startLoad(url: URL, completionHandler: @escaping ([String:Network]?) -> Void) {
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            if let error = error {
                self.handleClientError(error: error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    self.handleServerError(response: response)
                    return
            }
            
            
            if let string = String(data: data!, encoding: .utf8)
            {
                print(string)
            }
            
            let deser = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
            print(deser!)
            
            
            let jsonDecoder = JSONDecoder()
            
            do {
                let result = try jsonDecoder.decode([String:Network].self, from: data!)
                completionHandler(result)
            }
            catch {
                print(error)
            }
            
        }
        
        task.resume()
    }
    
    func handleClientError(error value: Error) -> Void
    {
    }
    
    func handleServerError(response value: URLResponse?) -> Void
    {
    }
    
    
    
    
    func FindClosestBikeNetwork(networks: [String:Network]?, location: CLLocation) -> (String?) {
        
        var closestBikeNetwork : String?
        /*
        if let networkArray = networks["networks"]
        {
            if let forced = networkArray as! NSArray
            var closest = 1000000.0
            
        
            for network in networkArray as NSArray {
                let networkDictionary = network as! NSDictionary
                let locationDictionary = networkDictionary["location"]  as! NSDictionary
                let locLng = locationDictionary.value(forKey: "longitude") as! Double
                let locLat = locationDictionary.value(forKey: "latitude") as! Double
                let networkLocation = CLLocation(latitude: locLat, longitude: locLng)
                let distance = networkLocation.distance(from: location)
                
                if (distance < closest)
                {
                    closestBikeNetwork = networkDictionary["href"] as! String
                    closest = distance
                }
                
            }
        }
 */
        
        return closestBikeNetwork
    }
}
