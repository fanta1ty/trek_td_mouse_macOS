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
    private var lastCheckpoint: TransferCheckpoint?
    
    // Tracking properties
    private var completedFiles = [String]()
    
    // MARK: - Path Handling
    private func resolvePath(
        base: String,
        component: String
    ) -> String {
        if base.isEmpty {
            return component
        } else {
            return "\(base)/\(component)"
        }
    }
    
    private func createCheckpoint(
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
    
    private func saveCheckpoint() {
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

// MARK: - Single File Transfers
extension TransferManager {
    func startSingleFileDownload(
        file: File,
        destinationURL: URL,
        smbViewModel: FileTransferViewModel,
        onComplete: @escaping () -> Void
    ) {
        Task {
            await MainActor.run {
                self.activeTransfer = .toLocal
                self.currentTransferItem = file.name
            }
            
            do {
                // Download file with tracking enabled
                let data = try await smbViewModel.downloadFile(fileName: file.name, trackTransfer: true)
                try data.write(to: destinationURL)
                
                // Wait a moment to show completion before clearing
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    self.activeTransfer = nil
                    self.currentTransferItem = ""
                    onComplete()
                }
            } catch {
                print("Download failed: \(error)")
                await MainActor.run {
                    self.activeTransfer = nil
                    self.currentTransferItem = ""
                }
            }
        }
    }
    
    func startSingleFileUpload(
        file: LocalFile,
        smbViewModel: FileTransferViewModel,
        onComplete: @escaping () -> Void
    ) {
        Task {
            await MainActor.run {
                self.activeTransfer = .toRemote
                self.currentTransferItem = file.name
            }
            
            do {
                try await smbViewModel.uploadLocalFile(url: file.url)
                
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    self.activeTransfer = nil
                    self.currentTransferItem = ""
                    onComplete()
                }
            } catch {
                print("Upload error: \(error)")
                await MainActor.run {
                    self.activeTransfer = nil
                    self.currentTransferItem = ""
                }
            }
        }
    }
}

