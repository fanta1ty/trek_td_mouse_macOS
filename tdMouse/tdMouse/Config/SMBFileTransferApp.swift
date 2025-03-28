//
//  SMBFileTransferApp.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI
import Combine

@main
struct SMBFileTransferApp: App {
    @StateObject private var notificationCenter = FileNotificationCenter.shared
    @StateObject private var preferencesManager = PreferencesManager.shared
    
    var body: some Scene {
        WindowGroup {
            DualPaneFileTransferView()
                .frame(minWidth: 900, minHeight: 600)
                .environmentObject(notificationCenter)
                .environmentObject(preferencesManager)
                .onAppear {
                    configureMainWindow()
                }
        }
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
        .windowStyle(TitleBarWindowStyle())
        .commands {
            // Add standard macOS menu commands
            CommandGroup(replacing: .newItem) {
                Button("Connect to Server") {
                    FileNotificationCenter.shared.postOpenConnectDialog()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            // Add File menu commands
            CommandGroup(after: .newItem) {
                Divider()
                Button("Upload File") {
                    FileNotificationCenter.shared.postOpenUploadDialog()
                }
                .keyboardShortcut("u", modifiers: .command)
                
                Button("New Folder") {
                    FileNotificationCenter.shared.postOpenNewFolderDialog()
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            
            // Add refresh command
            CommandGroup(after: .toolbar) {
                Button("Refresh") {
                    FileNotificationCenter.shared.postRefreshFileList()
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
    
    private func configureMainWindow() {
        if let window = NSApplication.shared.windows.first {
            window.title = "TD Mouse"
            window.setFrameAutosaveName("SMBFileTransferWindow")
            window.setContentSize(NSSize(width: 900, height: 600))
            
            if preferencesManager.isFirstLaunch {
                window.center()
                preferencesManager.isFirstLaunch = false
            }
        }
    }
}
