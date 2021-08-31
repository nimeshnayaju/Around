//
//  Around.swift
//  Around
//
//  Created by Nimesh Nayaju on 2021-08-17.
//

import Foundation
import CoreMotion
import CoreLocation
import UIKit
import os.log

class LookAround: ObservableObject {
    
//    private let activityManager = CMMotionActivityManager()
    private let activityManager = ActivityManager()
    @Published private (set) var isWalking2 = false {
        didSet {
            print(isWalking2)
        }
    }
    private let notificationManager = LocalNotificationManager()
    private var timer: Timer!
    private var elapsedTime:Int16 = 0
    
    @Published private (set) var isWalking = false {
        didSet {
            if shouldStartTimer(previousActivity: oldValue) {
                startTimer()
            } else if shouldInvalidateTimer(previousActivity: oldValue) {
                invalidateTimer()
            }
        }
    }
    
    @Published private var locationManager: LocationManager? {
        didSet {
            if (location != nil) {
                self.location = locationManager!.location
                print("here")
            }
        }
    }
    private var location: CLLocation?
    
    @Published private var lastLocation = LocationManager().location {
        didSet {
            print("lastLocation")
        }
    }
    
    init() {
//        self.startTracking()
        self.locationManager = LocationManager()
        self.isWalking2 = activityManager.isWalking
    }
    
    /*
     Starts tracking user motion activity
     */
    private func startTracking() {
        os_log("Tracking user motion activity", log: OSLog.around, type: .info)
        startTrackingActivityType()
    }
    
    /*
     Helper method to check if the timer should be started
     */
    private func shouldStartTimer(previousActivity:Bool) -> Bool {
        // only start timer if:
        // (1) the user is walking AND the screen is not locked AND a timer hasn't been set already
        // OR
        // (2) the user was previously stationary and has now been detected walking
        return (isWalking && !isScreenLocked() && elapsedTime == 0) || (isWalking && isWalking != previousActivity)
    }
    
    /*
     Helper method to check if the timer should be invalidated
     */
    private func shouldInvalidateTimer(previousActivity:Bool) -> Bool {
        // invalidate the timer if:
        // the user was previously walking and has now been detected not walking
        return (!isWalking && isWalking != previousActivity)
    }
    
    /*
     Starts a timer that calls checkIfScreenIsLocked() method in a second interval
     */
    private func startTimer() {
        os_log("Starting the tracking timer", log: OSLog.around, type: .debug)
        // query if the screen is locked every 1 second
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkIfScreenIsLocked), userInfo: nil, repeats: true)
    }
    
    /*
     Invalidates the timer and sets the elapsed time to 0
     */
    private func invalidateTimer() {
        if (self.timer != nil) {
            os_log("Invalidating the tracking timer", log: OSLog.around, type: .debug)
            self.timer.invalidate()
            self.elapsedTime = 0
        }
    }
    
    /*
     Invalidates the timer if the screen is locked; otherwise increases the elapsed time by 1.
     If the elapsed time reaches 5, sends a look around notification and then invalidates the timer
     */
    @objc private func checkIfScreenIsLocked() {
        // if the device is locked, invalidate the timer
        if (isScreenLocked()) {
            os_log("device is locked", log: OSLog.around, type: .debug)
            invalidateTimer()
        }
        // if the device is unlocked, increase the elapsed time by 1
        else {
            self.elapsedTime += 1
            os_log("Elapsed time: %d", log: OSLog.around, type: .debug, self.elapsedTime)
        }
        
        // notify the user to look around at the 5th iteration
        if (self.elapsedTime == 5) {
            os_log("Notifying the user to look around", log: OSLog.around, type: .debug)
            notificationManager.sendLookAroundNotification()
            invalidateTimer()
        }
    }
    
    /*
     Helper method to check if the screen is locked
     */
    private func isScreenLocked() -> Bool {
        return UIScreen.main.brightness == 0.0
    }
    
    private func startTrackingActivityType() {
//        if (CMMotionActivityManager.isActivityAvailable()) {
//            activityManager.startActivityUpdates(to: OperationQueue.main) { (data) in
//                DispatchQueue.main.async {
//                    if let activity = data {
//                        if activity.walking {
//                            self.isWalking = true
//                            os_log("Walking activity detected", log: OSLog.around, type: .debug)
//                        } else {
//                            self.isWalking = false
//                            os_log("Non-walking activity detected", log: OSLog.around, type: .debug)
//                        }
//                    }
//                }
//            }
//        } else {
//            os_log("Activity tracking not available", log: OSLog.around, type: .error)
//        }
    }
}
