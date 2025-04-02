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
    
    var body: some Scene {
        WindowGroup {
            DualPaneFileView()
                .environmentObject(smbViewModel)
                .environmentObject(localViewModel)
        }
    }
}