// MARK: - Folder Transfers
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
            }
            
            do {
                // First, count all files in the folder to set accurate totals
                let fileCount = await countFilesInFolder(url: folder.url)
                
                await MainActor.run {
                    self.totalTransferItems = fileCount
                }
                
                // Now upload the folder and track total bytes
                totalBytes = await uploadFolderRecursivelyWithSizeTracking(
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
                    self.totalTransferItems = 0
                    self.processedTransferItems = 0
                    self.isFolderTransferInProgress = false
                }
            }
        }
    }
    
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
                totalBytes = await downloadFolderRecursivelyWithSizeTracking(
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
                    self.totalTransferItems = 0
                    self.processedTransferItems = 0
                    self.isFolderTransferInProgress = false
                }
            }
        }
    }

    // Modified version of downloadFolderRecursively that also returns the total bytes downloaded
    private func downloadFolderRecursivelyWithSizeTracking(
        folderName: String,
        destURL: URL,
        smbViewModel: FileTransferViewModel
    ) async -> UInt64 {
        // For first level, folderName might include path separators
        // Get the starting state
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
                if startingDir.isEmpty {
                    targetPath = folderName
                } else {
                    targetPath = "\(startingDir)/\(folderName)"
                }
            } else {
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
                    let subfoldertotalBytes = await downloadFolderRecursivelyWithSizeTracking(
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
                    let data = try await smbViewModel.downloadFile(fileName: file.name, trackTransfer: false)
                    try data.write(to: fileURL)
                    
                    // Add file size to total
                    totalBytes += UInt64(data.count)
                    
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
        
        return totalBytes
    }
    
    private func uploadFolderRecursivelyWithSizeTracking(
        url: URL,
        parentPath: String = "",
        smbViewModel: FileTransferViewModel
    ) async -> UInt64 {
        // Get folder name from URL
        let folderName = url.lastPathComponent
        let fullSmbPath = parentPath.isEmpty ? folderName : "\(parentPath)/\(folderName)"
        
        var totalBytes: UInt64 = 0
        
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
            for itemURL in contents {
                let isDir = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                
                // Update UI only once per file/folder to avoid excessive updates
                await MainActor.run {
                    self.currentTransferItem = itemURL.lastPathComponent
                }
                
                if isDir {
                    // Recursively upload subdirectories
                    let subdirBytes = await uploadFolderRecursivelyWithSizeTracking(
                        url: itemURL,
                        parentPath: fullSmbPath,
                        smbViewModel: smbViewModel
                    )
                    
                    totalBytes += subdirBytes
                } else {
                    // Navigate to correct directory
                    let currentDir = smbViewModel.currentDirectory
                    try await smbViewModel.listFiles(fullSmbPath)
                    
                    // Upload file
                    let data = try Data(contentsOf: itemURL)
                    try await smbViewModel.uploadFile(data: data, fileName: itemURL.lastPathComponent)
                    
                    // Add file size to total
                    totalBytes += UInt64(data.count)
                    
                    // Navigate back
                    try await smbViewModel.listFiles(currentDir)
                    
                    // Update progress (on main actor to prevent multiple updates)
                    await MainActor.run {
                        self.processedTransferItems += 1
                    }
                }
            }
        } catch {
            print("Error uploading folder: \(error)")
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
                                            destinationURL: localURL,
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
                                destinationURL: localURL,
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
    private func uploadFolderRecursively(
        url: URL,
        parentPath: String = "",
        smbViewModel: FileTransferViewModel
    ) async {
        // Get folder name from URL
        let folderName = url.lastPathComponent
        let fullSmbPath = parentPath.isEmpty ? folderName : "\(parentPath)/\(folderName)"
        
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
                includingPropertiesForKeys: [.isDirectoryKey]
            ) else {
                return
            }
            
            // Process each item
            for itemURL in contents {
                let isDir = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                
                // Update UI only once per file/folder to avoid excessive updates
                await MainActor.run {
                    self.currentTransferItem = itemURL.lastPathComponent
                }
                
                if isDir {
                    // Recursively upload subdirectories
                    await uploadFolderRecursively(
                        url: itemURL,
                        parentPath: fullSmbPath,
                        smbViewModel: smbViewModel
                    )
                } else {
                    // Navigate to correct directory
                    let currentDir = smbViewModel.currentDirectory
                    try await smbViewModel.listFiles(fullSmbPath)
                    
                    // Upload file
                    let data = try Data(contentsOf: itemURL)
                    try await smbViewModel.uploadFile(data: data, fileName: itemURL.lastPathComponent)
                    
                    // Navigate back
                    try await smbViewModel.listFiles(currentDir)
                    
                    // Update progress (on main actor to prevent multiple updates)
                    await MainActor.run {
                        self.processedTransferItems += 1
                    }
                }
            }
        } catch {
            print("Error uploading folder: \(error)")
        }
    }
    
    private func countFilesInFolder(url: URL) async -> Int {
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
    private func countRemoteFilesInFolder(
        folderName: String,
        parentPath: String = "",
        smbViewModel: FileTransferViewModel
    ) async -> Int {
        do {
            // Determine full path
            let fullPath: String
            if parentPath.isEmpty {
                fullPath = folderName
            } else {
                fullPath = "\(parentPath)/\(folderName)"
            }
            
            // Save current directory
            let currentDir = smbViewModel.currentDirectory
            
            // Navigate to folder
            try await smbViewModel.listFiles(fullPath)
            
            // Get all files excluding . and ..
            let files = smbViewModel.files.filter { $0.name != "." && $0.name != ".." }
            
            var count = 0
            
            // Count files and recursive folders
            for file in files {
                if smbViewModel.isDirectory(file) {
                    count += await countRemoteFilesInFolder(
                        folderName: file.name,
                        parentPath: fullPath,
                        smbViewModel: smbViewModel
                    )
                } else {
                    count += 1
                }
            }
            
            // Restore original directory
            try await smbViewModel.listFiles(currentDir)
            
            return count
        } catch {
            print("Error counting files in folder: \(error)")
            return 0
        }
    }
}
