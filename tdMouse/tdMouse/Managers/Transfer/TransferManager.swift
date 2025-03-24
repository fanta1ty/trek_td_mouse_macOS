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
    
    var activeTasks: [UUID: TransferTask] = [:]
    
    // Tracking properties
    var completedFiles = [String]()
    
    var isTransferInProgress: Bool {
        return activeTransfer != nil || isFolderTransferInProgress
    }
    
    init() {
        // Try to load a saved checkpoint on initialization
        loadCheckpoint()
    }
    
    func cancelAllTransfers() {
        for task in activeTasks.values {
            task.cancel()
        }
        activeTasks.removeAll()
        
        DispatchQueue.main.async {
            self.activeTransfer = nil
            self.currentTransferItem = ""
            self.totalTransferItems = 0
            self.processedTransferItems = 0
            self.transferProgress = 0.0
            self.isFolderTransferInProgress = false
        }
    }
    
    func resumeTransfer(completion: @escaping (Bool) -> Void) {
        guard let checkpoint = lastCheckpoint, checkpoint.isValid else {
            completion(false)
            return
        }
        
        // Implementation would depend on the transfer type
        // For simplicity, we'll just check if there's a valid checkpoint
        completion(true)
    }
    
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
        bytesTransferred: UInt64,
        direction: TransferDirection
    ) {
        lastCheckpoint = TransferCheckpoint(
            remotePath: remotePath,
            localPath: localPath,
            completedItems: completedItems,
            totalItems: totalItems,
            bytesTransferred: bytesTransferred,
            direction: direction
        )
        
        // Persist this checkpoint to disk for true resumability
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
    
    private func loadCheckpoint() {
        let url = getCheckpointURL()
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            lastCheckpoint = try decoder.decode(TransferCheckpoint.self, from: data)
            
            // Validate checkpoint
            if let checkpoint = lastCheckpoint, !checkpoint.isValid {
                lastCheckpoint = nil
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            print("Failed to load checkpoint: \(error)")
            lastCheckpoint = nil
            
            // Remove corrupted checkpoint file
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    private func getCheckpointURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("SMBFileTransfer")
        
        // Create app folder if it doesn't exist
        if !FileManager.default.fileExists(atPath: appFolder.path) {
            try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }
        
        return appFolder.appendingPathComponent("transfer_checkpoint.json")
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
        smbViewModel: FileTransferViewModel
    ) async -> Int {
        let startingDir = smbViewModel.currentDirectory
        var count = 0
        
        do {
            // Navigate to the target folder
            let targetPath = startingDir.isEmpty ? folderName : "\(startingDir)/\(folderName)"
            try await smbViewModel.listFiles(targetPath)
            
            // List files
            let files = smbViewModel.files.filter { $0.name != "." && $0.name != ".." }
            
            // Count regular files
            count += files.filter { !smbViewModel.isDirectory($0) }.count
            
            // Recursively count files in subdirectories
            for file in files where smbViewModel.isDirectory(file) {
                count += await countRemoteFilesInFolder(
                    folderName: file.name,
                    smbViewModel: smbViewModel
                )
            }
            
            // Return to original directory
            try await smbViewModel.listFiles(smbViewModel.currentDirectory)
        } catch {
            print("Error counting files in folder \(folderName): \(error)")
        }
        
        return count
    }
    
    func countLocalFilesInFolder(url: URL) async -> Int {
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else {
            return 0
        }
        
        var count = 0
        
        for itemURL in contents {
            let isDir = itemURL.isDirectory
            
            if isDir {
                count += await countLocalFilesInFolder(url: itemURL)
            } else {
                count += 1
            }
        }
        
        return count
    }
    
    func localFileFromURL(_ url: URL) -> LocalFile? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [
                .isDirectoryKey,
                .fileSizeKey,
                .contentModificationDateKey
            ])
            
            let isDirectory = resourceValues.isDirectory ?? false
            let size = resourceValues.fileSize ?? 0
            let modificationDate = resourceValues.contentModificationDate
            
            return LocalFile(
                name: url.lastPathComponent,
                url: url,
                isDirectory: isDirectory,
                size: Int64(size),
                modificationDate: modificationDate
            )
        } catch {
            // Fallback to basic file manager attributes if resourceValues fails
            let attributes = url.safeAttributes()
            let isDirectory = attributes?[.type] as? FileAttributeType == .typeDirectory
            let size = attributes?[.size] as? NSNumber ?? 0
            let modificationDate = attributes?[.modificationDate] as? Date
            
            return LocalFile(
                name: url.lastPathComponent,
                url: url,
                isDirectory: isDirectory,
                size: size.int64Value,
                modificationDate: modificationDate
            )
        }
    }
}
