//
//  BikeNetworks.swift
//  Bikes
//
//  Created by Martin Davy on 7/12/18.
//  Copyright © 2018 Martin Davy. All rights reserved.
//

import Foundation

class BikeNetworks {
    
    var networks: NSDictionary??
    
    func startLoad() {
        let url = URL(string: "https://api.citybik.es/v2/networks")!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            self.networks = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary
        }
        
        task.resume()
    }
}
