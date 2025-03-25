//
//  FileTransferViewModel+FileOperations.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 25/3/25.
//

import Foundation
import SMBClient

// MARK: - File Operations
extension FileTransferViewModel {
    /// List files in a specific directory
    func listFiles(_ path: String) async throws {
        guard let client, connectionState == .connected else {
            await MainActor.run {
                self.errorMessage = "Not connected to server"
            }
            throw TransferError.connectionFailed(
                host: credentials.host,
                underlyingError: nil
            )
        }
        
        await MainActor.run {
            self.transferState = .listing(path)
        }
        
        do {
            let files = try await client.listDirectory(path: path)
            
            await MainActor.run {
                self.files = files
                self.currentDirectory = path
                self.transferState = .none
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to list files: \(error.localizedDescription)"
                self.transferState = .none
            }
            throw TransferError.navigationFailed(
                path: path,
                underlyingError: error
            )
        }
    }
    
    /// Navigate up one directory
    func navigateUp() async throws {
        if currentDirectory.isEmpty {
            return
        }
        
        let components = currentDirectory.components(separatedBy: "/")
        let newPath = components.dropLast().joined(separator: "/")
        
        try await listFiles(newPath)
    }
    
    /// Navigate to a subdirectory
    func navigateToDirectory(_ directoryName: String) async throws {
        let newPath = pathForItem(directoryName)
        try await listFiles(newPath)
    }
    
    /// Download a file from the server
    func downloadFile(fileName: String, trackTransfer: Bool = true) async throws -> Data {
        guard let client, connectionState == .connected else {
            await MainActor.run {
                self.errorMessage = "Not connected to server"
            }
            throw TransferError.connectionFailed(
                host: credentials.host,
                underlyingError: nil
            )
        }
        
        let filePath = pathForItem(fileName)
        
        // Get file info to know the size
        let fileInfo = try await getFileInfo(fileName: fileName)
        let fileSize = fileInfo?.size ?? 0
        
        await MainActor.run {
            self.transferState = .downloading(fileName)
            self.transferProgress = 0.0
            
            if trackTransfer {
                self.startTransferTracking(
                    fileName: fileName,
                    fileSize: fileSize,
                    type: .download
                )
            }
        }
        
        do {
            let data = try await client.download(path: filePath) { [weak self] progress in
                guard let self else { return }
                
                Task { @MainActor in
                    self.transferProgress = progress
                    
                    if trackTransfer {
                        let bytesTransferred = UInt64(progress * Double(fileSize))
                        self.updateTransferProgress(bytesTransferred: bytesTransferred)
                    }
                }
            }
            
            await MainActor.run {
                self.transferState = .none
                self.transferProgress = 1.0
                
                if trackTransfer {
                    self.finishTransferTracking(fileSize: UInt64(data.count))
                }
            }
            
            return data
        } catch {
            await MainActor.run {
                self.errorMessage = "Download failed: \(error.localizedDescription)"
                self.transferState = .none
                
                if trackTransfer {
                    self.stopSpeedSamplingTimer()
                }
            }
            throw TransferError.fileDownloadFailed(
                fileName: fileName,
                underlyingError: error
            )
        }
    }
    
    /// Upload a local file to the server
    func uploadLocalFile(url: URL) async throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw TransferError.securityScopedResourceFailed(url: url)
        }
        
        // Ensure we stop accessing when we're done
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let data = try Data(contentsOf: url)
            try await uploadFile(data: data, fileName: url.lastPathComponent)
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to read local file: \(error.localizedDescription)"
            }
            throw TransferError.localFileReadFailed(
                url: url,
                underlyingError: error
            )
        }
    }
    
    /// Upload a file to the server
    func uploadFile(data: Data, fileName: String) async throws {
        guard let client, connectionState == .connected else {
            await MainActor.run {
                self.errorMessage = "Not connected to server"
            }
            throw TransferError.connectionFailed(
                host: credentials.host,
                underlyingError: nil
            )
        }
        
        let filePath = pathForItem(fileName)
        let fileSize = UInt64(data.count)
        
        await MainActor.run {
            self.transferState = .uploading(fileName)
            self.transferProgress = 0.0
            self.startTransferTracking(
                fileName: fileName,
                fileSize: fileSize,
                type: .upload
            )
        }
        
        do {
            try await client.upload(content: data, path: filePath) { progress in
                Task { @MainActor in
                    self.transferProgress = progress
                    let bytesTransferred = UInt64(progress * Double(fileSize))
                    self.updateTransferProgress(bytesTransferred: bytesTransferred)
                }
            }
            
            await MainActor.run {
                self.transferProgress = 1.0
                self.transferState = .none
            }
            
            finishTransferTracking(fileSize: fileSize)
            
            try await listFiles(currentDirectory)
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Upload failed: \(error.localizedDescription)"
                self.transferState = .none
                self.stopSpeedSamplingTimer()
            }
            throw TransferError.fileUploadFailed(
                fileName: fileName,
                underlyingError: error
            )
        }
    }
    
    /// Get detailed information about a file
    private func getFileInfo(fileName: String) async throws -> File? {
        guard let client, connectionState == .connected else {
            throw TransferError.connectionFailed(
                host: credentials.host,
                underlyingError: nil
            )
        }
        
        let path = currentDirectory.isEmpty ? "" : currentDirectory
        let files = try await client.listDirectory(path: path)
        return files.first { $0.name == fileName }
    }
}

// MARK: - Helper Methods
extension FileTransferViewModel {
    func isDirectory(_ file: File) -> Bool {
        file.isDirectory
    }
    
    func getFileByName(_ fileName: String) -> File? {
        return files.first { $0.name == fileName }
    }
}
