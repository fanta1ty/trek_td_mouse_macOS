//
//  FileTransferViewModel.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 12/3/25.
//

import Combine
import SMBClient
import Foundation

/// Main view model for SMB file transfers
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
    
    // Published properties for transfer stats
    @Published var lastTransferStats: TransferStats?
    @Published var showTransferSummary: Bool = false
    
    // MARK: - Private Properties
    var client: SMBClient?
    var cancellables = Set<AnyCancellable>()
    
    // Private properties for tracking transfer progress
    var transferStartTime: Date?
    var speedSamples: [Double] = []
    var speedSamplingTimer: Timer?
    var lastTransferredBytes: UInt64 = 0
    var currentTransferredBytes: UInt64 = 0
    var currentFileName: String = ""
    var currentTransferType: TransferStats.TransferType = .download
    
    // MARK: - Initialization
    
    init(credentials: SMBServerCredentials? = nil) {
        self.credentials = credentials ?? SMBServerCredentials.sample3
        
        $credentials
            .map { credential in
                !credential.host.isEmpty &&
                !credential.username.isEmpty
            }
            .assign(to: &$isCredentialsValid)
    }
    
    // MARK: - Path Utilities
    
    /// Constructs a full path for an item in the current directory
    func pathForItem(_ itemName: String) -> String {
        if currentDirectory.isEmpty {
            return itemName
        } else {
            return "\(currentDirectory)/\(itemName)"
        }
    }
    
    /// Updates UI state on the main thread
    @MainActor
    private func updateUIState(
        errorMessage: String? = nil,
        transferState: TransferOperation? = nil,
        connectionState: ConnectionState? = nil
    ) {
        if let errorMessage = errorMessage {
            self.errorMessage = errorMessage
        }
        
        if let transferState = transferState {
            self.transferState = transferState
        }
        
        if let connectionState = connectionState {
            self.connectionState = connectionState
        }
    }
}
