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
    let name: String?
    let coordinate: CLLocationCoordinate2D
    let freeBikes: Int
    let freeSlots: Int
    
    init(station: Network.Station) {
        title = "Bikes: \(station.free_bikes) Docks: \(station.empty_slots)"
        name = station.name
        freeBikes = station.free_bikes
        freeSlots = station.empty_slots
        coordinate = CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)
        super.init()
    }
    
    var subtitle: String? {
        return name
    }
    
    // Annotation right callout accessory opens this mapItem in Maps app
    func mapItem() -> MKMapItem {
        let addressDict = [CNPostalAddressStreetKey: subtitle!]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        return mapItem
    }
}
