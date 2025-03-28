//
//  TransferManager+DragDrop.swift
//  tdMouse
//
//  Created by mobile on 22/3/25.
//

import SwiftUI
import SMBClient
import UniformTypeIdentifiers

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
                                    if self.isTransferInProgress {
                                        print("Transfer already in progress, ignoring drop")
                                        self.errorMessage = TransferError.transferInProgress.localizedDescription
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
                                        await self.startFolderDownload(
                                            folder: file,
                                            destination: localURL,
                                            smbViewModel: smbViewModel
                                        ) {
                                            localViewModel.refreshFiles()
                                        }
                                    } else {
                                        // Start file download
                                        print("Starting file download for: \(fileName)")
                                        await self.startSingleFileDownload(
                                            file: file,
                                            destinationURL: localURL,
                                            smbViewModel: smbViewModel
                                        ) {
                                            localViewModel.refreshFiles()
                                        }
                                    }
                                } else {
                                    print("File not found in current directory: \(fileName)")
                                    await MainActor.run {
                                        self.errorMessage = TransferError.fileNotFound(path: fileName).localizedDescription
                                    }
                                }
                            } else {
                                print("Invalid JSON format or not an SMB file")
                            }
                        } else if let file = smbViewModel.getFileByName(jsonString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                            let fileName = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
                            // Fallback for simple string drop
                            
                            await MainActor.run {
                                // Check if a transfer is already in progress
                                if self.isTransferInProgress {
                                    print("Transfer already in progress, ignoring drop")
                                    self.errorMessage = TransferError.transferInProgress.localizedDescription
                                    return
                                }
                            }
                            
                            // Create destination path
                            let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(fileName)
                            
                            // Start file download
                            print("Starting file download for: \(fileName) (simple string format)")
                            await self.startSingleFileDownload(
                                file: file,
                                destinationURL: localURL,
                                smbViewModel: smbViewModel
                            ) {
                                localViewModel.refreshFiles()
                            }
                        } else {
                            print("Could not parse drop data: \(jsonString)")
                            await MainActor.run {
                                self.errorMessage = "Invalid file data in drag operation"
                            }
                        }
                    } catch {
                        print("Error processing dropped file: \(error)")
                        await MainActor.run {
                            if let transferError = error as? TransferError {
                                self.errorMessage = transferError.localizedDescription
                            } else {
                                self.errorMessage = "Error processing drop: \(error.localizedDescription)"
                            }
                        }
                    }
                } else {
                    print("No valid string data in drop")
                    await MainActor.run {
                        self.errorMessage = "Invalid data in drag operation"
                    }
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
                
                if let jsonString = jsonString {
                    print("Received local file drag data: \(jsonString)")
                    
                    do {
                        // Try JSON format first
                        if let jsonData = jsonString.data(using: .utf8),
                           let fileInfo = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String],
                           let path = fileInfo["path"],
                           let isDirectoryStr = fileInfo["isDirectory"],
                           let type = fileInfo["type"], type == "localFile" {
                            
                            // We got a valid local file drop
                            let url = URL(fileURLWithPath: path)
                            let isDirectory = isDirectoryStr == "true"
                            
                            await MainActor.run {
                                // Check if a transfer is already in progress
                                if self.isTransferInProgress {
                                    print("Transfer already in progress, ignoring drop")
                                    self.errorMessage = TransferError.transferInProgress.localizedDescription
                                    return
                                }
                            }
                            
                            if isDirectory {
                                // Create a LocalFile struct with the folder information
                                if let folderFile = self.localFileFromURL(url) {
                                    await self.startFolderUpload(
                                        folder: folderFile,
                                        smbViewModel: smbViewModel
                                    ) {
                                        // File upload completed
                                    }
                                } else {
                                    print("Failed to create local file from URL: \(url)")
                                    await MainActor.run {
                                        self.errorMessage = "Failed to access local folder"
                                    }
                                }
                            } else {
                                // Create a LocalFile struct with the file information
                                if let localFile = self.localFileFromURL(url) {
                                    await self.startSingleFileUpload(
                                        file: localFile,
                                        smbViewModel: smbViewModel
                                    ) {
                                        // File upload completed
                                    }
                                } else {
                                    print("Failed to create local file from URL: \(url)")
                                    await MainActor.run {
                                        self.errorMessage = "Failed to access local file"
                                    }
                                }
                            }
                        } else {
                            print("Invalid local file drag data format")
                            await MainActor.run {
                                self.errorMessage = "Invalid file data in drag operation"
                            }
                        }
                    } catch {
                        print("Error processing dropped local file: \(error)")
                        await MainActor.run {
                            if let transferError = error as? TransferError {
                                self.errorMessage = transferError.localizedDescription
                            } else {
                                self.errorMessage = "Error processing drop: \(error.localizedDescription)"
                            }
                        }
                    }
                }
            }
        }
    }
}
