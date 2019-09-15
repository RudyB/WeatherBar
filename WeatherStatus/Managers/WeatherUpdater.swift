//
//  WeatherUpdater.swift
//  WeatherStatus
//
//  Created by Rudy Bermudez on 9/10/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Foundation
import Houston

enum WeatherUpdaterError: Int {
    case coordinatesNotAvailible = 10
}

/// The Weather Updater interfaces with the location manager and Forcecast API to retrieve the weather
/// conditions for the users location at a user definable interval
class WeatherUpdater
{
    enum State: CustomStringConvertible
    {
        case updatingLocation
        case updatingWeather
        case done(Location, CurrentWeather)
        
        var description: String {
            switch self {
            case .updatingLocation:
                return "Getting Your Current Location"
            case .updatingWeather:
                return "Getting The Latest Weather Report"
            case .done(let location, let weather):
                guard let city = location.city, let state = location.state else
                {
                    return "\(weather.apparentTemperatureString) \(weather.summary)"
                }
                return "\(weather.apparentTemperatureString) \(weather.summary) -- \(city), \(state)"
            }
        }
        
    }
    /// Location Manager is responsible for getting the user's current location
    private let locationManager: LocationManager
    
    /// Forcecast API Client is responsible for getting the weather report
    private let forcastClient: ForecastAPIClient
    
    /// Interval at which the forecast should be updated
    private var updateInterval: Double // Update Interval in Seconds
    
    /// Error Domain
    private let errorDomain = "io.rudybermudez.WeatherStatus.WeatherUpdater"
    
    /// Create a new Weather Updater
    ///
    /// - Parameter APIKey: API Key used for the forecast API
    init(APIKey: String) {
        forcastClient = ForecastAPIClient(APIKey: APIKey)
        updateInterval = 60 * 60 // 60 seconds * 60 minutes = 1 hour
        locationManager = LocationManager()
        locationManager.onLocationFix = onLocationDetermined(_:)
    }
    
    /// Closure called when the forecast is fethced
    public var onStateChange: ((APIResult<State>) -> Void)?
    
    /// Triggers a new
    public func refreshWeatherConditions()
    {
        if let onStateChange = onStateChange
        {
            onStateChange(.success(.updatingLocation))
        }
        locationManager.updateLocation()
    }
    
    public func setUpdateInterval(seconds: Double)
    {
        updateInterval = seconds
    }
    
    // MARK:- Closure Functions
    
    private func onLocationDetermined(_ result: APIResult<Location> )
    {
        guard let onStateChange = onStateChange else
        {
            Logger.error("Error - Closure not defined")
            return
        }
        
        switch result {
        case .failure(let error):
            onStateChange(.failure(error))
        case .success(let location):
            guard let coordinates = location.coordinates else
            {
                let error = createError(domain: errorDomain, code: WeatherUpdaterError.coordinatesNotAvailible.rawValue, message: "Location retrieved but no coordinates were returned")
                onStateChange(.failure(error))
                return
            }
            onStateChange(.success(.updatingWeather))
            forcastClient.fetchCurrentWeather(coordinates) { (result) in
                switch result
                {
                case .failure(let error):
                    onStateChange(.failure(error))
                case .success(let weather):
                    onStateChange(.success(.done(location, weather)))
                }
                
            }
        }
    }

    
    
    
    
    
}
