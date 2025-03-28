//
//  FileTransferViewModel+DirectoryOperations.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 25/3/25.
//

import Foundation
import SMBClient

// MARK: - Directory Operations
extension FileTransferViewModel {
    /// Delete a file or directory on the server
    func deleteItem(name: String, isDirectory: Bool) async throws {
        guard let client, connectionState == .connected else {
            await MainActor.run {
                self.errorMessage = "Not connected to server"
            }
            throw TransferError.connectionFailed(
                host: credentials.host,
                underlyingError: nil
            )
        }
        
        let itemPath = pathForItem(name)
        
        do {
            try await client.deleteFile(path: itemPath)
            try await listFiles(currentDirectory)
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete item: \(error.localizedDescription)"
            }
            if isDirectory {
                throw TransferError.directoryDeletionFailed(
                    path: itemPath,
                    underlyingError: error
                )
            } else {
                throw TransferError.fileDeletionFailed(
                    path: itemPath,
                    underlyingError: error
                )
            }
        }
    }
    
    /// Delete a folder and all its contents recursively
    func deleteDirectoryRecursively(name: String) async throws {
        // First, navigate into the directory
        let currentDir = currentDirectory
        try await navigateToDirectory(name)
        
        // List all files in the directory
        let dirContents = files.filter { $0.name != "." && $0.name != ".." }
        
        // Delete each item
        for item in dirContents {
            if isDirectory(item) {
                // Recursively delete subdirectories
                try await deleteDirectoryRecursively(name: item.name)
            } else {
                // Delete individual files
                try await deleteItem(name: item.name, isDirectory: false)
            }
        }
        
        // Navigate back to parent directory
        try await listFiles(currentDir)
        
        // Now delete the empty directory
        try await deleteItem(name: name, isDirectory: true)
    }
    
    /// Create a new directory on the server
    func createDirectory(directoryName: String) async throws {
        guard let client, connectionState == .connected else {
            await MainActor.run {
                self.errorMessage = "Not connected to server"
            }
            throw TransferError.connectionFailed(
                host: credentials.host,
                underlyingError: nil
            )
        }
        
        let directoryPath = pathForItem(directoryName)
        
        do {
            try await client.createDirectory(path: directoryPath)
            try await listFiles(currentDirectory)
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to create directory: \(error.localizedDescription)"
            }
            throw TransferError.directoryCreationFailed(
                path: directoryPath,
                underlyingError: error
            )
        }
    }
}
