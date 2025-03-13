//
//  View+Ext.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import Foundation
import SMBClient
import SwiftUI

extension View {
    func onFileSelected(perform action: @escaping (File) -> Void) -> some View {
        onReceive(FileNotificationCenter.shared.fileSelectedPublisher()) { notification in
            if let file = notification.object as? File {
                action(file)
            }
        }
    }
    
    func onOpenConnectDialog(perform action: @escaping () -> Void) -> some View {
        onReceive(FileNotificationCenter.shared.openConnectDialogPublisher()) { _ in
            action()
        }
    }
    
    func onOpenUploadDialog(perform action: @escaping () -> Void) -> some View {
        onReceive(FileNotificationCenter.shared.openUploadDialogPublisher()) { _ in
            action()
        }
    }
    
    func onOpenNewFolderDialog(perform action: @escaping () -> Void) -> some View {
        onReceive(FileNotificationCenter.shared.openNewFolderDialogPublisher()) { _ in
            action()
        }
    }
    
    func onRefreshFileList(perform action: @escaping () -> Void) -> some View {
        onReceive(FileNotificationCenter.shared.refreshFileListPublisher()) { _ in
            action()
        }
    }
}
