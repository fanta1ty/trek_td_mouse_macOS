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
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenConnectDialog"),
                        object: nil
                    )
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            // Add File menu commands
            CommandGroup(after: .newItem) {
                Divider()
                Button("Upload File") {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenUploadDialog"),
                        object: nil
                    )
                }
                .keyboardShortcut("u", modifiers: .command)
                
                Button("New Folder") {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenNewFolderDialog"),
                        object: nil
                    )
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            
            // Add refresh command
            CommandGroup(after: .toolbar) {
                Button("Refresh") {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("RefreshFileList"),
                        object: nil
                    )
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
