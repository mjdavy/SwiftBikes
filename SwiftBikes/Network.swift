//
//  Network.swift
//  Swift Bikes
//
//  Created by Martin Davy on 7/12/18.
//  Copyright © 2018 Martin Davy. All rights reserved.
//

import CoreLocation

/// A bike-share network as returned by the CityBikes API (https://api.citybik.es/v2).
///
/// Only the fields the app needs are decoded; the API sends many more, which are ignored.
struct Network: Decodable, Sendable {

    struct Location: Decodable, Sendable {
        let city: String
        let country: String
        let latitude: Double
        let longitude: Double
    }

    struct Station: Decodable, Sendable {
        let id: String
        let name: String
        let latitude: Double
        let longitude: Double
        let freeBikes: Int
        let emptySlots: Int
        let timestamp: String

        private enum CodingKeys: String, CodingKey {
            case id, name, latitude, longitude, timestamp
            case freeBikes = "free_bikes"
            case emptySlots = "empty_slots"
        }
    }

    let id: String
    let name: String
    /// API path of this network's detail resource, e.g. `/v2/networks/citi-bike-nyc`.
    let href: String
    let location: Location
    /// Only present when fetching a single network, not in the network list.
    let stations: [Station]?

    var clLocation: CLLocation {
        CLLocation(latitude: location.latitude, longitude: location.longitude)
    }
}

/// Response body of `GET /v2/networks`.
struct NetworkList: Decodable, Sendable {
    let networks: [Network]
}

/// Response body of `GET /v2/networks/{id}`.
struct NetworkDetail: Decodable, Sendable {
    let network: Network
}
