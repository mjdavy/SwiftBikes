//
//  CityBikesClient.swift
//  Swift Bikes
//
//  Created by Martin Davy on 7/12/18.
//  Copyright © 2018 Martin Davy. All rights reserved.
//

import CoreLocation
import Foundation

/// Minimal async client for the CityBikes API.
struct CityBikesClient: Sendable {

    static let baseURL = "https://api.citybik.es"

    var session: URLSession = .shared

    /// All bike-share networks worldwide (without their stations).
    func networks() async throws -> [Network] {
        try await fetch(NetworkList.self, path: "/v2/networks").networks
    }

    /// A single network, including its stations and their current availability.
    /// - Parameter href: The network's `href`, e.g. `/v2/networks/citi-bike-nyc`.
    func network(href: String) async throws -> Network {
        try await fetch(NetworkDetail.self, path: href).network
    }

    /// The network whose advertised location is nearest to `location`, or `nil` if there are none.
    static func closestNetwork(to location: CLLocation, in networks: [Network]) -> Network? {
        networks.min { $0.clLocation.distance(from: location) < $1.clLocation.distance(from: location) }
    }

    @concurrent
    private func fetch<T: Decodable & Sendable>(_ type: T.Type, path: String) async throws -> T {
        guard let url = URL(string: Self.baseURL + path) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse, userInfo: [NSURLErrorFailingURLErrorKey: url])
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
