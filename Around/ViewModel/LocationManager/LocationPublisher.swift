//
//  LocationPublisher.swift
//  Around
//
//  Created by Nimesh Nayaju on 2021-08-25.
//

import Foundation
import CoreLocation
import Combine

protocol LocationSubscriptionDelegate {
    func startLocationUpdate()
    func stopLocationUpdate()
}

protocol LocationSubscriptionProtocol {
    func sendLocation(location: CLLocation)
    func sendError(error: LocationPublisher.LocationError)
}

public final class LocationPublisher: NSObject, CLLocationManagerDelegate, LocationSubscriptionDelegate {
    private let locationManager: CLLocationManager
    private var locationSubscription: LocationSubscriptionProtocol?
    
    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            locationSubscription?.sendLocation(location: location)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let locationError: LocationError
        if let error = error as? CLError, error.code == .denied {
            locationError = LocationError.notAuthorized
        } else {
            locationError = LocationError.unknown
        }
        locationSubscription?.sendError(error: locationError)
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .denied:
            locationSubscription?.sendError(error: LocationError.notAuthorized)
        default:
            break
        }
    }
    
    func startLocationUpdate() {
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdate() {
        locationManager.stopUpdatingLocation()
    }
}

extension LocationPublisher: Publisher {
    // LocationPublisher emits CLLocation values
    public typealias Output = CLLocation
    // LocationPublisher emits LocationError during failure
    public typealias Failure = LocationError
    
    // This method is called whenever a new object subsribes to the publisher,
    // we create a new location subscription instance and attach it to the subscriber
    public func receive<S>(subscriber: S) where S : Subscriber, LocationPublisher.Failure == S.Failure, LocationPublisher.Output == S.Input {
        let subscription = LocationSubscription(subscriber: subscriber, delegate: self)
        // attach location subscription to the subscriber
        subscriber.receive(subscription: subscription)
        locationSubscription = subscription
    }
    
    public enum LocationError: Error {
        case unknown
        case notAuthorized
    }
    
    public final class LocationSubscription<S: Subscriber>: NSObject, CLLocationManagerDelegate, Subscription, LocationSubscriptionProtocol where S.Input == LocationPublisher.Output, S.Failure == LocationPublisher.Failure {
        private var delegate: LocationSubscriptionDelegate?
        private var subscriber: S?
        
        init(subscriber: S, delegate: LocationSubscriptionDelegate) {
            self.subscriber = subscriber
            self.delegate = delegate
        }
        
        public func request(_ demand: Subscribers.Demand) {
            delegate?.startLocationUpdate()
        }
        
        public func cancel() {
            delegate?.stopLocationUpdate()
        }
        
        public func sendLocation(location: CLLocation) {
            _ = subscriber?.receive(location)
        }
        
        public func sendError(error: LocationError) {
            _ = subscriber?.receive(completion: .failure(error))
        }
    }
}
