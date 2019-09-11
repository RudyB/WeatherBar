//
//  LocationManager.swift
//  Stratus
//
//  Created by Rudy Bermudez on 3/19/17.
//  Copyright © 2017 Rudy Bermudez. All rights reserved.
//

import Foundation
import CoreLocation

enum LocationError: Int {
	case reverseGeocoderFailure = 10
}

final class LocationManager: NSObject, CLLocationManagerDelegate {
	private let manager = CLLocationManager()
	
	private let errorDomain = "io.rudybermudez.WeatherStatus.LocationManager"
    
    private let clGeocoder = CLGeocoder()
	
	var onLocationFix: ((APIResult<Location>) -> Void)?
	
	override init() {
		super.init()
		manager.delegate = self
		manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.requestLocation()
	}

	
	func updateLocation() {
		manager.requestLocation()
	}
	
	// MARK: CLLocationManagerDelegate
	
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            manager.requestLocation()
        default:
            print("User has not properly configured location permission")
        }
		
	}
	
	internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		if let onLocationFix = onLocationFix {
			onLocationFix(.failure(error))
		}
	}
	
	internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		
		guard let currLocation = locations.first else { return }
		
		if let onLocationFix = onLocationFix {
			clGeocoder.reverseGeocodeLocation(currLocation) { (placemarks, error) in
				
				
				if error != nil {
					onLocationFix(.failure(error!))
				} else {
					guard let placemark = placemarks?.first, let city = placemark.locality, let state = placemark.administrativeArea else {
						let error = createError(domain: self.errorDomain, code: LocationError.reverseGeocoderFailure.rawValue, message: "Failed to determine the name")
						onLocationFix(.failure(error))
						return
					}
					
					onLocationFix(.success(Location(coordinates: Coordinate(currLocation.coordinate), city: city, state: state)))
				}
			}
			
		}
	}
}
