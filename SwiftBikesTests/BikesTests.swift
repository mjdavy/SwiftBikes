//
//  BikesTests.swift
//  SwiftBikesTests
//
//  Created by Martin Davy on 7/10/18.
//  Copyright © 2018 Martin Davy. All rights reserved.
//

import XCTest
import CoreLocation
import UIKit
@testable import Swift_Bikes

// Trimmed real responses from api.citybik.es, including fields the app ignores,
// so decoding stays tolerant of extra keys.
enum Fixtures {
    static let networksJSON = Data("""
    {"networks": [
      {"id": "abu-dhabi-careem-bike", "name": "Abu Dhabi Careem BIKE",
       "location": {"latitude": 24.4866, "longitude": 54.3728, "city": "Abu Dhabi", "country": "AE"},
       "href": "/v2/networks/abu-dhabi-careem-bike", "company": ["Careem"],
       "gbfs_href": "https://dubai.publicbikesystem.net/customer/gbfs/v2/en/gbfs.json"},
      {"id": "citi-bike-nyc", "name": "Citi Bike",
       "location": {"latitude": 40.7143528, "longitude": -74.00597309999999, "city": "New York, NY", "country": "US"},
       "href": "/v2/networks/citi-bike-nyc", "company": ["Lyft"]},
      {"id": "santander-cycles", "name": "Santander Cycles",
       "location": {"latitude": 51.5072, "longitude": -0.1276, "city": "London", "country": "GB"},
       "href": "/v2/networks/santander-cycles", "company": ["Serco"]}
    ]}
    """.utf8)

    static let networkJSON = Data("""
    {"network": {
      "id": "citi-bike-nyc", "name": "Citi Bike",
      "location": {"latitude": 40.7143528, "longitude": -74.00597309999999, "city": "New York, NY", "country": "US"},
      "href": "/v2/networks/citi-bike-nyc", "company": ["Lyft"], "ebikes": true,
      "stations": [
        {"id": "0007398f39bd26118c9fdfd5197ccada", "name": "Chester Ave & 12 Ave",
         "latitude": 40.644367, "longitude": -73.984276,
         "timestamp": "2026-11-18T19:29:26.181628+00:00Z", "free_bikes": 5, "empty_slots": 14,
         "extra": {"uid": "7aa86431", "renting": 1, "slots": 21, "has_ebikes": true}},
        {"id": "a1", "name": "W 52 St & 11 Ave",
         "latitude": 40.76727216, "longitude": -73.99392888,
         "timestamp": "2026-11-18T19:29:26.181628+00:00Z", "free_bikes": 0, "empty_slots": 30}
      ]
    }}
    """.utf8)
}

final class DecodingTests: XCTestCase {

    func testDecodesNetworkList() throws {
        let result = try JSONDecoder().decode(NetworkList.self, from: Fixtures.networksJSON)
        XCTAssertEqual(result.networks.count, 3)
        let nyc = result.networks[1]
        XCTAssertEqual(nyc.id, "citi-bike-nyc")
        XCTAssertEqual(nyc.name, "Citi Bike")
        XCTAssertEqual(nyc.href, "/v2/networks/citi-bike-nyc")
        XCTAssertEqual(nyc.location.city, "New York, NY")
        XCTAssertEqual(nyc.location.latitude, 40.7143528, accuracy: 1e-9)
        XCTAssertNil(nyc.stations, "The network list doesn't include stations")
    }

    func testDecodesNetworkWithStations() throws {
        let network = try JSONDecoder().decode(NetworkDetail.self, from: Fixtures.networkJSON).network
        let stations = try XCTUnwrap(network.stations)
        XCTAssertEqual(stations.count, 2)
        XCTAssertEqual(stations[0].id, "0007398f39bd26118c9fdfd5197ccada")
        XCTAssertEqual(stations[0].name, "Chester Ave & 12 Ave")
        XCTAssertEqual(stations[0].freeBikes, 5)
        XCTAssertEqual(stations[0].emptySlots, 14)
        XCTAssertEqual(stations[0].latitude, 40.644367, accuracy: 1e-9)
        XCTAssertEqual(stations[0].longitude, -73.984276, accuracy: 1e-9)
    }
}

final class ClosestNetworkTests: XCTestCase {

    private func networks() throws -> [Network] {
        try JSONDecoder().decode(NetworkList.self, from: Fixtures.networksJSON).networks
    }

    private func closestHref(to location: CLLocation) throws -> String? {
        CityBikesClient.closestNetwork(to: location, in: try networks())?.href
    }

    func testPicksNearestNetworkToUser() throws {
        let timesSquare = CLLocation(latitude: 40.7580, longitude: -73.9855)
        XCTAssertEqual(try closestHref(to: timesSquare), "/v2/networks/citi-bike-nyc")

        let paris = CLLocation(latitude: 48.8566, longitude: 2.3522)
        XCTAssertEqual(try closestHref(to: paris), "/v2/networks/santander-cycles")

        let dubai = CLLocation(latitude: 25.2048, longitude: 55.2708)
        XCTAssertEqual(try closestHref(to: dubai), "/v2/networks/abu-dhabi-careem-bike")
    }

