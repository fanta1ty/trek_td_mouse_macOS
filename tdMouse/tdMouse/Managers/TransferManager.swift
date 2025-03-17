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
    // Transfer status
    @Published var activeTransfer: TransferDirection?
    @Published var currentTransferItem = ""
    @Published var totalTransferItems = 0
    @Published var processedTransferItems = 0
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
                let data = try await smbViewModel.downloadFile(fileName: file.name)
                try data.write(to: destinationURL)
                
                DispatchQueue.main.async {
                    Task {
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        
                        await MainActor.run {
                            self.activeTransfer = nil
                            self.currentTransferItem = ""
                            onComplete()
                        }
                    }
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
                
                DispatchQueue.main.async {
                    // Give time for UI to show completion
                    Task {
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        
                        await MainActor.run {
                            self.activeTransfer = nil
                            self.currentTransferItem = ""
                            onComplete()
                        }
                    }
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
            await MainActor.run {
                self.activeTransfer = .toRemote
                self.totalTransferItems = 0
                self.processedTransferItems = 0
            }
            
            await uploadFolderRecursively(url: folder.url, smbViewModel: smbViewModel)
            
            await MainActor.run {
                self.activeTransfer = nil
                self.currentTransferItem = ""
                
                Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    
                    await MainActor.run {
                        self.totalTransferItems = 0
                        self.processedTransferItems = 0
                        onComplete()
                    }
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
            await MainActor.run {
                self.activeTransfer = .toLocal
                self.totalTransferItems = 0
                self.processedTransferItems = 0
            }
            
            await downloadFolderRecursively(
                folderName: folder.name,
                destURL: destination,
                smbViewModel: smbViewModel
            )
            
            await MainActor.run {
                self.activeTransfer = nil
                self.currentTransferItem = ""
                
                Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    
                    await MainActor.run {
                        self.totalTransferItems = 0
                        self.processedTransferItems = 0
                        onComplete()
                    }
                }
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
                
                // Try to decode as JSON first
                if let jsonString = jsonString {
                    if let jsonData = jsonString.data(using: .utf8),
                       let fileInfo = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String],
                       let fileName = fileInfo["name"],
                       let isDirectoryStr = fileInfo["isDirectory"],
                       let type = fileInfo["type"], type == "smbFile" {
                        
                        // We got a valid SMB file drop
                        let isDirectory = isDirectoryStr == "true"
                        
                        if let file = smbViewModel.getFileByName(fileName) {
                            let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(fileName)
                            
                            if isDirectory {
                                self.startFolderDownload(folder: file, destination: localURL, smbViewModel: smbViewModel) {
                                    localViewModel.refreshFiles()
                                }
                            } else {
                                self.startSingleFileDownload(file: file, destinationURL: localURL, smbViewModel: smbViewModel) {
                                    localViewModel.refreshFiles()
                                }
                            }
                        }
                    } else {
                        // Try simple string if JSON parsing failed
                        if let fileName = secureData as? String,
                           let file = smbViewModel.getFileByName(fileName) {
                            let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(fileName)
                            self.startSingleFileDownload(file: file, destinationURL: localURL, smbViewModel: smbViewModel) {
                                localViewModel.refreshFiles()
                            }
                        }
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
            // Create the folder on SMB server if not at root
            try await smbViewModel.createDirectory(directoryName: folderName)
            
            // Get all items in the local folder
            let fileManager = FileManager.default
            guard let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey]) else {
                return
            }
            
            // Count total items for progress tracking
            let totalItems = contents.count
            
            DispatchQueue.main.async {
                self.totalTransferItems += totalItems
            }
            
            // Upload each item
            for (index, itemURL) in contents.enumerated() {
                let isDir = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                
                // Update progress info
                await MainActor.run {
                    self.currentTransferItem = itemURL.lastPathComponent
                }
                
                if isDir {
                    // For subdirectories, we need to:
                    // 1. Navigate to the target directory on SMB
                    let currentDir = smbViewModel.currentDirectory
                    
                    try await smbViewModel.navigateToDirectory(folderName)
                    
                    // 2. Recursively upload the subdirectory contents
                    await uploadFolderRecursively(
                        url: itemURL,
                        parentPath: fullSmbPath,
                        smbViewModel: smbViewModel
                    )
                    
                    // 3. Navigate back to original directory
                    try await smbViewModel.listFiles(currentDir)
                } else {
                    // Navigate to correct directory first
                    let currentDir = smbViewModel.currentDirectory
                    try await smbViewModel.navigateToDirectory(folderName)
                    
                    // Upload file
                    try await smbViewModel.uploadLocalFile(url: itemURL)
                    
                    // Navigate back
                    try await smbViewModel.listFiles(currentDir)
                }
                
                await MainActor.run {
                    self.processedTransferItems += 1
                }
            }
            
        } catch {
            print("Error uploading folder: \(error)")
        }
    }
    
    private func downloadFolderRecursively(
        folderName: String,
        destURL: URL,
        smbViewModel: FileTransferViewModel
    ) async {
        // Track our path to avoid loops
        let startingDir = smbViewModel.currentDirectory
        let targetDir = startingDir.isEmpty ? folderName : "\(startingDir)/\(folderName)"
        
        do {
            // Create the local folder
            try FileManager.default.createDirectory(at: destURL, withIntermediateDirectories: true)
            
            // Navigate to the target directory directly instead of navigating relatively
            try await smbViewModel.listFiles(targetDir)
            
            // List files in the folder
            let files = smbViewModel.files
            
            // Skip the "." and ".." entries if they exist
            let validFiles = files.filter { $0.name != "." && $0.name != ".." }
            
            await MainActor.run {
                self.totalTransferItems += validFiles.count
            }
            
            // Download each file or subfolder
            for file in validFiles {
                // Update progress
                await MainActor.run {
                    self.currentTransferItem = file.name
                }
                
                if smbViewModel.isDirectory(file) {
                    // Recursively download subfolders
                    let subfolderURL = destURL.appendingPathComponent(file.name)
                    let subfolderPath = targetDir.isEmpty ? file.name : "\(targetDir)/\(file.name)"
                    
                    // Use the full path instead of relative navigation
                    await downloadFolderRecursively(
                        folderName: subfolderPath,
                        destURL: subfolderURL,
                        smbViewModel: smbViewModel
                    )
                    
                    // Navigate back to the current folder after each subfolder
                    try await smbViewModel.listFiles(targetDir)
                } else {
                    // Use the full path to download the file
                    let fullPath = targetDir.isEmpty ? file.name : "\(targetDir)/\(file.name)"
                    
                    // Download individual file
                    let fileURL = destURL.appendingPathComponent(file.name)
                    
                    // Save current directory
                    let tempDir = smbViewModel.currentDirectory
                    
                    // Navigate to the file's parent directory if needed
                    if smbViewModel.currentDirectory != targetDir {
                        try await smbViewModel.listFiles(targetDir)
                    }
                    
                    let data = try await smbViewModel.downloadFile(fileName: file.name)
                    try data.write(to: fileURL)
                    
                    // Ensure we're back in the right directory
                    if smbViewModel.currentDirectory != tempDir {
                        try await smbViewModel.listFiles(tempDir)
                    }
                }
                
                await MainActor.run {
                    self.processedTransferItems += 1
                }
            }
            
            // Always navigate back to starting directory
            try await smbViewModel.listFiles(startingDir)
            
        } catch {
            print("Error downloading folder '\(folderName)' to '\(destURL.path)': \(error)")
            
            // Even if we hit an error, try to get back to the starting directory
            do {
                try await smbViewModel.listFiles(startingDir)
            } catch {
                print("Failed to return to starting directory: \(error)")
            }
        }
    }
}
