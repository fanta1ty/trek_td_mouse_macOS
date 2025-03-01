//
//  AppDelegate.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 28/2/25.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowControllers = [NSWindowController]()

    func applicationDidFinishLaunching(_ aNotification: Notification) {

    }

    func applicationWillTerminate(_ aNotification: Notification) {

    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