    func testNoNetworksMeansNoClosestNetwork() {
        XCTAssertNil(CityBikesClient.closestNetwork(to: CLLocation(latitude: 0, longitude: 0), in: []))
    }
}

@MainActor
final class StationPinTests: XCTestCase {

    private func station(id: String = "s1", bikes: Int, slots: Int) throws -> Network.Station {
        let json = """
        {"id": "\(id)", "name": "Main St", "latitude": 40.1, "longitude": -73.2,
         "timestamp": "2026-11-18T19:29:26Z", "free_bikes": \(bikes), "empty_slots": \(slots)}
        """
        return try JSONDecoder().decode(Network.Station.self, from: Data(json.utf8))
    }

    func testPinCopiesStationFields() throws {
        let pin = StationPin(station: try station(bikes: 3, slots: 5))
        XCTAssertEqual(pin.id, "s1")
        XCTAssertEqual(pin.title, "Main St")
        XCTAssertEqual(pin.freeBikes, 3)
        XCTAssertEqual(pin.freeSlots, 5)
        XCTAssertEqual(pin.coordinate.latitude, 40.1, accuracy: 1e-9)
        XCTAssertEqual(pin.coordinate.longitude, -73.2, accuracy: 1e-9)
    }

    func testSubtitleShowsBikesAndDocks() throws {
        XCTAssertEqual(StationPin(station: try station(bikes: 3, slots: 5)).subtitle, "Bikes: 3 Docks: 5")
        XCTAssertEqual(StationPin(station: try station(bikes: 0, slots: 0)).subtitle, "Bikes: 0 Docks: 0")
    }

    func testMarkerColorReflectsAvailability() throws {
        XCTAssertEqual(StationPin(station: try station(bikes: 0, slots: 0)).markerTintColor, .gray)
        XCTAssertEqual(StationPin(station: try station(bikes: 0, slots: 4)).markerTintColor, .red)
        XCTAssertEqual(StationPin(station: try station(bikes: 4, slots: 0)).markerTintColor, .green)
        XCTAssertEqual(StationPin(station: try station(bikes: 4, slots: 4)).markerTintColor, .blue)
    }

    func testMapItemIsNamedAfterStation() throws {
        let pin = StationPin(station: try station(bikes: 3, slots: 5))
        let item = pin.mapItem()
        XCTAssertEqual(item.name, "Main St")
        XCTAssertEqual(item.placemark.coordinate.latitude, 40.1, accuracy: 1e-9)
        XCTAssertEqual(item.placemark.coordinate.longitude, -73.2, accuracy: 1e-9)
    }

    func testUpdateReportsWhetherCountsChanged() throws {
        let pin = StationPin(station: try station(bikes: 3, slots: 5))
        XCTAssertFalse(pin.update(from: try station(bikes: 3, slots: 5)))
        XCTAssertTrue(pin.update(from: try station(bikes: 2, slots: 6)))
        XCTAssertEqual(pin.freeBikes, 2)
        XCTAssertEqual(pin.freeSlots, 6)
        XCTAssertEqual(pin.subtitle, "Bikes: 2 Docks: 6")
        XCTAssertEqual(pin.markerTintColor, .blue)
        XCTAssertTrue(pin.update(from: try station(bikes: 0, slots: 8)))
        XCTAssertEqual(pin.markerTintColor, .red)
    }

    func testApplyUpdatesReturnsOnlyChangedPins() throws {
        let unchanged = StationPin(station: try station(id: "a", bikes: 1, slots: 1))
        let changed = StationPin(station: try station(id: "b", bikes: 1, slots: 1))
        let missing = StationPin(station: try station(id: "c", bikes: 1, slots: 1))
        let updates = [
            try station(id: "a", bikes: 1, slots: 1),
            try station(id: "b", bikes: 0, slots: 2),
            try station(id: "z", bikes: 9, slots: 9),
        ]

        let result = StationPin.applyUpdates(from: updates, to: [unchanged, changed, missing])

        XCTAssertEqual(result.map(\.id), ["b"])
        XCTAssertEqual(changed.freeBikes, 0)
        XCTAssertEqual(changed.freeSlots, 2)
        XCTAssertEqual(missing.freeBikes, 1, "Pins with no matching station are left alone")
    }

    func testApplyUpdatesUsesLastDuplicateStation() throws {
        let pin = StationPin(station: try station(id: "a", bikes: 1, slots: 1))
        let updates = [try station(id: "a", bikes: 5, slots: 5), try station(id: "a", bikes: 7, slots: 0)]

        _ = StationPin.applyUpdates(from: updates, to: [pin])

        XCTAssertEqual(pin.freeBikes, 7)
        XCTAssertEqual(pin.freeSlots, 0)
    }
}
