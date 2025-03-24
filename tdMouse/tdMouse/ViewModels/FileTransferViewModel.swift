//
//  FileTransferViewModel.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 12/3/25.
//

import Combine
import SMBClient
import Foundation

class FileTransferViewModel: ObservableObject {
    // MARK: - Published Properties
    // Published properties for transfer statistics
    @Published var credentials: SMBServerCredentials
    @Published var isCredentialsValid: Bool = false
    @Published var shareName: String = ""
    @Published var currentDirectory: String = ""
    @Published var connectionState: ConnectionState = .disconnected
    @Published var transferState: TransferOperation = .none
    @Published var availableShares: [String] = []
    @Published var files: [File] = []
    @Published var transferProgress: Double = 0.0
    @Published var errorMessage: String = ""
    
    // Published properties for transfer stats
    @Published var lastTransferStats: TransferStats?
    @Published var showTransferSummary: Bool = false
    
    // MARK: - Private Properties
    private var client: SMBClient?
    private var cancellables = Set<AnyCancellable>()
    
    // Private properteis for tracking transfer progress
    private var transferStartTime: Date?
    private var speedSamples: [Double] = []
    private var speedSamplingTimer: Timer?
    private var lastTransferredBytes: UInt64 = 0
    private var currentTransferredBytes: UInt64 = 0
    private var currentFileName: String = ""
    private var currentTransferType: TransferStats.TransferType = .download
    
    init(credentials: SMBServerCredentials? = nil) {
        self.credentials = credentials ?? SMBServerCredentials.sample2
        
        $credentials
            .map { credential in
                !credential.host.isEmpty &&
                !credential.username.isEmpty
            }
            .assign(to: &$isCredentialsValid)
    }
    
    // MARK: - Public Methods
    /// Connect to the SMB server
    func connect() async throws {
        guard isCredentialsValid else {
            await MainActor.run {
                self.errorMessage = "Invalid credentials"
                self.connectionState = .error("Invalid credentials")
            }
            
            throw TransferError.authenticationFailed(
                host: credentials.host,
                underlyingError: nil
            )
        }
        
        await MainActor.run {
            self.connectionState = .connecting
            self.errorMessage = ""
        }
        
        do {
            let newClient = SMBClient(host: credentials.host, port: credentials.port)
            try await newClient.login(username: credentials.username, password: credentials.password)
            
            await MainActor.run {
                self.client = newClient
                self.connectionState = .connected
            }
            
            // Fetch available shares after successful connection
            try await fetchShares()
        } catch {
            await MainActor.run {
                self.connectionState = .error(error.localizedDescription)
                self.errorMessage = "Connection failed: \(error.localizedDescription)"
            }
            
            throw TransferError.connectionFailed(
                host: credentials.host,
                underlyingError: error
            )
        }
    }
    
    /// Fetch available shares from the server
    func fetchShares() async throws {
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
            self.transferState = .listing("shares")
        }
        
