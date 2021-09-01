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

    @Published private(set) var location: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus?
    @Published private (set) var home: CLLocationCoordinate2D?
    
    private let activityManager = CMMotionActivityManager()
    private let notificationManager = LocalNotificationManager()
    private let radius = 0.0002
    private var motionTracking = false
    private var screenStatusTracking = false
    private var locationTracking = false
    private var screenTrackingTimer: Timer?
    private var elapsedTime:Int16 = 0
    private var isWalking = false
    private(set) var isAuthorized = false
    
    private func startFetchingLocationData() {
        CLLocationManager.publishAuthorizationStatus()
            .sink { status in
                self.authorizationStatus = status
                switch status {
                case .authorizedAlways:
                    os_log("Authorization to fetch background updates received", log: OSLog.around, type: .debug)
                    self.isAuthorized = true
                case .authorizedWhenInUse, .denied, .restricted:
                    os_log("Not enough permission to fetch background location information", log: OSLog.location, type: .debug)
                    self.isAuthorized = false
                    self.unsubscribeFromLocationUpdates()
                case .notDetermined:
                    self.isAuthorized = false
                    self.location = nil
                    os_log("Location authorization not determined", log: OSLog.location, type: .debug)
                @unknown default:
                    self.isAuthorized = false
                    self.location = nil
                }
            }
            .store(in: &subscribers)
    }
    
    private func subscribeToLocationUpdates() {
        // if location tracking hasn't started yet and if the app has received the correct authorization, start subscribing to location updates, else do nothing
        if !self.locationTracking && isAuthorized {
            os_log("Subscribing to location updates", log: OSLog.around, type: .debug)
            self.locationSubsriber = CLLocationManager.publishLocation()
                .sink(receiveCompletion: { error in
                    os_log("Error while fetching location", log: OSLog.location, type: .debug)
                }, receiveValue: { location in
                    os_log("Location: %@", log: OSLog.location, type: .debug, location.description)
                    self.location = location
                    self.locationTracking = true
        
                    // if home hasn't been set at all, no need to check if the user is inside their home building, otherwise
                    // only start tracking motion activities if the location is not within the circle representing the home building
                    if (self.home == nil || !self.isInsideCircle(location.coordinate)) {
                        // only start tracking motion activities if motion tracking isn't started already
                        if !self.motionTracking {
                            os_log("Starting motion tracking", log: OSLog.around, type: .debug)
                            self.startTrackingActivityType()
                        }
                    } else {
                        // stop tracking motion activities if motion tracking has been started
                        if self.motionTracking {
                            os_log("User located inside their home building. Stopping motion updates", log: OSLog.around, type: .debug)
                            self.stopTrackingActivityType()
                        }
                    }
                })
        } else {
            os_log("Not enough permission to fetch background location updates", log: OSLog.around, type: .debug)
        }
    }
    
    private func unsubscribeFromLocationUpdates() {
        os_log("Unsubscribing from location updates", log: OSLog.around, type: .debug)
        self.location = nil
        if locationTracking {
            self.locationSubsriber?.cancel()
            self.locationTracking = false
        }
        if self.motionTracking {
            self.stopTrackingActivityType()
        }
        if self.screenStatusTracking {
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
            self.motionTracking = true
            self.activityManager.startActivityUpdates(to: OperationQueue.main) { (data) in
                DispatchQueue.main.async {
                    if let activity = data {
                        // if the user is detected walking
                        if activity.walking {
                            if !self.isWalking {
                                self.isWalking = true
                                os_log("Walking activity detected", log: OSLog.motion, type: .debug)
                                // start tracking screen status if screen tracking isn't start already
                                if !self.screenStatusTracking {
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
        self.screenStatusTracking = true
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
        if screenStatusTracking {
            os_log("Stopping screen status tracking", log: OSLog.around, type: .debug)
            self.elapsedTime = 0
            self.screenTrackingTimer?.invalidate()
            self.screenStatusTracking = false
        }
    }
    
    private func stopTrackingActivityType() {
        self.activityManager.stopActivityUpdates()
        self.motionTracking = false
    }
    
    // MARK: Intents
    func requestAlwaysAuthorization() {
        self.startFetchingLocationData()
    }
    
    func setHomeCoordinates(coordinate: CLLocationCoordinate2D) {
        os_log("Home coordinates set to (%@, %@)", log: OSLog.around, type: .debug, coordinate.latitude.description, coordinate.longitude.description)
        self.home = coordinate
    }
    
    func receiveLocationUpdates(_ value: Bool) {
        if value {
            self.subscribeToLocationUpdates()
        } else {
            self.unsubscribeFromLocationUpdates()
        }
    }
}
