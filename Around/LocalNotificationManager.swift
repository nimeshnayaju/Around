//
//  LocalNotificationManager.swift
//  Around
//
//  Created by Nimesh Nayaju on 2021-08-19.
//

import UserNotifications
import os.log

class LocalNotificationManager {
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted == true && error == nil {
                os_log("Notifications permitted", log: OSLog.around, type: .debug)
            }
        }
    }
    
    func sendLookAroundNotification() {
        let content = UNMutableNotificationContent()

        content.title = "Look Around"
        content.body = "Reminder to look around"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
          if let error = error {
            os_log("%@", log: OSLog.around, type: .error, error.localizedDescription)
          }
        }
    }
}
