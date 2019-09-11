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

class WeatherUpdater
{
    private let locationManager: LocationManager
    
    private let forcastClient: ForecastAPIClient
    
    private var updateInterval: Double // Update Interval in Seconds
    
    private let errorDomain = "io.rudybermudez.WeatherStatus.WeatherUpdater"
    
    init(APIKey: String) {
        forcastClient = ForecastAPIClient(APIKey: APIKey)
        updateInterval = 60 * 60 // 60 seconds * 60 minutes = 1 hour
        locationManager = LocationManager()
        locationManager.onLocationFix = onLocationDetermined(_:)
        
    }
    
    public var onCurrentForecastFetched: ((APIResult<CurrentWeather>) -> Void)?
    
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
