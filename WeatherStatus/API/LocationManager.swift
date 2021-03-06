//
//  LocationManager.swift
//  Stratus
//
//  Created by Rudy Bermudez on 3/19/17.
//  Copyright © 2017 Rudy Bermudez. All rights reserved.
//

import Foundation
import CoreLocation
import Houston
import RateLimit

enum LocationError: Int {
    case reverseGeocoderFailure = 10
}

final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    private let errorDomain = "io.rudybermudez.WeatherStatus.LocationManager"
    
    private let geocoder = CLGeocoder()
    private let geocoderRateLimiter = CountedLimiter(limit: 1)
    
    var onLocationFix: ((APIResult<Location>) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }
    
    
    func updateLocation() {
        Logger.verbose("Request to Update Location")
        geocoderRateLimiter.reset() // Reset the timer on the geocoder rate limiter
        manager.requestLocation() // Request a new location
    }
    
    // MARK: CLLocationManagerDelegate
    
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorized:
            fallthrough
        case .authorizedAlways:
            Logger.debug("Use of Location Authorized")
            updateLocation()
        case .restricted, .denied:
            Logger.error("User has not properly configured location permission")
        case .notDetermined:
            Logger.debug("Application location permissions not determined")
        default:
            fatalError()
        }
        
    }
    
    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let onLocationFix = onLocationFix {
            onLocationFix(.failure(error))
        }
    }
    
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let currentlocation = locations.first
            else {
                Logger.error("No location returned")
                return
        }
        
        guard let onLocationFix = onLocationFix
            else {
                Logger.error("OnLocationFix closure not defined")
                return
        }
        
        Logger.debug("CLLocationManager updated location")
        
        // This delegate method is called multiple times after a single location is requested
        // For this reason the rate limiter will keep the reverseGeocodeLocation from being called too many times
        geocoderRateLimiter.execute {
            Logger.debug("Rate Limiting Allowing Reverse Geocode")
            reverseGeocodeLocation(location: currentlocation, onCompletion: onLocationFix)
        }
    }
    
    private func reverseGeocodeLocation(location: CLLocation, onCompletion: @escaping (APIResult<Location>) -> Void)
    {
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            guard
                let placemark = placemarks?.first,
                let city = placemark.locality,
                let state = placemark.administrativeArea
                else {
                    if error != nil {
                        onCompletion(.failure(error!))
                    } else {
                        let error = createError(domain: self.errorDomain, code: LocationError.reverseGeocoderFailure.rawValue, message: "Reverse Geocoder Failure")
                        onCompletion(.failure(error))
                    }
                    return
            }
            Logger.debug("Reverse Geocode Complete")
            onCompletion(.success(Location(coordinates: Coordinate(location.coordinate), city: city, state: state)))
        }
    }
}
