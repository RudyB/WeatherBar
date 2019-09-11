//
//  WeatherUpdater.swift
//  WeatherStatus
//
//  Created by Rudy Bermudez on 9/10/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Foundation


enum WeatherUpdaterError: Int {
    case coordinatesNotAvailible = 10
}

/// The Weather Updater interfaces with the location manager and Forcecast API to retrieve the weather
/// conditions for the users location at a user definable interval
class WeatherUpdater
{
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
    public var onCurrentForecastFetched: ((APIResult<CurrentWeather>) -> Void)?
    
    
    /// Triggers a new
    public func refreshWeatherConditions()
    {
        locationManager.updateLocation()
    }
    
    public func setUpdateInterval(seconds: Double)
    {
        updateInterval = seconds
    }
    
    private func onLocationDetermined(_ result: APIResult<Location> )
    {
        guard let onCurrentForecastFetched = onCurrentForecastFetched else
        {
            print("Error - Closure not defined")
            return
        }
        
        switch result {
        case .failure(let error):
            print(error)
            onCurrentForecastFetched(.failure(error))
        case .success(let location):
            guard let coordinates = location.coordinates else
            {
                let error = createError(domain: errorDomain, code: WeatherUpdaterError.coordinatesNotAvailible.rawValue, message: "Location retrieved but no coordinates were returned")
                print(error)
                onCurrentForecastFetched(.failure(error))
                return
            }
            
            forcastClient.fetchCurrentWeather(coordinates, completion: onCurrentForecastFetched)
        }
    }
    
    
    
    
    
}
