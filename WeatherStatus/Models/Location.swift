//
//  LocationData.swift
//  Stratus
//
//  Created by Rudy Bermudez on 7/1/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Foundation
import CoreLocation


struct Location: Codable, CustomStringConvertible {
	let coordinates: Coordinate?
	var city: String?
	var state: String?
    
    var description: String {
        if let city = city, let state = state, let coordinates = coordinates {
            return "\(city), \(state) \(coordinates)"
        }
        return ""
    }
    
}

struct Coordinate: Codable, CustomStringConvertible {
    
	let latitude: Double
	let longitude: Double
    
    var description: String {
        return "(\(latitude),\(longitude))"
    }
	
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(_ coordinate: CLLocationCoordinate2D) {
		self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
	}
}
