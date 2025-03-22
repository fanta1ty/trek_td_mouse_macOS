//
//  TransferManager.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI
import Combine
import SMBClient
import UniformTypeIdentifiers

class TransferManager: ObservableObject {
    // Transfer status properties
    @Published var activeTransfer: TransferDirection?
    @Published var currentTransferItem = ""
    @Published var totalTransferItems = 0
    @Published var processedTransferItems = 0
    @Published var transferProgress: Double = 0.0
    @Published var isFolderTransferInProgress: Bool = false
    @Published var errorMessage = ""
    
    // Last saved checkpoint for resuming transfers
    var lastCheckpoint: TransferCheckpoint?
    
    // Tracking properties
    var completedFiles = [String]()
    
    // MARK: - Path Handling
    func resolvePath(
        base: String,
        component: String
    ) -> String {
        if base.isEmpty {
            return component
        } else {
            return "\(base)/\(component)"
        }
    }
    
    func createCheckpoint(
        remotePath: String,
        localPath: URL,
        completedItems: [String],
        totalItems: Int,
        bytesTransferred: UInt64
    ) {
        lastCheckpoint = TransferCheckpoint(
            remotePath: remotePath,
            localPath: localPath,
            completedItems: completedItems,
            totalItems: totalItems,
            bytesTransferred: bytesTransferred
        )
        
        saveCheckpoint()
    }
    
    func saveCheckpoint() {
        guard let checkPoint = lastCheckpoint else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(checkPoint)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("transfer_checkpoint.json")
            try data.write(to: url)
        } catch {
            print("Failed to save checkpoint: \(error)")
        }
    }
}

