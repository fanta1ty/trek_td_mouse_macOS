//
//  LocalFileViewModel.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import UIKit
import SwiftUI

// Modifications to LocalFileViewModel for iOS
extension LocalFileViewModel {
    // iOS-specific directory selection
    func selectDirectory() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        documentPicker.delegate = DirectoryPickerDelegate.shared
        documentPicker.allowsMultipleSelection = false
        
        DirectoryPickerDelegate.shared.onPick = { [weak self] urls in
            guard let self = self, let url = urls.first else { return }
            self.navigateToURL(url)
        }
        
        // Present the picker
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(documentPicker, animated: true)
        }
    }
    
    // Replace the initialization point for iOS
    func initialize() {
        // Start at Documents directory for iOS
        currentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        refreshFiles()
    }
}

// Helper class for document picking
class DirectoryPickerDelegate: NSObject, UIDocumentPickerDelegate {
    static let shared = DirectoryPickerDelegate()
    var onPick: (([URL]) -> Void)?
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        onPick?(urls)
    }
}

// FilePreviewManager adjustments for iOS
class FilePreviewManager {
    static let shared = FilePreviewManager()
    private var tempFiles = [URL]()
    
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
            
            // Create a preview controller
            let fileType = Helpers.determineFileType(fileExtension: fileExtension.lowercased())
            
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = scene.windows.first,
                   let rootVC = window.rootViewController {
                    
                    let previewVC = UIHostingController(rootView: FilePreviewView(
                        url: tempURL,
                        title: originalFileName,
                        fileType: fileType
                    ))
                    
                    // Present the preview
                    if let presentedVC = rootVC.presentedViewController {
                        presentedVC.present(previewVC, animated: true)
                    } else {
                        rootVC.present(previewVC, animated: true)
                    }
                }
            }
        } catch {
            print("Error creating preview: \(error)")
        }
    }
    
    func cleanupTempFiles() {
        for url in tempFiles {
            try? FileManager.default.removeItem(at: url)
        }
        tempFiles.removeAll()
    }
}
