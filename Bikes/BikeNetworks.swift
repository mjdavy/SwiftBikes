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
    let company : [String]?
    let href : String
    let id: String
    let name : String
    let gbfs_href : String?
    
    struct Location : Codable {
        let city : String
        let country : String
        let latitude : Double
        let longitude : Double
    }
    let location : Location
    
    struct Station : Codable {
        let empty_slots : Int
        
        struct Extra : Codable {
            let address: String
            let last_updated: Int
            let renting: Int
            let returning: Int
            let uid: String
        }
        let extra: Extra?
        let free_bikes: String
        let id: String
        let latitude: Double
        let longitude: Double
        let name: String
        let timestamp: String
    }
    let stations: [Station]?
}

struct Networks : Codable {
    let networks: [Network]
}

class BikeNetworks {

    func startLoad<T: Decodable>(url: URL, completionHandler: @escaping (T?) -> Void) {
        
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            
            if let error = error {
                self.handleClientError(error: error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    self.handleServerError(response: response)
                    return
            }
            
            let jsonDecoder = JSONDecoder()
            let result = try? jsonDecoder.decode(T.self, from: data!)
            print(result ?? "no bike data")
            completionHandler(result)
        }
        
        task.resume()
    }
    
    func getDataFromEndPoint(endPoint: URL)
    {
        
    }
    
    func handleClientError(error value: Error) -> Void
    {
    }
    
    func handleServerError(response value: URLResponse?) -> Void
    {
    }
    
    func FindClosestBikeNetwork(networks: Networks?, location: CLLocation) -> (String?) {
        
        var closestBikeNetwork : String?
        
        if let networkArray = networks?.networks
        {
            let initialValue = (100000000.0,href:String())
            let result = networkArray.reduce(initialValue, {(result, network) -> (Double,String) in
                let networkLocation = CLLocation(latitude: network.location.latitude, longitude: network.location.longitude)
                let distance = networkLocation.distance(from: location)
                return distance < result.0 ? (distance, network.href) : result
            })
            closestBikeNetwork = result.1
        }
        
        return closestBikeNetwork
    }
}
