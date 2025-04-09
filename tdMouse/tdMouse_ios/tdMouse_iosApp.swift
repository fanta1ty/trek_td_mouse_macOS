//
//  tdMouse_iosApp.swift
//  tdMouse_ios
//
//  Created by mobile on 30/3/25.
//

import SwiftUI

@main
struct tdMouse_iosApp: App {
    @StateObject private var smbViewModel = FileTransferViewModel()
    @StateObject private var localViewModel = LocalViewModel()
    @StateObject private var transferManager = TransferManager()
    
    var body: some Scene {
        WindowGroup {
            WiFiConnectionView()
                .environmentObject(smbViewModel)
                .environmentObject(localViewModel)
                .environmentObject(transferManager)
        }
    }
}
