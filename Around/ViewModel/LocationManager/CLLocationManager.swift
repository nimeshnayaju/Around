//
//  CLLocationManager.swift
//  Around
//
//  Created by Nimesh Nayaju on 2021-08-26.
//

import Foundation
import CoreLocation
import Combine

extension CLLocationManager {
    static func publishLocation() -> AnyPublisher<CLLocation, LocationPublisher.LocationError> {
        let publisher = LocationPublisher(locationManager: CLLocationManager())
        return publisher.eraseToAnyPublisher()
    }
    
    static func publishAuthorizationStatus() -> AnyPublisher<CLAuthorizationStatus, Never> {
        let publisher = AuthorizationPublisher(locationManager: CLLocationManager())
        return publisher.eraseToAnyPublisher()
    }
}
