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
    
    // MARK: - Private Properties
    private var client: SMBClient?
    private var cancellables = Set<AnyCancellable>()
    
    init(credentials: SMBServerCredentials? = nil) {
        self.credentials = credentials ?? SMBServerCredentials(
            host: "192.168.50.24",
            username: "sambauser",
            password: "123456",
            domain: "share"
        )
        
        $credentials
            .map { credential in
                !credential.host.isEmpty &&
                !credential.username.isEmpty &&
                !credential.password.isEmpty
            }
            .assign(to: &$isCredentialsValid)
    }
    
    // MARK: - Public Methods
    /// Connect to the SMB server
    func connect() async throws {
        guard isCredentialsValid else {
            await MainActor.run { [weak self] in
                guard let self else { return }
                
                self.errorMessage = "Invalid credentials"
                self.connectionState = .error("Invalid credentials")
            }
            
            throw NSError(domain: "SMBClientError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        }
        
        await MainActor.run { [weak self] in
            guard let self else { return }
            
            self.connectionState = .connecting
            self.errorMessage = ""
        }
        
        do {
            let newClient = SMBClient(host: credentials.host, port: credentials.port)
            try await newClient.login(username: credentials.username, password: credentials.password)
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.client = newClient
                self.connectionState = .connected
            }
            
            // Fetch available shares after successful connection
            try await fetchShares()
        } catch {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.connectionState = .error(error.localizedDescription)
                self.errorMessage = "Connection failed: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Fetch available shares from the server
    func fetchShares() async throws {
        guard let client, connectionState == .connected else {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.errorMessage = "Not connected to server"
            }
            throw NSError(domain: "SMBClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not connected to server"])
        }
        
        await MainActor.run { [weak self] in
            guard let self else { return }
            self.transferState = .listing("shares")
        }
        
        do {
            let shares = try await client.listShares()
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                
                self.availableShares = shares.map({ $0.name })
                self.transferState = .none
            }
        } catch {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.transferState = .none
                self.errorMessage = "Failed to list shares: \(error.localizedDescription)"
            }
        }
    }
    
    /// Disconnect from the SMB server
    func disconnect() async throws {
        guard let client else {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.connectionState = .disconnected
            }
            return
        }
        
        do {
            if connectionState == .connected {
                try await client.disconnectShare()
                try await client.logoff()
            }
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.client = nil
                self.connectionState = .disconnected
                self.availableShares = []
                self.files = []
            }
        } catch {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.errorMessage = "Disconnect failed: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Connect to a specific share
    func connectToShare(_ shareName: String) async throws {
        guard let client, connectionState == .connected else {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.errorMessage = "Not connected to server"
            }
            throw NSError(domain: "SMBClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not connected to server"])
        }
        
        do {
            try await client.connectShare(shareName)
            let files = try await client.listDirectory(path: currentDirectory)
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.files = files
                self.shareName = shareName
                self.currentDirectory = ""
            }
            
        } catch {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.errorMessage = "Failed to connect to share: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// List files in a specific directory
    func listFiles(_ path: String) async throws {
        guard let client, connectionState == .connected else {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.errorMessage = "Not connected to server"
            }
            throw NSError(domain: "SMBClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not connected to server"])
        }
        
        await MainActor.run { [weak self] in
            guard let self else { return }
            self.transferState = .listing(path)
        }
        
        do {
            let files = try await client.listDirectory(path: path)
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.files = files
                self.currentDirectory = path
                self.transferState = .none
            }
        } catch {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.errorMessage = "Failed to list files: \(error.localizedDescription)"
                self.transferState = .none
            }
            throw error
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
    func downloadFile(fileName: String) async throws -> Data {
        guard let client, connectionState == .connected else {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.errorMessage = "Not connected to server"
            }
            throw NSError(domain: "SMBClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not connected to server"])
        }
        
        let filePath: String
        if currentDirectory.isEmpty {
            filePath = fileName
        } else {
            filePath = "\(currentDirectory)/\(fileName)"
        }
        
        await MainActor.run { [weak self] in
            guard let self else { return }
            self.transferState = .downloading(fileName)
            self.transferProgress = 0.0
        }
        
        do {
            let data = try await client.download(path: filePath) { [weak self] progress in
                guard let self else { return }
                
                DispatchQueue.main.async {
                    self.transferProgress = progress
                }
            }
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.transferState = .none
                self.transferProgress = 1.0
            }
            
            return data
        } catch {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.errorMessage = "Download failed: \(error.localizedDescription)"
                self.transferState = .none
            }
            throw error
        }
    }
    
    /// Delete a file or directory on the server
    func deleteItem(name: String, isDirectory: Bool) async throws {
        guard let client, connectionState == .connected else {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.errorMessage = "Not connected to server"
            }
            throw NSError(domain: "SMBClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not connected to server"])
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
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.errorMessage = "Failed to delete item: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Create a new directory on the server
    func createDirectory(directoryName: String) async throws {
        guard let client, connectionState == .connected else {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.errorMessage = "Not connected to server"
            }
            throw NSError(domain: "SMBClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not connected to server"])
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
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.errorMessage = "Failed to create directory: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Upload a local file to the server
    func uploadLocalFile(url: URL) async throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "SMBClientError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to access security scoped resource"])
        }
        
        // Ensure we stop accessing when we're done
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let data = try Data(contentsOf: url)
            try await uploadFile(data: data, fileName: url.lastPathComponent)
        } catch {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.errorMessage = "Failed to read local file: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Upload a file to the server
    func uploadFile(data: Data, fileName: String) async throws {
        guard let client, connectionState == .connected else {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.errorMessage = "Not connected to server"
            }
            throw NSError(domain: "SMBClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not connected to server"])
        }
        
        let filePath: String
        if currentDirectory.isEmpty {
            filePath = fileName
        } else {
            filePath = "\(currentDirectory)/\(fileName)"
        }
        
        await MainActor.run { [weak self] in
            guard let self else { return }
            self.transferState = .uploading(fileName)
            self.transferProgress = 0.0
        }
        
        do {
            try await client.upload(content: data, path: filePath) { progress in
                DispatchQueue.main.async {
                    self.transferProgress = progress
                }
            }
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.transferProgress = 1.0
                self.transferState = .none
            }
            
            try await listFiles(currentDirectory)
            
        } catch {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.errorMessage = "Upload failed: \(error.localizedDescription)"
                self.transferState = .none
            }
            throw error
        }
    }
}

// MARK: - Helper Methods
extension FileTransferViewModel {
    func isDirectory(_ file: File) -> Bool {
        file.isDirectory
    }
    
    func formatFileSize(_ size: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}
