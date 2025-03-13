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
    var body: some Scene {
        WindowGroup {
            FileTransferView()
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    // Set window title on macOS
                    if let window = NSApplication.shared.windows.first {
                        window.title = "TD Mouse"
                        window.setFrameAutosaveName("SMBFileTransferWindow")
                    }
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
}
