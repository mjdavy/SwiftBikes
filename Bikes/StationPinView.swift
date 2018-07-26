//
//  StationPinView.swift
//  Bikes
//
//  Created by Martin Davy on 7/26/18.
//  Copyright © 2018 Martin Davy. All rights reserved.
//

import Foundation
import MapKit

class StationPinView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            // 1
            guard let stationPin = newValue as? StationPin else { return }
            canShowCallout = true
            calloutOffset = CGPoint(x: -5, y: 5)
            let mapsButton = UIButton(frame: CGRect(origin: CGPoint.zero,
                                                    size: CGSize(width: 30, height: 30)))
            mapsButton.setBackgroundImage(UIImage(named: "Maps-icon"), for: UIControlState())
            rightCalloutAccessoryView = mapsButton
            markerTintColor = stationPin.markerTintColor
            glyphImage = UIImage(named: "Bike")
        }
    }
}
