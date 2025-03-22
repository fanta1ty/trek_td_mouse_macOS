//
//  TransferManager+FolderUploads.swift
//  tdMouse
//
//  Created by mobile on 22/3/25.
//

import SwiftUI
import SMBClient

extension TransferManager {
    func startFolderUpload(
        folder: LocalFile,
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
                self.activeTransfer = .toRemote
                self.totalTransferItems = 0
                self.processedTransferItems = 0
                self.currentTransferItem = folder.name
                self.errorMessage = ""
                self.completedFiles = []
            }
            
            do {
                // First, count all files in the folder to set accurate totals
                let fileCount = await countFilesInFolder(url: folder.url)
                
                await MainActor.run {
                    self.totalTransferItems = fileCount > 0 ? fileCount : 1
                }
                
                // Now upload the folder and track total bytes
                totalBytes = try await uploadFolderRecursively(
                    url: folder.url,
                    smbViewModel: smbViewModel
                )
                
                // Create and display transfer summary
                let endTime = Date()
                
                // Generate transfer stats
                let stats = TransferStats(
                    fileSize: totalBytes,
                    fileName: "\(folder.name) (Folder)",
                    startTime: startTime,
                    endTime: endTime,
                    transferType: .upload,
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
                
                // Wait a moment to show completion before clearing
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    self.activeTransfer = nil
                    self.currentTransferItem = ""
                    self.totalTransferItems = 0
                    self.processedTransferItems = 0
                    self.isFolderTransferInProgress = false
                    onComplete()
                }
            } catch {
                print("Folder upload error: \(error)")
                await MainActor.run {
                    self.activeTransfer = nil
                    self.currentTransferItem = ""
                    self.errorMessage = error is TransferError ? error.localizedDescription : "Upload failed: \(error.localizedDescription)"
                    self.isFolderTransferInProgress = false
                }
            }
        }
    }
    
    func uploadFolderRecursively(
        url: URL,
        parentPath: String = "",
        smbViewModel: FileTransferViewModel
    ) async throws -> UInt64 {
        // Get folder name from URL
        let folderName = url.lastPathComponent
        let fullSmbPath = parentPath.isEmpty ? folderName : "\(parentPath)/\(folderName)"
        
        var totalBytes: UInt64 = 0
        var localCompletedFiles = [String]()
        
        do {
            // Create the folder on SMB server if needed
            if parentPath.isEmpty {
                try await smbViewModel.createDirectory(directoryName: folderName)
            } else {
                // Navigate to parent directory and create subfolder
                let currentDir = smbViewModel.currentDirectory
                try await smbViewModel.listFiles(parentPath)
                try await smbViewModel.createDirectory(directoryName: folderName)
                try await smbViewModel.listFiles(currentDir)
            }
            
            // Get all items in the local folder
            let fileManager = FileManager.default
            guard let contents = try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey]
            ) else {
                return 0
            }
            
            // Process each item
            for itemURL in contents where (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                let isDir = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                
                // Update UI only once per file/folder to avoid excessive updates
                await MainActor.run {
                    self.currentTransferItem = itemURL.lastPathComponent
                }
                
                let subdirBytes = try await uploadFolderRecursively(
                    url: itemURL,
                    parentPath: fullSmbPath,
                    smbViewModel: smbViewModel
                )
                
                totalBytes += subdirBytes
                localCompletedFiles.append(itemURL.lastPathComponent)
                
                // Periodically create checkpoint
                createCheckpoint(
                    remotePath: fullSmbPath,
                    localPath: url,
                    completedItems: localCompletedFiles,
                    totalItems: contents.count,
                    bytesTransferred: totalBytes
                )
            }
            // Collect all files (not directories)
            let files = contents.filter {
                ((try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false) == false
            }
            
            // Process regular files (we can potentially use task groups here for up to 5 concurrent uploads)
            var processedFileCount = 0
            
            // Navigate to target directory once for all files
            let currentDir = smbViewModel.currentDirectory
            try await smbViewModel.listFiles(fullSmbPath)
            
            for itemURL in files {
                // Update UI only once per file to avoid excessive updates
                await MainActor.run {
                    self.currentTransferItem = itemURL.lastPathComponent
                }
                
                do {
                    // Upload file
                    let data = try Data(contentsOf: itemURL)
                    try await smbViewModel.uploadFile(data: data, fileName: itemURL.lastPathComponent)
                    
                    // Track progress
                    totalBytes += UInt64(data.count)
                    localCompletedFiles.append(itemURL.lastPathComponent)
                    
                    // Update progress (batch updates to avoid UI thrashing)
                    processedFileCount += 1
                    await MainActor.run {
                        self.processedTransferItems += 1
                    }
                    
                    // Create checkpoint every 5 files
                    if processedFileCount % 5 == 0 || processedFileCount == files.count {
                        createCheckpoint(
                            remotePath: fullSmbPath,
                            localPath: url,
                            completedItems: localCompletedFiles,
                            totalItems: contents.count,
                            bytesTransferred: totalBytes
                        )
                    }
                } catch {
                    print("Error uploading file \(itemURL.lastPathComponent): \(error)")
                    // Continue with the next file instead of failing the entire operation
                }
            }
            
            // Navigate back to original directory
            try await smbViewModel.listFiles(currentDir)
        } catch {
            print("Error uploading folder: \(error)")
            throw TransferError.folderUploadFailed(folderName: folderName, underlyingError: error)
        }
        
        return totalBytes
    }
    
    private func downloadFolderRecursively(
        folderName: String,
        destURL: URL,
        smbViewModel: FileTransferViewModel
    ) async {
        // For first level, folderName might include path info from the drag operation
        // We need to handle possible paths like "AFK/Test" correctly
        
        // Get the starting state
        let startingDir = smbViewModel.currentDirectory
        
        // Parse folderName in case it contains path separators
        let components = folderName.components(separatedBy: "/")
        let simpleFolderName = components.last ?? folderName
        
        do {
            // Create the local folder
            try FileManager.default.createDirectory(at: destURL, withIntermediateDirectories: true, attributes: nil)
            
            // Figure out the target path based on whether folderName has path separators
            let targetPath: String
            if components.count > 1 {
                // If folderName contains path separators, navigate to each component
                if startingDir.isEmpty {
                    targetPath = folderName
                } else {
                    targetPath = "\(startingDir)/\(folderName)"
                }
            } else {
                // Simple folder name
                if startingDir.isEmpty {
                    targetPath = folderName
                } else {
                    targetPath = "\(startingDir)/\(folderName)"
                }
            }
            
            print("Trying to navigate to: \(targetPath)")
            
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
                        throw error
                    }
                }
            }
            
            // At this point, we should be in the target directory
            // List files in the folder
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
                    // so we can just pass the simple folder name
                    await downloadFolderRecursively(
                        folderName: file.name,
                        destURL: subfolderURL,
                        smbViewModel: smbViewModel
                    )
                    
                    // After handling a subfolder, make sure we're back in the right directory
                    // If our folder had a path like "AFK/Test", we need to return to that
                    try await smbViewModel.listFiles(smbViewModel.currentDirectory)
                } else {
                    // Download individual file
                    let fileURL = destURL.appendingPathComponent(file.name)
                    let data = try await smbViewModel.downloadFile(fileName: file.name, trackTransfer: false)
                    try data.write(to: fileURL)
                    
                    // Update progress counter
                    await MainActor.run {
                        self.processedTransferItems += 1
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
        }
    }
}
