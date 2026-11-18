//
//  StationPin.swift
//  Swift Bikes
//
//  Created by Martin Davy on 7/22/18.
//  Copyright © 2018 Martin Davy. All rights reserved.
//

import Contacts
import MapKit
import UIKit

/// Map annotation for one bike station. Bike and dock counts change as the station data refreshes.
final class StationPin: NSObject, MKAnnotation {

    let id: String
    let title: String?
    let coordinate: CLLocationCoordinate2D
    private(set) var freeBikes: Int
    private(set) var freeSlots: Int

    init(station: Network.Station) {
        id = station.id
        title = station.name
        freeBikes = station.freeBikes
        freeSlots = station.emptySlots
        coordinate = CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)
        super.init()
    }

    var subtitle: String? {
        "Bikes: \(freeBikes) Docks: \(freeSlots)"
    }

    /// Gray when empty and full at once, red with no bikes, green with no docks, otherwise blue.
    var markerTintColor: UIColor {
        switch (freeBikes, freeSlots) {
        case (0, 0): .gray
        case (0, _): .red
        case (_, 0): .green
        default: .blue
        }
    }

    var location: CLLocation {
        CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    /// Copies the latest counts from `station`. Returns `true` if either count changed.
    @discardableResult
    func update(from station: Network.Station) -> Bool {
        guard freeBikes != station.freeBikes || freeSlots != station.emptySlots else {
            return false
        }
        freeBikes = station.freeBikes
        freeSlots = station.emptySlots
        return true
    }

    /// Updates each pin from the station with the same id and returns the pins whose counts changed.
    static func applyUpdates(from stations: [Network.Station], to pins: [StationPin]) -> [StationPin] {
        let stationsByID = Dictionary(stations.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        var changed: [StationPin] = []
        for pin in pins {
            if let station = stationsByID[pin.id], pin.update(from: station) {
                changed.append(pin)
            }
        }
        return changed
    }

    /// The item opened in Maps from the callout's accessory button. Maps shows the
    /// bike/dock counts where it would normally show the street address.
    func mapItem() -> MKMapItem {
        let addressDict = [CNPostalAddressStreetKey: subtitle ?? ""]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        return mapItem
    }
}
