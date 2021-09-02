//
//  Around.swift
//  Around
//
//  Created by Nimesh Nayaju on 2021-08-22.
//

import Foundation
import Combine
import CoreLocation
import CoreMotion
import UIKit
import os.log

class Around: ObservableObject {

    var subscribers = Set<AnyCancellable>()
    var locationSubsriber: AnyCancellable?

    @Published private var location: CLLocation?
    @Published private(set) var authorizationStatus = CLAuthorizationStatus.notDetermined {
        didSet {
            if authorizationStatus != .authorizedAlways {
                self.locationTracking = false
            }
        }
    }
    @Published private(set) var home: CLLocationCoordinate2D?
    @Published var locationTracking = false {
        didSet {
            UserDefaults.standard.set(self.locationTracking, forKey: Around.locationTrackingKey)
        }
    }
    
    private let activityManager = CMMotionActivityManager()
    private let notificationManager = LocalNotificationManager()
    private let locationManager = CLLocationManager()
    private let radius = 0.0002
    private var motionTrackingHasStarted = false
    private var screenStatusTrackingHasStarted = false
    private var screenTrackingTimer: Timer?
    private var elapsedTime:Int16 = 0
    private var isWalking = false
    
    private static var locationTrackingKey = "locationTracking"
    
    init() {
        self.authorizationStatus = locationManager.authorizationStatus
        self.locationTracking = UserDefaults.standard.bool(forKey: Around.locationTrackingKey)
        if self.authorizationStatus != .notDetermined {
            subscribeToAuthorizationUpdates()
        }
        if self.locationTracking {
            subscribeToLocationUpdates()
        }
    }
    
    /*
     Subscribes to AuthorizationPublisher and updates the value of  `authorizationStatus` to the current authorization status
     */
    private func subscribeToAuthorizationUpdates() {
        os_log("Subscribing to authorization updates", log: OSLog.around, type: .debug)
        CLLocationManager.publishAuthorizationStatus(locationManager: locationManager)
            .sink { status in
                // update the value of `authorizationStatus`
                self.authorizationStatus = status
                switch status {
                case .authorizedAlways:
                    os_log("Authorization to fetch background updates received", log: OSLog.around, type: .debug)
                case .authorizedWhenInUse, .denied, .restricted:
                    os_log("Not enough permission to fetch background location information", log: OSLog.location, type: .debug)
                    self.unsubscribeFromLocationUpdates()
                case .notDetermined:
                    self.location = nil
                    os_log("Location authorization not determined", log: OSLog.location, type: .debug)
                @unknown default:
                    self.location = nil
                }
            }
            .store(in: &subscribers)
    }
    
    /*
     Subscribes to LocationPublisher and updates the value of  `location` to the current user location
     */
    private func subscribeToLocationUpdates() {
        // if the app has received the correct authorization, start subscribing to location updates, else do nothing
        if self.isAuthorized() {
            os_log("Subscribing to location updates", log: OSLog.around, type: .debug)
            self.locationSubsriber = CLLocationManager.publishLocation()
                .sink(receiveCompletion: { error in
                    os_log("Error while fetching location", log: OSLog.location, type: .debug)
                }, receiveValue: { location in
                    os_log("Location: %@", log: OSLog.location, type: .debug, location.description)
                    self.location = location
                    // if home hasn't been set at all, no need to check if the user is inside their home building, otherwise
                    // only start tracking motion activities if the location is not within the circle representing the home building
                    if (self.home == nil || !self.isInsideCircle(location.coordinate)) {
                        // only start tracking motion activities if motion tracking hasn't been started already
                        if !self.motionTrackingHasStarted {
                            os_log("Starting motion tracking", log: OSLog.around, type: .debug)
                            self.startTrackingActivityType()
                        }
                    } else {
                        // stop tracking motion activities only if motion tracking has been started
                        if self.motionTrackingHasStarted {
                            os_log("User located inside their home building. Stopping motion updates", log: OSLog.around, type: .debug)
                            self.stopTrackingActivityType()
                        }
                    }
                })
        } else {
            os_log("Not authorized to receive background location updates", log: OSLog.around, type: .debug)
        }
    }
    
    private func unsubscribeFromLocationUpdates() {
        self.location = nil
        os_log("Unsubscribing from location updates", log: OSLog.around, type: .debug)
        self.locationSubsriber?.cancel()
        if self.motionTrackingHasStarted {
            self.stopTrackingActivityType()
        }
        if self.screenStatusTrackingHasStarted {
            self.stopTrackingScreenStatus()
        }
    }
    
    /*
     Helper method to check if the given coordinate is within the circle with center (self.home) and radius (self.radius)
     */
    private func isInsideCircle(_ coordinate: CLLocationCoordinate2D) -> Bool {
        if let center = self.home {
            let distance = (pow((coordinate.latitude - center.latitude), 2) + pow((coordinate.longitude - center.longitude), 2)).squareRoot()
            return distance <= radius
        }
        return true
    }
    
