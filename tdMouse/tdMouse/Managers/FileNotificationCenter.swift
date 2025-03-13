//
//  FileNotificationCenter.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import Foundation
import SwiftUI
import Combine
import SMBClient

class FileNotificationCenter {
    static let shared = FileNotificationCenter()
    
    // Notification names
    static let fileSelectedNotification = NSNotification.Name("FileSelected")
    static let openConnectDialogNotification = NSNotification.Name("OpenConnectDialog")
    static let openUploadDialogNotification = NSNotification.Name("OpenUploadDialog")
    static let openNewFolderDialogNotification = NSNotification.Name("OpenNewFolderDialog")
    static let refreshFileListNotification = NSNotification.Name("RefreshFileList")
    
    // Post a notification to select a file
    func postFileSelected(_ file: File) {
        NotificationCenter.default.post(
            name: Self.fileSelectedNotification,
            object: file
        )
    }
    
    // Post a notification to open the connect dialog
    func postOpenConnectDialog() {
        NotificationCenter.default.post(
            name: Self.openConnectDialogNotification,
            object: nil
        )
    }
    
    // Post a notification to open the upload dialog
    func postOpenUploadDialog() {
        NotificationCenter.default.post(
            name: Self.openUploadDialogNotification,
            object: nil
        )
    }
    
    // Post a notification to open the new folder dialog
    func postOpenNewFolderDialog() {
        NotificationCenter.default.post(
            name: Self.openNewFolderDialogNotification,
            object: nil
        )
    }
    
    // Post a notification to refresh the file list
    func postRefreshFileList() {
        NotificationCenter.default.post(
            name: Self.refreshFileListNotification,
            object: nil
        )
    }
    
    // Get a publisher for file selected notifications
    func fileSelectedPublisher() -> NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: Self.fileSelectedNotification)
    }
    
    // Get a publisher for open connect dialog notifications
    func openConnectDialogPublisher() -> NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: Self.openConnectDialogNotification)
    }
    
    // Get a publisher for open upload dialog notifications
    func openUploadDialogPublisher() -> NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: Self.openUploadDialogNotification)
    }
    
    // Get a publisher for open new folder dialog notifications
    func openNewFolderDialogPublisher() -> NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: Self.openNewFolderDialogNotification)
    }
    
    // Get a publisher for refresh file list notifications
    func refreshFileListPublisher() -> NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: Self.refreshFileListNotification)
    }
}
