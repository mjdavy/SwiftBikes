//
//  StationPin.swift
//  Bikes
//
//  Created by Martin Davy on 7/22/18.
//  Copyright © 2018 Martin Davy. All rights reserved.
//

import Foundation
import MapKit
import Contacts

class StationPin: NSObject, MKAnnotation {
    
    let title: String?
    let coordinate: CLLocationCoordinate2D
    var freeBikes: Int
    var freeSlots: Int
    let id: String
    
    var markerTintColor: UIColor  {
        if freeBikes == 0 {
            return .red
        }
        
        else if freeSlots == 0 {
            return .green
        }
        
        else {
            return .blue
        }
    }
    
    init(station: Network.Station) {
        id = station.id
        title = station.name
        freeBikes = station.free_bikes
        freeSlots = station.empty_slots
        coordinate = CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)
        super.init()
    }
    
    var subtitle: String? {
        return "Bikes: \(self.freeBikes) Docks: \(self.freeSlots)"
    }
    
    func update(station: Network.Station) -> Void {
        self.freeBikes = station.free_bikes
        self.freeSlots = station.empty_slots
    }
    
    // Annotation right callout accessory opens this mapItem in Maps app
    func mapItem() -> MKMapItem {
        let addressDict = [CNPostalAddressStreetKey: subtitle!]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        return mapItem
    }
}
