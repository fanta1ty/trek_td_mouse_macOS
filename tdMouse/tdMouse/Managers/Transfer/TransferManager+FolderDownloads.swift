//
//  TransferManager+FolderDownloads.swift
//  tdMouse
//
//  Created by mobile on 21/3/25.
//

import Foundation
import SMBClient

// MARK: - Folder Download Methods
extension TransferManager {
    func startFolderDownload(
        folder: File,
        destination: URL,
        smbViewModel: FileTransferViewModel,
        onComplete: @escaping () -> Void
    ) {
        Task {
            // Check if a folder transfer is already in progress
            let transferInProgress = await MainActor.run { self.isFolderTransferInProgress }
            if transferInProgress {
                print("Folder transfer already in progress, ignoring request")
                await MainActor.run {
                    self.errorMessage = TransferError.transferInProgress.localizedDescription
                }
                return
            }
            
            // Record start time for transfer stats
            let startTime = Date()
            var totalBytes: UInt64 = 0
            
            await MainActor.run {
                self.isFolderTransferInProgress = true
                self.activeTransfer = .toLocal
                self.totalTransferItems = 0
                self.processedTransferItems = 0
                self.currentTransferItem = folder.name
                self.errorMessage = ""
                self.completedFiles = []
            }
            
            do {
                // Ensure destination directory exists
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: destination.path) {
                    try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
                }
                
                // Save starting directory
                let originalDir = smbViewModel.currentDirectory
                
                // Try to calculate total files (but don't throw if it fails)
                do {
                    let fileCount = await countRemoteFilesInFolder(
                        folderName: folder.name,
                        smbViewModel: smbViewModel
                    )
                    
                    // Restore original directory
                    try await smbViewModel.listFiles(originalDir)
                    
                    await MainActor.run {
                        print("Found \(fileCount) files in folder \(folder.name)")
                        self.totalTransferItems = max(1, fileCount) // Ensure at least 1
                    }
                } catch {
                    print("Error counting files (continuing anyway): \(error)")
                    await MainActor.run {
                        // Set a nominal number if counting fails
                        self.totalTransferItems = 1
                    }
                    
                    // Make sure we're back in original directory
                    try? await smbViewModel.listFiles(originalDir)
                }
                
                // Now download the folder
                print("Starting folder download from \(smbViewModel.currentDirectory) for folder \(folder.name)")
                
                // Track file sizes as we go
                totalBytes = await try downloadFolderRecursivelyWithSizeTracking(
                    folderName: folder.name,
                    destURL: destination,
                    smbViewModel: smbViewModel
                )
                
                // Make sure we're back in original directory
                try await smbViewModel.listFiles(originalDir)
                
                // Create and display transfer summary
                let endTime = Date()
                
                // Generate transfer stats
                let stats = TransferStats(
                    fileSize: totalBytes,
                    fileName: "\(folder.name) (Folder)",
                    startTime: startTime,
                    endTime: endTime,
                    transferType: .download,
                    speedSamples: [] // We don't have detailed speed samples for folder transfers
                )
                
                await MainActor.run {
                    // Set transfer stats and show summary
                    smbViewModel.lastTransferStats = stats
                    
                    // Add a small delay to ensure UI updates properly
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                        smbViewModel.showTransferSummary = true
                    }
                }
                
                // Pause briefly to show completion
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                // Reset UI state
                await MainActor.run {
                    self.activeTransfer = nil
                    self.currentTransferItem = ""
                    self.totalTransferItems = 0
                    self.processedTransferItems = 0
                    self.isFolderTransferInProgress = false
                    onComplete()
                }
            } catch {
                print("Folder download error: \(error)")
                
                // Reset UI state even on error
                await MainActor.run {
                    self.activeTransfer = nil
                    self.currentTransferItem = ""
                    self.errorMessage = error is TransferError ? error.localizedDescription : "Download failed: \(error.localizedDescription)"
                    self.isFolderTransferInProgress = false
                }
            }
        }
    }
    
    func downloadFolderRecursivelyWithSizeTracking(
        folderName: String,
        destURL: URL,
        smbViewModel: FileTransferViewModel
    ) async throws -> UInt64 {
        // Get the starting state
        let startingDir = smbViewModel.currentDirectory
        
        // Parse folderName in case it contains path separators
        let components = folderName.components(separatedBy: "/")
        
        var totalBytes: UInt64 = 0
        var localCompletedFiles = [String]()
        
        do {
            // Create the local folder
            try FileManager.default.createDirectory(at: destURL, withIntermediateDirectories: true, attributes: nil)
            
            // Figure out the target path
            let targetPath: String
            if components.count > 1 {
                // If folderName contains path separators, we need to navigate to the full path
                targetPath = startingDir.isEmpty ? folderName : "\(startingDir)/\(folderName)"
            } else {
                // Simple folder name - just append to current directory
                targetPath = startingDir.isEmpty ? folderName : "\(startingDir)/\(folderName)"
            }
            
            print("Navigating to: \(targetPath)")
            
            do {
                // First try to navigate directly to the target path
                try await smbViewModel.listFiles(targetPath)
            } catch {
                print("Failed to navigate directly to \(targetPath): \(error)")
                
                // If direct navigation fails, try navigating component by component
                var currentPath = startingDir
                for component in components {
                    let nextPath = currentPath.isEmpty ? component : "\(currentPath)/\(component)"
                    
                    do {
                        try await smbViewModel.listFiles(nextPath)
                        currentPath = nextPath
                    } catch {
                        print("Failed to navigate to component \(component): \(error)")
                        throw TransferError.navigationFailed(path: nextPath, underlyingError: error)
                    }
                }
            }
            
            // At this point, we should be in the target directory
            let files = smbViewModel.files
            
            // Skip the "." and ".." entries if they exist
            let validFiles = files.filter { $0.name != "." && $0.name != ".." }
            
            // Process each file or subfolder
            for (index, file) in validFiles.enumerated() {
                // Skip already completed files if resuming
                if self.completedFiles.contains(file.name) {
                    continue
                }
                
                // Update UI for current item (not too frequently to avoid UI thrashing)
                if index % 5 == 0 || index == validFiles.count - 1 {
                    await MainActor.run {
                        self.currentTransferItem = file.name
                        self.transferProgress = Double(index) / Double(validFiles.count)
                    }
                }
                
                if smbViewModel.isDirectory(file) {
                    // Recursively download subfolders
                    let subfolderURL = destURL.appendingPathComponent(file.name)
                    
                    // For subfolders, we're already in the correct parent directory
                    let subfoldertotalBytes = try await downloadFolderRecursivelyWithSizeTracking(
                        folderName: file.name,
                        destURL: subfolderURL,
                        smbViewModel: smbViewModel
                    )
                    
                    totalBytes += subfoldertotalBytes
                    localCompletedFiles.append(file.name)
                    
                    createCheckpoint(
                        remotePath: targetPath,
                        localPath: destURL,
                        completedItems: localCompletedFiles,
                        totalItems: validFiles.count,
                        bytesTransferred: totalBytes
                    )
                    
                    try await smbViewModel.listFiles(smbViewModel.currentDirectory)
                } else {
                    // Download individual file
                    let fileURL = destURL.appendingPathComponent(file.name)
                    
                    do {
                        let data = try await smbViewModel.downloadFile(fileName: file.name, trackTransfer: false)
                        try data.write(to: fileURL)
                        
                        // Add file size to total
                        totalBytes += UInt64(data.count)
                        localCompletedFiles.append(file.name)
                        
                        // Update progress counter (batch updates)
                        await MainActor.run {
                            self.processedTransferItems += 1
                        }
                        
                        // Create checkpoint periodically
                        if index % 10 == 0 || index == validFiles.count - 1 {
                            createCheckpoint(
                                remotePath: targetPath,
                                localPath: destURL,
                                completedItems: localCompletedFiles,
                                totalItems: validFiles.count,
                                bytesTransferred: totalBytes
                            )
                        }
                    } catch {
                        print("Error downloading file '\(file.name)': \(error)")
                    }
                }
            }
            
            // Return to where we started
            try await smbViewModel.listFiles(startingDir)
        } catch {
            print("Error downloading folder '\(folderName)' to '\(destURL.path)': \(error)")
            
            // Try to get back to the starting directory
            do {
                try await smbViewModel.listFiles(startingDir)
            } catch {
                print("Failed to return to starting directory: \(error)")
            }
            
            // Re-throw with context
            if error is TransferError {
                throw error
            } else {
                throw TransferError.folderDownloadFailed(folderName: folderName, underlyingError: error)
            }
        }
        
        await MainActor.run {
            self.completedFiles.append(contentsOf: localCompletedFiles)
        }
        
        return totalBytes
    }
}
