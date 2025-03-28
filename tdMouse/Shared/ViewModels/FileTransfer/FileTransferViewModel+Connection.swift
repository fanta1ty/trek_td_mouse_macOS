//
//  FileTransferViewModel+Connection.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 25/3/25.
//

import Foundation
import SMBClient

// MARK: - Connection Methods
extension FileTransferViewModel {
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
}