// MARK: - Drag and Drop Handlers
extension TransferManager {
    func handleSmbFileDroppedToLocal(
        provider: NSItemProvider,
        smbViewModel: FileTransferViewModel,
        localViewModel: LocalFileViewModel
    ) {
        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { secureData, error in
            guard error == nil else { return }
            
            Task {
                var jsonString: String? = nil
                
                if let string = secureData as? String {
                    jsonString = string
                } else if let nsString = secureData as? NSString {
                    jsonString = nsString as String
                } else if let data = secureData as? Data,
                          let decodedString = String(data: data, encoding: .utf8) {
                    jsonString = decodedString
                }
                
                // Check if this is a valid SMB file drop
                if let jsonString = jsonString {
                    print("Received drag data: \(jsonString)")
                    
                    do {
                        // Try JSON format first
                        if let jsonData = jsonString.data(using: .utf8),
                           let fileInfo = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String] {
                            
                            // Extract file info
                            let fileName = fileInfo["name"] ?? fileInfo["fileName"] ?? ""
                            let isDirectoryStr = fileInfo["isDirectory"] ?? "false"
                            let type = fileInfo["type"] ?? ""
                            
                            if !fileName.isEmpty && type == "smbFile" {
                                let isDirectory = isDirectoryStr == "true"
                                
                                await MainActor.run {
                                    // Check if a transfer is already in progress
                                    if self.isFolderTransferInProgress || self.activeTransfer != nil {
                                        print("Transfer already in progress, ignoring drop")
                                        return
                                    }
                                }
                                
                                // Find the file in the current directory
                                if let file = smbViewModel.getFileByName(fileName) {
                                    // Create destination path
                                    let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(fileName)
                                    
                                    if isDirectory {
                                        // Start folder download
                                        print("Starting folder download for: \(fileName) to \(localURL.path)")
                                        self.startFolderDownload(
                                            folder: file,
                                            destination: localURL,
                                            smbViewModel: smbViewModel
                                        ) {
                                            localViewModel.refreshFiles()
                                        }
                                    } else {
                                        // Start file download
                                        print("Starting file download for: \(fileName)")
                                        self.startSingleFileDownload(
                                            file: file,
                                            destination: localURL,
                                            smbViewModel: smbViewModel
                                        ) {
                                            localViewModel.refreshFiles()
                                        }
                                    }
                                } else {
                                    print("File not found in current directory: \(fileName)")
                                }
                            } else {
                                print("Invalid JSON format or not an SMB file")
                            }
                        } else if let file = smbViewModel.getFileByName(jsonString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                            // Fallback for simple string drop
                            
                            await MainActor.run {
                                // Check if a transfer is already in progress
                                if self.isFolderTransferInProgress || self.activeTransfer != nil {
                                    print("Transfer already in progress, ignoring drop")
                                    return
                                }
                            }
                            
                            // Create destination path
                            let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(jsonString.trimmingCharacters(in: .whitespacesAndNewlines))
                            
                            // Start file download
                            print("Starting file download for: \(jsonString.trimmingCharacters(in: .whitespacesAndNewlines)) (simple string format)")
                            self.startSingleFileDownload(
                                file: file,
                                destination: localURL,
                                smbViewModel: smbViewModel
                            ) {
                                localViewModel.refreshFiles()
                            }
                        } else {
                            print("Could not parse drop data: \(jsonString)")
                        }
                    } catch {
                        print("Error processing dropped file: \(error)")
                    }
                } else {
                    print("No valid string data in drop")
                }
            }
        }
    }
    
    func handleLocalFileDroppedToSMB(
        provider: NSItemProvider,
        smbViewModel: FileTransferViewModel
    ) {
        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { secureData, error in
            guard error == nil else { return }
            
            DispatchQueue.main.async {
                var jsonString: String? = nil
                
                if let string = secureData as? String {
                    jsonString = string
                } else if let nsString = secureData as? NSString {
                    jsonString = nsString as String
                } else if let data = secureData as? Data,
                          let decodedString = String(data: data, encoding: .utf8) {
                    jsonString = decodedString
                }
                
                // Process the JSON string if we got one
                
                if let jsonString = jsonString {
                    if let jsonData = jsonString.data(using: .utf8),
                       let fileInfo = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String],
                       let path = fileInfo["path"],
                       let isDirectoryStr = fileInfo["isDirectory"],
                       let type = fileInfo["type"], type == "localFile" {
                        
                        // We got a valid local file drop
                        let url = URL(fileURLWithPath: path)
                        let isDirectory = isDirectoryStr == "true"
                        
                        if isDirectory {
                            // Create a LocalFile struct with the folder information
                            let folderFile = LocalFile(
                                name: url.lastPathComponent,
                                url: url,
                                isDirectory: true,
                                size: 0,
                                modificationDate: nil
                            )
                            self.startFolderUpload(folder: folderFile, smbViewModel: smbViewModel, onComplete: {})
                        } else {
                            // Create a LocalFile struct with the file information
                            let localFile = LocalFile(
                                name: url.lastPathComponent,
                                url: url,
                                isDirectory: false,
                                size: 0,
                                modificationDate: nil
                            )
                            self.startSingleFileUpload(file: localFile, smbViewModel: smbViewModel, onComplete: {})
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Private Functions
extension TransferManager {
    func countFilesInFolder(url: URL) async -> Int {
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else {
            return 0
        }
        
        var count = 0
        
        for itemURL in contents {
            let isDir = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            
            if isDir {
                count += await countFilesInFolder(url: itemURL)
            } else {
                count += 1
            }
        }
        
        return count
    }
    
    // Count all files in a remote folder recursively
    func countRemoteFilesInFolder(
        folderName: String,
        parentPath: String = "",
        smbViewModel: FileTransferViewModel
    ) async -> Int {
        let originalDir = smbViewModel.currentDirectory
        var count = 0
        
        do {
            // Navigate to the folder
            let targetPath = originalDir.isEmpty ? folderName : "\(originalDir)/\(folderName)"
            try await smbViewModel.listFiles(targetPath)
            
            // Get all files excluding . and ..
            let files = smbViewModel.files.filter { $0.name != "." && $0.name != ".." }
            
            // Count files (non-directories)
            count += files.filter { !smbViewModel.isDirectory($0) }.count
            
            // Count files and recursive folders
            for file in files where smbViewModel.isDirectory(file) {
                count += await countRemoteFilesInFolder(
                    folderName: file.name,
                    smbViewModel: smbViewModel
                )
                
                // Navigate back to parent folder
                try await smbViewModel.listFiles(targetPath)
            }
            
            // Restore original directory
            try await smbViewModel.listFiles(originalDir)
        } catch {
            print("Error counting files in folder: \(error)")
            
            try? await smbViewModel.listFiles(originalDir)
        }
        
        return count
    }
}
