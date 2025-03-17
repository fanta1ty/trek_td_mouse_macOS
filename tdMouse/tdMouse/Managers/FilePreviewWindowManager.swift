//
//  FilePreviewWindowManager.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import SwiftUI
import AppKit
import Quartz

// Create a wrapper class to conform to QLPreviewItem
class FilePreviewItem: NSObject, QLPreviewItem {
    let url: URL
    let title: String
    
    init(url: URL, title: String) {
        self.url = url
        self.title = title
        super.init()
    }
    
    var previewItemURL: URL? {
        return url
    }
    
    var previewItemTitle: String? {
        return title
    }
}

class FilePreviewManager: NSObject {
    static let shared = FilePreviewManager()
    private var tempFiles = [URL]()
    
    // Use NSApplication's will terminate notification to clean up temp files
    override init() {
        super.init()
        
        // Register for application termination to clean up temp files
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }
    
    @objc func applicationWillTerminate() {
        cleanupTempFiles()
    }
    
    func showPreview(title: String, data: Data, fileExtension: String, originalFileName: String) {
        do {
            // Create a temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(fileExtension)
            
            // Write the data to the temporary file
            try data.write(to: tempURL)
            
            // Store temp file URL for cleanup
            tempFiles.append(tempURL)
            
            // Use NSWorkspace to open the file with the default app
            // This is safer than creating our own window
            NSWorkspace.shared.open(tempURL)
            
        } catch {
            print("Error creating preview: \(error)")
        }
    }
    
    // Method to clean up temp files
    func cleanupTempFiles() {
        for url in tempFiles {
            try? FileManager.default.removeItem(at: url)
        }
        tempFiles.removeAll()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cleanupTempFiles()
    }
}