    private func startTrackingActivityType() {
        if (CMMotionActivityManager.isActivityAvailable()) {
            self.motionTrackingHasStarted = true
            self.activityManager.startActivityUpdates(to: OperationQueue.main) { (data) in
                DispatchQueue.main.async {
                    if let activity = data {
                        // if the user is detected walking
                        if activity.walking {
                            if !self.isWalking {
                                self.isWalking = true
                                os_log("Walking activity detected", log: OSLog.motion, type: .debug)
                                // start tracking screen status if screen tracking isn't start already
                                if !self.screenStatusTrackingHasStarted {
                                    os_log("Starting screen status tracking", log: OSLog.around, type: .debug)
                                    self.startTrackingScreenStatus()
                                }
                            }
                        } else {
                            if self.isWalking {
                                os_log("Non-walking activity detected", log: OSLog.motion, type: .debug)
                                self.isWalking = false
                                self.stopTrackingScreenStatus()
                            }
                        }
                    }
                }
            }
        } else {
            os_log("Activity tracking not available", log: OSLog.motion, type: .error)
        }
    }
    
    private func startTrackingScreenStatus() {
        self.screenStatusTrackingHasStarted = true
        self.screenTrackingTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(screenStatusTracker), userInfo: nil, repeats: true)
    }
    
    @objc private func screenStatusTracker() {
        // if the screen is locked, invalidate and restart the timer
        if isScreenLocked() {
            os_log("Resetting screen status tracker", log: OSLog.screen, type: .debug, self.elapsedTime)
            // invalidate the timer
            self.elapsedTime = 0
            self.screenTrackingTimer?.invalidate()
            // (re)start the timer
            startTrackingScreenStatus()
        } else {
            // Increase the elapsed time by 1
            self.elapsedTime += 1
            os_log("Elapsed time: %d", log: OSLog.screen, type: .debug, self.elapsedTime)
            // notify the user to look around at the 5th iteration
            if self.elapsedTime == 5 {
                os_log("Notifying the user to look around", log: OSLog.around, type: .debug)
                notificationManager.sendLookAroundNotification()
                stopTrackingScreenStatus()
            }
        }
    }
    
    /*
     Helper method to check if the screen is locked
     */
    private func isScreenLocked() -> Bool {
        return UIScreen.main.brightness == 0.0
    }
    
    private func stopTrackingScreenStatus() {
        if screenStatusTrackingHasStarted {
            os_log("Stopping screen status tracking", log: OSLog.around, type: .debug)
            self.elapsedTime = 0
            self.screenTrackingTimer?.invalidate()
            self.screenStatusTrackingHasStarted = false
        }
    }
    
    private func stopTrackingActivityType() {
        self.activityManager.stopActivityUpdates()
        self.motionTrackingHasStarted = false
    }
    
    // MARK: Intents
    func requestAlwaysAuthorization() {
        self.subscribeToAuthorizationUpdates()
    }
    
    func isAuthorized() -> Bool {
        return self.authorizationStatus == .authorizedAlways
    }
    
    func getCurrentCoordinates() -> CLLocationCoordinate2D {
        if let currentLocation = self.location {
            return currentLocation.coordinate
        } else {
           return CLLocationCoordinate2D()
        }
    }
    
    func setHomeCoordinates(coordinate: CLLocationCoordinate2D) {
        os_log("Home coordinates set to (%@, %@)", log: OSLog.around, type: .debug, coordinate.latitude.description, coordinate.longitude.description)
        self.home = coordinate
        saveHomeCordinate(coordinate)
    }
    
    func receiveLocationUpdates(_ value: Bool) {
        if value {
            self.subscribeToLocationUpdates()
        } else {
            self.unsubscribeFromLocationUpdates()
        }
    }
    
    private func saveHomeCordinate(_ coordinate: CLLocationCoordinate2D) {
        let homeLatitude = NSNumber(value: coordinate.latitude)
        let homeLongitude = NSNumber(value: coordinate.longitude)
        UserDefaults.standard.set(["latitude": homeLatitude, "longitude": homeLongitude], forKey: "homeCoordinate")
    }
    
    func getHomeCordinate() -> CLLocationCoordinate2D? {
        if let locationDictionary = UserDefaults.standard.object(forKey: "homeCoordinate") as? Dictionary<String,NSNumber> {
            let homeLatitude = locationDictionary["latitude"]!.doubleValue
            let homeLongitude = locationDictionary["longitude"]!.doubleValue
            return CLLocationCoordinate2D(latitude: homeLatitude, longitude: homeLongitude)
        }
        return nil
    }
}
