//
//  ActivityManager.swift
//  Around
//
//  Created by Nimesh Nayaju on 2021-08-21.
//

import Foundation
import CoreMotion
import os.log

class ActivityManager {
    private let activityManager = CMMotionActivityManager()
    private (set) var isWalking = false
    
    init() {
        if (CMMotionActivityManager.isActivityAvailable()) {
            activityManager.startActivityUpdates(to: OperationQueue.main) { (data) in
                DispatchQueue.main.async {
                    if let activity = data {
                        if activity.walking {
                            self.isWalking = true
                            os_log("Walking activity detected", log: OSLog.around, type: .debug)
                        } else {
                            self.isWalking = false
                            os_log("Non-walking activity detected", log: OSLog.around, type: .debug)
                        }
                    }
                }
            }
        } else {
            os_log("Activity tracking not available", log: OSLog.around, type: .error)
        }
    }
}
