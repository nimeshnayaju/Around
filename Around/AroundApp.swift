//
//  AroundApp.swift
//  Around
//
//  Created by Nimesh Nayaju on 2021-08-17.
//

import SwiftUI

@main
struct AroundApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let around = Around()
    var body: some Scene {
        WindowGroup {
            AroundMainView(around: around)
        }
    }
}
