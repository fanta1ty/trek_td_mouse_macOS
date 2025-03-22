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
