//
//  SMBBrowserSection.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI
import UniformTypeIdentifiers

// Extension for SMBBrowserSection
extension SMBBrowserSection {
    // Add drop handling to SMB section
    var dropDelegate: some DropDelegate {
        SMBDropDelegate(smbViewModel: smbViewModel, transferManager: transferManager)
    }
}

// Drop delegate for SMB section
struct SMBDropDelegate: DropDelegate {
    @ObservedObject var smbViewModel: FileTransferViewModel
    @ObservedObject var transferManager: TransferManager
    
    func performDrop(info: DropInfo) -> Bool {
        guard smbViewModel.connectionState == .connected else { return false }
        
        // Extract local file information from drag items
        let providers = info.itemProviders(for: [UTType.plainText.identifier, UTType.fileURL.identifier])
        
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { (data, error) in
                guard error == nil else { return }
                
                var textData: String?
                
                if let data = data as? Data {
                    textData = String(data: data, encoding: .utf8)
                } else if let string = data as? String {
                    textData = string
                } else if let nsString = data as? NSString {
                    textData = nsString as String
                }
                
                if let text = textData {
                    processDroppedText(text)
                }
            }
            
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { (urlData, error) in
                guard error == nil else { return }
                
                if let url = urlData as? URL {
                    processDroppedURL(url)
                } else if let urlBookmarkData = urlData as? Data {
                    // For iOS, use simpler URL resolution but still need the isStale parameter
                    var isStale = false
                    if let url = try? URL(resolvingBookmarkData: urlBookmarkData,
                                          options: [],
                                          relativeTo: nil,
                                          bookmarkDataIsStale: &isStale) {
                        processDroppedURL(url)
                    }
                }
            }
        }
        
        return true
    }
    
    private func processDroppedText(_ text: String) {
        // Try to parse the JSON data
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
           let type = json["type"], type == "localFile",
           let path = json["path"],
           let isDirectoryStr = json["isDirectory"] {
            
            let url = URL(fileURLWithPath: path)
            let isDirectory = isDirectoryStr == "true"
            
            processDroppedURL(url, isDirectory: isDirectory)
        }
    }
    
    private func processDroppedURL(_ url: URL, isDirectory: Bool? = nil) {
        // Determine if this is a directory if not explicitly specified
        let isDir = isDirectory ?? (url.hasDirectoryPath || (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false)
        
        // Create a LocalFile object
        let localFile = LocalFile(
            name: url.lastPathComponent,
            url: url,
            isDirectory: isDir,
            size: 0,  // Size will be determined during transfer
            modificationDate: nil  // Date will be determined during transfer
        )
        
        Task {
            if isDir {
                // Upload folder
                await transferManager.startFolderUpload(
                    folder: localFile,
                    smbViewModel: smbViewModel
                ) {
                    // Refresh SMB directory after upload
                    Task {
                        try? await smbViewModel.refreshCurrentDirectory()
                    }
                }
            } else {
                // Upload file
                await transferManager.startSingleFileUpload(
                    file: localFile,
                    smbViewModel: smbViewModel
                ) {
                    // Refresh SMB directory after upload
                    Task {
                        try? await smbViewModel.refreshCurrentDirectory()
                    }
                }
            }
        }
    }
}

// Similar delegate for LocalFilesBrowserSection
extension LocalFilesBrowserSection {
    var dropDelegate: some DropDelegate {
        LocalDropDelegate(localViewModel: localViewModel, smbViewModel: smbViewModel, transferManager: transferManager)
    }
}

struct LocalDropDelegate: DropDelegate {
    @ObservedObject var localViewModel: LocalFileViewModel
    @ObservedObject var smbViewModel: FileTransferViewModel
    @ObservedObject var transferManager: TransferManager
    
    func performDrop(info: DropInfo) -> Bool {
        // Handle drops from SMB panel
        let providers = info.itemProviders(for: [UTType.plainText.identifier])
        
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { (data, error) in
                guard error == nil else { return }
                
                var textData: String?
                
                if let data = data as? Data {
                    textData = String(data: data, encoding: .utf8)
                } else if let string = data as? String {
                    textData = string
                } else if let nsString = data as? NSString {
                    textData = nsString as String
                }
                
                if let text = textData {
                    processDroppedText(text)
                }
            }
        }
        
        return true
    }
    
    private func processDroppedText(_ text: String) {
        // Try to parse the JSON data
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
           let type = json["type"], type == "smbFile",
           let fileName = json["name"],
           let isDirectoryStr = json["isDirectory"] {
            
            let isDirectory = isDirectoryStr == "true"
            
            // Process the drop based on the file type
            if let file = smbViewModel.getFileByName(fileName) {
                let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(fileName)
                
                Task {
                    if isDirectory {
                        // Download folder
                        await transferManager.startFolderDownload(
                            folder: file,
                            destination: localURL,
                            smbViewModel: smbViewModel
                        ) {
                            // Refresh local files when done
                            localViewModel.refreshFiles()
                        }
                    } else {
                        // Download file
                        await transferManager.startSingleFileDownload(
                            file: file,
                            destinationURL: localURL,
                            smbViewModel: smbViewModel
                        ) {
                            // Refresh local files when done
                            localViewModel.refreshFiles()
                        }
                    }
                }
            } else {
                // Handle simple file name without JSON
                if let file = smbViewModel.getFileByName(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(file.name)
                    
                    Task {
                        await transferManager.startSingleFileDownload(
                            file: file,
                            destinationURL: localURL,
                            smbViewModel: smbViewModel
                        ) {
                            localViewModel.refreshFiles()
                        }
                    }
                }
            }
        } else {
            // Try as simple file name if JSON parsing fails
            if let file = smbViewModel.getFileByName(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(file.name)
                
                Task {
                    await transferManager.startSingleFileDownload(
                        file: file,
                        destinationURL: localURL,
                        smbViewModel: smbViewModel
                    ) {
                        localViewModel.refreshFiles()
                    }
                }
            }
        }
    }
}
