//
//  AuthorizationPublisher.swift
//  Around
//
//  Created by Nimesh Nayaju on 2021-08-27.
//

import Foundation
import CoreLocation
import Combine

protocol AuthorizationSubscriptionDelegate {
    func requestAlwaysAuthorization()
}

protocol AuthorizationSubscriptionProtocol {
    func sendStatus(status: CLAuthorizationStatus)
}

public final class AuthorizationPublisher: NSObject, CLLocationManagerDelegate, AuthorizationSubscriptionDelegate {
    private let locationManager: CLLocationManager
    private var authorizationSubscription: AuthorizationSubscriptionProtocol?
    
    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationSubscription?.sendStatus(status: manager.authorizationStatus)
    }
    
    func requestAlwaysAuthorization() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
}

extension AuthorizationPublisher: Publisher {
    // AuthorizationPublisher emits CLAuthorizationStatus values
    public typealias Output = CLAuthorizationStatus
    // AuthorizationPublisher doesn't fail
    public typealias Failure = Never
    
    public func receive<S>(subscriber: S) where S : Subscriber, AuthorizationPublisher.Failure == S.Failure, AuthorizationPublisher.Output == S.Input {
        let subscription = AuthorizationSubscription(subscriber: subscriber, delegate: self)
        subscriber.receive(subscription: subscription)
        authorizationSubscription = subscription
    }
    
    public final class AuthorizationSubscription<S: Subscriber>: NSObject, CLLocationManagerDelegate, Subscription, AuthorizationSubscriptionProtocol where S.Input == AuthorizationPublisher.Output, S.Failure == AuthorizationPublisher.Failure {
        private var delegate: AuthorizationSubscriptionDelegate?
        private var subscriber: S?
        
        init(subscriber: S, delegate: AuthorizationSubscriptionDelegate) {
            self.subscriber = subscriber
            self.delegate = delegate
        }
        
        public func request(_ demand: Subscribers.Demand) {
            delegate?.requestAlwaysAuthorization()
        }
        
        public func cancel() {}
        
        public func sendStatus(status: CLAuthorizationStatus) {
            _ = subscriber?.receive(status)
        }
    
    }
}

