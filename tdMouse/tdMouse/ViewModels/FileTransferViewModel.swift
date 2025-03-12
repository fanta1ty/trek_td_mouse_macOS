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
}
