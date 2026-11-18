//
//  StationPinView.swift
//  Swift Bikes
//
//  Created by Martin Davy on 7/26/18.
//  Copyright © 2018 Martin Davy. All rights reserved.
//

import MapKit

/// Bike-glyph marker whose colour reflects availability. Its callout shows the
/// station name and counts, with a Maps button for walking directions.
final class StationPinView: MKMarkerAnnotationView {

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        markerTintColor = (annotation as? StationPin)?.markerTintColor
    }

    private func configure() {
        canShowCallout = true
        calloutOffset = CGPoint(x: -5, y: 5)
        glyphImage = UIImage(named: "Bike")

        let mapsButton = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 30, height: 30)))
        mapsButton.setBackgroundImage(UIImage(named: "Maps-icon"), for: .normal)
        mapsButton.accessibilityLabel = "Walking directions in Maps"
        rightCalloutAccessoryView = mapsButton
    }
}
