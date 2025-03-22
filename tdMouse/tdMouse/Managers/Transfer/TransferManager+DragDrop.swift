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
                                
                                let transferInProgress = await MainActor.run {
                                    self.isFolderTransferInProgress || self.activeTransfer != nil
                                }
                                
                                if transferInProgress {
                                    print("Transfer already in progress, ignoring drop")
                                    await MainActor.run {
                                        self.errorMessage = TransferError.transferInProgress.localizedDescription
                                    }
                                    return
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
                                    await MainActor.run {
                                        self.errorMessage = "File not found: \(fileName)"
                                    }
                                }
                            } else {
                                print("Invalid JSON format or not an SMB file")
                                await MainActor.run {
                                    self.errorMessage = "Invalid file format"
                                }
                            }
                        } else if let file = smbViewModel.getFileByName(jsonString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                            let fileName = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
                            // Fallback for simple string drop
                            let transferInProgress = await MainActor.run {
                                self.isFolderTransferInProgress || self.activeTransfer != nil
                            }
                            
                            if transferInProgress {
                                print("Transfer already in progress, ignoring drop")
                                await MainActor.run {
                                    self.errorMessage = TransferError.transferInProgress.localizedDescription
                                }
                                return
                            }
                            
                            // Create destination path
                            let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(fileName)
                            
                            // Start file download
                            print("Starting file download for: \(fileName) (simple string format)")
                            self.startSingleFileDownload(
                                file: file,
                                destination: localURL,
                                smbViewModel: smbViewModel
                            ) {
                                localViewModel.refreshFiles()
                            }
                        } else {
                            print("Could not parse drop data: \(jsonString)")
                            await MainActor.run {
                                self.errorMessage = "Invalid drop data"
                            }
                        }
                    } catch {
                        print("Error processing dropped file: \(error)")
                        await MainActor.run {
                            self.errorMessage = "Error processing drop: \(error.localizedDescription)"
                        }
                    }
                } else {
                    print("No valid string data in drop")
                    await MainActor.run {
                        self.errorMessage = "No valid data in drop"
                    }
                }
            }
        }
    }
    
    func handleLocalFileDroppedToSMB(provider: NSItemProvider, smbViewModel: FileTransferViewModel) {
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
                    print("Received local file drop: \(jsonString)")
                    
                    do {
                        // Try to decode as JSON
                        if let jsonData = jsonString.data(using: .utf8),
                           let fileInfo = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String],
                           let path = fileInfo["path"],
                           let isDirectoryStr = fileInfo["isDirectory"],
                           let type = fileInfo["type"], type == "localFile" {
                            
                            // We got a valid local file drop
                            let url = URL(fileURLWithPath: path)
                            let isDirectory = isDirectoryStr == "true"
                            
                            let transferInProgress = await MainActor.run {
                                self.isFolderTransferInProgress || self.activeTransfer != nil
                            }
                            
                            if transferInProgress {
                                print("Transfer already in progress, ignoring drop")
                                await MainActor.run {
                                    self.errorMessage = TransferError.transferInProgress.localizedDescription
                                }
                                return
                            }
                            
                            if isDirectory {
                                // Create a LocalFile struct for the folder
                                let folderFile = LocalFile(
                                    name: url.lastPathComponent,
                                    url: url,
                                    isDirectory: true,
                                    size: 0,
                                    modificationDate: nil
                                )
                                
                                // Start folder upload
                                self.startFolderUpload(
                                    folder: folderFile,
                                    smbViewModel: smbViewModel
                                ) {
                                    // Refresh SMB view on completion
                                    Task {
                                        try? await smbViewModel.listFiles(smbViewModel.currentDirectory)
                                    }
                                }
                            } else {
                                // Create a LocalFile struct for the file
                                let localFile = LocalFile(
                                    name: url.lastPathComponent,
                                    url: url,
                                    isDirectory: false,
                                    size: 0,
                                    modificationDate: nil
                                )
                                
                                // Start file upload
                                self.startSingleFileUpload(
                                    file: localFile,
                                    smbViewModel: smbViewModel
                                ) {
                                    // Refresh SMB view on completion
                                    Task {
                                        try? await smbViewModel.listFiles(smbViewModel.currentDirectory)
                                    }
                                }
                            }
                        } else {
                            print("Invalid drag data format")
                            await MainActor.run {
                                self.errorMessage = "Invalid drag data format"
                            }
                        }
                    } catch {
                        print("Error processing local file drop: \(error)")
                        await MainActor.run {
                            self.errorMessage = "Error processing drop: \(error.localizedDescription)"
                        }
                    }
                } else {
                    print("No valid string data in drop")
                    await MainActor.run {
                        self.errorMessage = "No valid data in drop"
                    }
                }
            }
        }
    }
}
