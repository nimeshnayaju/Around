//
//  Around.swift
//  Around
//
//  Created by Nimesh Nayaju on 2021-08-17.
//

import Foundation
import CoreMotion
import UIKit

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
    
    private func periodicallyCheckIfScreenIsLocked() {
        if isWalking {
            print("user is walking")
            // query if the screen is locked every 1 second if the person is walking
            startTimer()
        } else {
            print("user is stationary")
            // if the person isn't walking, invalidate the timer
            invalidateTimer()
            self.lookAround = false
        }
    }
    
    private func startTimer() {
        if (elapsedTime == 0) {
            print("starting the timer")
            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkIfScreenIsLocked), userInfo: nil, repeats: true)
        }
    }
    
    private func invalidateTimer() {
        if (self.timer != nil) {
            print("invalidating the timer")
            self.timer.invalidate()
            self.elapsedTime = 0
        }
    }
    
    @objc private func checkIfScreenIsLocked() {
        // if the device is locked, reset the timer
        if (UIScreen.main.brightness == 0.0) {
            print("device is locked, so resetting the timer")
            invalidateTimer()
            startTimer()
        }
        // if the device is unlocked, increase the elapsed time by 1
        else {
            self.elapsedTime += 1
            print("elapsed time: \(self.elapsedTime)")
        }
        
        // notify the user to look around at the 5th iteration
        if (self.elapsedTime == 5) {
            print("notifying the user to look around")
            self.lookAround = true
            invalidateTimer()
        }
    }
    
    private func startTracking() {
        print("Starting tracking")
        startTrackingActivityType()
    }
    
    func startTrackingActivityType() {
        if (CMMotionActivityManager.isActivityAvailable()) {
            activityManager.startActivityUpdates(to: OperationQueue.main) { (data) in
                DispatchQueue.main.async {
                    if let activity = data {
                        if activity.walking {
                            self.isWalking = true
                        } else {
                            self.isWalking = false
                        }
//                        } else if activity.stationary {
//                            print("user is stationary")
//                            self.isWalking = false
//                        } else if activity.automotive {
//                            print("user is driving")
//                            self.isWalking = false
//                        } else if activity.unknown {
//                            print("user is doing something unknown to us")
//                            self.isWalking = false
//                        } else if activity.running {
//                            print("user is running")
//                            self.isWalking = false
//                        }
                    }
                }
            }
        } else {
            print("Activity tracking not available")
        }
    }
}
