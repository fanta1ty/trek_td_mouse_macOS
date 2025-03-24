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
    ) async {
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
            
            // Create a transfer task for tracking
            let task = TransferTask(
                direction: .toLocal,
                remotePath: smbViewModel.currentDirectory.isEmpty ? folder.name : "\(smbViewModel.currentDirectory)/\(folder.name)",
                localPath: destination
            )
            
            activeTasks[task.id] = task
            
            // Download folder recursively and track file sizes
            task.start {
                do {
                    totalBytes = try await self.downloadFolderRecursively(
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
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    throw error
                }
            }
            
            // Wait for the task to finish
            while !task.isCompleted {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                
                if Task.isCancelled {
                    task.cancel()
                    await MainActor.run {
                        self.errorMessage = "Transfer was cancelled"
                    }
                    break
                }
            }
            
            // Clean up the task
            activeTasks.removeValue(forKey: task.id)
            
            // Check for errors
            if let error = task.error {
                throw error
            }
            
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
                self.totalTransferItems = 0
                self.processedTransferItems = 0
                self.isFolderTransferInProgress = false
                
                if let transferError = error as? TransferError {
                    self.errorMessage = transferError.localizedDescription
                } else {
                    self.errorMessage = "Folder download failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func downloadFolderRecursively(
        folderName: String,
        destURL: URL,
        smbViewModel: FileTransferViewModel
    ) async throws -> UInt64 {
        // For first level, folderName might include path separators
        let startingDir = smbViewModel.currentDirectory
        
        // Parse folderName in case it contains path separators
        let components = folderName.components(separatedBy: "/")
        let simpleFolderName = components.last ?? folderName
        
        var totalBytes: UInt64 = 0
        
        do {
            // Create the local folder
            try FileManager.default.createDirectory(at: destURL, withIntermediateDirectories: true, attributes: nil)
            
            // Figure out the target path
            let targetPath: String
            if components.count > 1 {
                // Handle paths with separators
                targetPath = startingDir.isEmpty ? folderName : "\(startingDir)/\(folderName)"
            } else {
                // Simple folder name
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
            for file in validFiles {
                // Update UI for current item
                await MainActor.run {
                    self.currentTransferItem = file.name
                }
                
                if smbViewModel.isDirectory(file) {
                    // Recursively download subfolders
                    let subfolderURL = destURL.appendingPathComponent(file.name)
                    
                    // For subfolders, we're already in the correct parent directory
                    let subfoldertotalBytes = try await downloadFolderRecursively(
                        folderName: file.name,
                        destURL: subfolderURL,
                        smbViewModel: smbViewModel
                    )
                    
                    totalBytes += subfoldertotalBytes
                    
                    // After handling a subfolder, make sure we're back in the right directory
                    try await smbViewModel.listFiles(smbViewModel.currentDirectory)
                } else {
                    // Download individual file
                    let fileURL = destURL.appendingPathComponent(file.name)
                    
                    // Skip if file already exists in completed files list
                    if completedFiles.contains(file.name) {
                        continue
                    }
                    
                    let data = try await smbViewModel.downloadFile(fileName: file.name, trackTransfer: false)
                    try data.write(to: fileURL)
                    
                    // Add file size to total
                    totalBytes += UInt64(data.count)
                    
                    // Track completed file
                    await MainActor.run {
                        self.completedFiles.append(file.name)
                        self.processedTransferItems += 1
                    }
                    
                    // Update checkpoint periodically
                    if self.processedTransferItems % 5 == 0 || self.processedTransferItems == self.totalTransferItems {
                        self.createCheckpoint(
                            remotePath: smbViewModel.currentDirectory,
                            localPath: destURL,
                            completedItems: self.completedFiles,
                            totalItems: self.totalTransferItems,
                            bytesTransferred: totalBytes,
                            direction: .toLocal
                        )
                    }
                }
                
                // Check for cancellation
                try Task.checkCancellation()
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
            
            throw TransferError.folderDownloadFailed(folderName: folderName, underlyingError: error)
        }
        
        return totalBytes
    }
}
