//
//  FileTransferViewModel+Ext.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SMBClient
import SwiftUI

// Extension for FileTransferViewModel to add iOS-specific functionality
extension FileTransferViewModel {
    /// Refreshes the current directory listing without changing the path
    func refreshCurrentDirectory() async throws {
        // Simply call listFiles with the current directory path
        try await listFiles(currentDirectory)
    }
    
    /// Convenience method for iOS to check if file preview is supported
    func isPreviewSupported(_ file: File) -> Bool {
        if isDirectory(file) {
            return false
        }
        return Helpers.isPreviewableFileType(file.name)
    }
    
    /// Performs file selection action appropriate for iOS
    func handleFileSelection(_ file: File) async {
        if isDirectory(file) {
            try? await navigateToDirectory(file.name)
        } else if isPreviewSupported(file) {
            // Handle file preview
            do {
                let data = try await downloadFile(fileName: file.name, trackTransfer: false)
                let fileExt = file.name.components(separatedBy: ".").last ?? ""
                
                DispatchQueue.main.async {
                    FilePreviewManager.shared.showPreview(
                        title: "Preview",
                        data: data,
                        fileExtension: fileExt,
                        originalFileName: file.name
                    )
                }
            } catch {
                // Handle preview error
                print("Preview error: \(error)")
            }
        } else {
            // Offer to download the file
            // This would typically show an action sheet on iOS
        }
    }
}
