//
//  AppDelegate.swift
//  WeatherStatus
//
//  Created by Rudy Bermudez on 9/10/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Cocoa
import Houston

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var manager:  StatusBarManager!
    let consoleLogger = ConsoleDestination()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        Logger.add(destination: consoleLogger)
        manager = StatusBarManager()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

