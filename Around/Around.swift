//
//  Around.swift
//  Around
//
//  Created by Nimesh Nayaju on 2021-08-17.
//

import Foundation
import CoreMotion
import UIKit
import os.log

class Around: ObservableObject {
    
    private var activityManager = CMMotionActivityManager()
    private var timer: Timer!
    private var elapsedTime:Int16 = 0
    
    @Published var isWalking = false {
        didSet {
            if (isWalking != oldValue) {
                periodicallyCheckIfScreenIsLocked()
            }
        }
    }
    @Published var lookAround = false
    
    init() {
        self.startTracking()
    }
    
    private func startTracking() {
        os_log("Tracking user motion activity", log: OSLog.around, type: .info)
        startTrackingActivityType()
    }
    
    private func periodicallyCheckIfScreenIsLocked() {
        if isWalking {
            os_log("User has started walking", log: OSLog.around, type: .debug)
            // query if the screen is locked every 1 second if the person is walking
            startTimer()
        } else {
            os_log("User has stopped walking", log: OSLog.around, type: .debug)
            // if the person isn't walking, invalidate the timer
            invalidateTimer()
            self.lookAround = false
        }
    }
    
    private func startTimer() {
        if (elapsedTime == 0) {
            os_log("Starting the tracking timer", log: OSLog.around, type: .debug)
            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkIfScreenIsLocked), userInfo: nil, repeats: true)
        }
    }
    
    private func invalidateTimer() {
        if (self.timer != nil) {
            os_log("Invalidating the tracking timer", log: OSLog.around, type: .debug)
            self.timer.invalidate()
            self.elapsedTime = 0
        }
    }
    
    @objc private func checkIfScreenIsLocked() {
        // if the device is locked, reset the timer
        if (UIScreen.main.brightness == 0.0) {
            os_log("device is locked, so resetting the timer", log: OSLog.around, type: .debug)
            invalidateTimer()
            startTimer()
        }
        // if the device is unlocked, increase the elapsed time by 1
        else {
            self.elapsedTime += 1
            os_log("Elapsed time: %@", log: OSLog.around, type: .debug, elapsedTime)
        }
        
        // notify the user to look around at the 5th iteration
        if (self.elapsedTime == 5) {
            os_log("Notifying the user to look around", log: OSLog.around, type: .debug)
            self.lookAround = true
            invalidateTimer()
        }
    }
    
    private func startTrackingActivityType() {
        if (CMMotionActivityManager.isActivityAvailable()) {
            activityManager.startActivityUpdates(to: OperationQueue.main) { (data) in
                DispatchQueue.main.async {
                    if let activity = data {
                        if activity.walking {
                            self.isWalking = true
                        } else {
                            self.isWalking = false
                        }
                    }
                }
            }
        } else {
            os_log("Activity tracking not available", log: OSLog.around, type: .error)
        }
    }
}
