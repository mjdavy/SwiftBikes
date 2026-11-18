//
//  MapViewController.swift
//  Swift Bikes
//
//  Created by Martin Davy on 7/10/18.
//  Copyright © 2018 Martin Davy. All rights reserved.
//

import MapKit
import UIKit
import os

/// The app's only screen. Once location access is granted it finds the bike-share network
/// nearest to the user, shows its stations on the map, refreshes their availability every
/// minute, and offers buttons to jump to the nearest station with a free bike or dock.
final class MapViewController: UIViewController {

    private static let refreshInterval: Duration = .seconds(60)
    private static let regionRadius: CLLocationDistance = 10_000
    private static let infoPageURL = URL(string: "https://citybik.es")!

    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var myLocationButton: UIButton!
    @IBOutlet private weak var nearestBikeButton: UIButton!
    @IBOutlet private weak var nearestDockButton: UIButton!

    private let client = CityBikesClient()
    private let locationManager = CLLocationManager()
    private let logger = Logger(subsystem: "org.ancientgeeks.bikes", category: "Map")

    private var currentLocation: CLLocation?
    /// API path of the network shown on the map, once it has been determined.
    private var networkHref: String?
    private var hasRequestedNetwork = false
    private var hasEnabledLocationFeatures = false
    private var refreshTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.register(StationPinView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        myLocationButton.accessibilityLabel = "Follow my location"
        nearestBikeButton.accessibilityLabel = "Nearest available bike"
        nearestDockButton.accessibilityLabel = "Nearest available dock"

        locationManager.delegate = self
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            enableLocationBasedFeatures()
        case .restricted, .denied:
            // The authorization callback asks the user to enable access in Settings.
            break
        @unknown default:
            break
        }
    }

    // MARK: - Location-based features

    private func enableLocationBasedFeatures() {
        startReceivingLocationChanges()

        guard !hasEnabledLocationFeatures else { return }
        hasEnabledLocationFeatures = true

        mapView.showsUserLocation = true
        myLocationButton.addAction(UIAction { [weak self] _ in
            self?.mapView.setUserTrackingMode(.follow, animated: true)
        }, for: .touchUpInside)
        nearestBikeButton.addAction(UIAction { [weak self] _ in
            self?.selectNearestStation { $0.freeBikes > 0 }
        }, for: .touchUpInside)
        nearestDockButton.addAction(UIAction { [weak self] _ in
            self?.selectNearestStation { $0.freeSlots > 0 }
        }, for: .touchUpInside)
        addInfoButton()
        startRefreshingStations()
    }

    private func startReceivingLocationChanges() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1.0  // metres
        locationManager.startUpdatingLocation()
    }

    private func addInfoButton() {
        let infoButton = UIButton(type: .infoLight, primaryAction: UIAction { _ in
            UIApplication.shared.open(Self.infoPageURL)
        })
        infoButton.accessibilityLabel = "About CityBikes"
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(infoButton)
        NSLayoutConstraint.activate([
            infoButton.bottomAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            infoButton.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -16),
        ])
    }

    private func promptToEnableLocationServices() {
        guard presentedViewController == nil else { return }

        let alert = UIAlertController(
            title: "Location Access Disabled",
            message: "This app requires location services to work. Please enable location services in Settings.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
    }

    // MARK: - Stations

    /// Finds the network nearest to `location` and shows its stations. Runs once per launch.
    private func loadNearestNetwork(near location: CLLocation) async {
        do {
            let networks = try await client.networks()
            guard let nearest = CityBikesClient.closestNetwork(to: location, in: networks) else { return }
            networkHref = nearest.href

            let network = try await client.network(href: nearest.href)
            guard let stations = network.stations else { return }
            mapView.addAnnotations(stations.map(StationPin.init))
            centerMap(on: network.clLocation)
        } catch {
            logger.error("Failed to load the nearest bike network: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func startRefreshingStations() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.refreshInterval)
                guard let self else { return }
                await self.refreshStations()
            }
        }
    }

    private func refreshStations() async {
        guard let networkHref else { return }
        do {
            let network = try await client.network(href: networkHref)
            let pins = mapView.annotations.compactMap { $0 as? StationPin }
            let changed = StationPin.applyUpdates(from: network.stations ?? [], to: pins)
            // Re-adding a pin is what makes MapKit pick up its new subtitle and marker colour.
            mapView.removeAnnotations(changed)
            mapView.addAnnotations(changed)
        } catch {
            logger.error("Failed to refresh stations: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func selectNearestStation(where isAvailable: (StationPin) -> Bool) {
        guard let currentLocation else { return }
        let nearest = mapView.annotations
            .compactMap { $0 as? StationPin }
            .filter(isAvailable)
            .min { currentLocation.distance(from: $0.location) < currentLocation.distance(from: $1.location) }
        guard let nearest else { return }

        mapView.deselectAnnotation(nearest, animated: false)
        mapView.selectAnnotation(nearest, animated: true)
    }

    private func centerMap(on location: CLLocation) {
        let region = MKCoordinateRegion(center: location.coordinate,
                                        latitudinalMeters: Self.regionRadius,
                                        longitudinalMeters: Self.regionRadius)
        mapView.setRegion(region, animated: true)
    }
}

// MARK: - CLLocationManagerDelegate

// The location manager is created on the main thread, so it calls its delegate there.
extension MapViewController: @preconcurrency CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            enableLocationBasedFeatures()
        case .restricted, .denied:
            promptToEnableLocationServices()
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location

        guard !hasRequestedNetwork else { return }
        hasRequestedNetwork = true
        Task { await loadNearestNetwork(near: location) }
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        guard let pin = view.annotation as? StationPin else { return }
        pin.mapItem().openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}
