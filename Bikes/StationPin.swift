//
//  StationPin.swift
//  Bikes
//
//  Created by Martin Davy on 7/22/18.
//  Copyright © 2018 Martin Davy. All rights reserved.
//

import Foundation
import MapKit

class StationPin: NSObject, MKAnnotation {
    
    let title: String?
    let coordinate: CLLocationCoordinate2D
    
    init(station: Network.Station) {
        title = station.name
        coordinate = CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)
        super.init()
    }
    
    var subtitle: String? {
        return nil
    }
}