        do {
            let shares = try await client.listShares()
            
            await MainActor.run {
                self.availableShares = shares.map({ $0.name })
                self.transferState = .none
            }
        } catch {
            await MainActor.run {
                self.transferState = .none
                self.errorMessage = "Failed to list shares: \(error.localizedDescription)"
            }
            
            throw TransferError.navigationFailed(
                path: "shares",
                underlyingError: error
            )
        }
    }
    
    /// Disconnect from the SMB server
    func disconnect() async throws {
        guard let client else {
            await MainActor.run {
                self.connectionState = .disconnected
            }
            return
        }
        
        do {
            if connectionState == .connected {
                try await client.disconnectShare()
                try await client.logoff()
            }
            
            await MainActor.run {
                self.client = nil
                self.connectionState = .disconnected
                self.availableShares = []
                self.files = []
                self.shareName = ""
                self.currentDirectory = ""
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Disconnect failed: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Connect to a specific share
    func connectToShare(_ shareName: String) async throws {
        guard let client, connectionState == .connected else {
            await MainActor.run {
                self.errorMessage = "Not connected to server"
            }
            throw TransferError.connectionFailed(
                host: credentials.host,
                underlyingError: nil
            )
        }
        
        do {
            try await client.connectShare(shareName)
            let files = try await client.listDirectory(path: currentDirectory)
            
            await MainActor.run {
                self.files = files
                self.shareName = shareName
                self.currentDirectory = ""
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to connect to share: \(error.localizedDescription)"
            }
            throw TransferError.navigationFailed(
                path: shareName,
                underlyingError: error
            )
        }
    }
    
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
        let newPath: String
        
        if currentDirectory.isEmpty {
            newPath = directoryName
        } else {
            newPath = "\(currentDirectory)/\(directoryName)"
        }
        
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
        
        let filePath: String
        if currentDirectory.isEmpty {
            filePath = fileName
        } else {
            filePath = "\(currentDirectory)/\(fileName)"
        }
        
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
        
        let itemPath: String
        if currentDirectory.isEmpty {
            itemPath = name
        } else {
            itemPath = "\(currentDirectory)/\(name)"
        }
        
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
        
        let directoryPath: String
        if currentDirectory.isEmpty {
            directoryPath = directoryName
        } else {
            directoryPath = "\(currentDirectory)/\(directoryName)"
        }
        
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
        
        let filePath: String
        if currentDirectory.isEmpty {
            filePath = fileName
        } else {
            filePath = "\(currentDirectory)/\(fileName)"
        }
        
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

// MARK: - Transfer Statistics Methods
extension FileTransferViewModel {
    /// Start tracking a new transfer
    private func startTransferTracking(
        fileName: String,
        fileSize: UInt64,
        type: TransferStats.TransferType
    ) {
        transferStartTime = Date()
        speedSamples = []
        lastTransferredBytes = 0
        currentTransferredBytes = 0
        currentFileName = fileName
        currentTransferType = type
        
        // Start the sampling timer
        stopSpeedSamplingTimer()
        speedSamplingTimer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true,
            block: { [weak self] _ in
                guard let self else { return }
                self.updateSpeedSample()
            })
    }
    
    /// Update the speed sample based on current progress
    private func updateSpeedSample() {
        guard let startTime = transferStartTime else { return }
        
        let now = Date()
        let elapsed = now.timeIntervalSince(startTime)
        if elapsed > 0 {
            // Calculate current speed in bytes per second
            let bytesTransferred = currentTransferredBytes - lastTransferredBytes
            let instantSpeed = Double(bytesTransferred) / 0.5
            
            if instantSpeed > 0 {
                speedSamples.append(instantSpeed)
            }
            
            lastTransferredBytes = currentTransferredBytes
        }
    }
    
    /// Stop the speed sampling timer
    private func stopSpeedSamplingTimer() {
        speedSamplingTimer?.invalidate()
        speedSamplingTimer = nil
    }
    
    /// Update the current transfer progress
    func updateTransferProgress(
        bytesTransferred: UInt64
    ) {
        currentTransferredBytes = bytesTransferred
    }
    
    /// Finish tracking a transfer and generate stats
    /// Finish tracking a transfer and generate stats
    private func finishTransferTracking(fileSize: UInt64) {
        stopSpeedSamplingTimer()
        
        guard let startTime = transferStartTime else {
            print("Error: attempted to finish transfer tracking with no start time")
            return
        }
        
        let endTime = Date()
        
        let stats = TransferStats(
            fileSize: fileSize,
            fileName: currentFileName,
            startTime: startTime,
            endTime: endTime,
            transferType: currentTransferType,
            speedSamples: speedSamples
        )
        
        // Make sure this runs on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lastTransferStats = stats
            
            // Add a small delay to ensure UI updates properly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showTransferSummary = true
            }
            
            print("Transfer complete: \(stats.fileName) - \(stats.fileSize)")
        }
        
        // Reset tracking data
        transferStartTime = nil
        speedSamples = []
        currentFileName = ""
    }
}
