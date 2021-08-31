//
//  OsLog.swift
//  Around
//
//  Created by Nimesh Nayaju on 2021-08-18.
//

import os.log

extension OSLog {
    static let around = OSLog(subsystem: "com.aroundapp.around", category: "around")
    static let location = OSLog(subsystem: "com.aroundapp.location", category: "location")
    static let motion = OSLog(subsystem: "com.aroundapp.motion", category: "motion")
    static let screen = OSLog(subsystem: "com.aroundapp.screen", category: "screen")
}
