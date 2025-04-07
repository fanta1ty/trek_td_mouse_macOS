//
//  ConnectionSheetView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 31/3/25.
//

import SwiftUI
import SMBClient

struct ConnectionSheetView: View {
    enum ConnectionState {
        case credentials
        case shareSelection
    }
    
    @EnvironmentObject var viewModel: FileTransferViewModel
    @Binding var isPresented: Bool
    
    @State private var showPassword: Bool = false
    @State private var shouldSave: Bool = false
    @State private var isConnecting: Bool = false
    @State private var showingError: Bool = false
    
    @State private var connectionName: String = ""
    @State private var selectedShare: String = ""
    @State private var errorMessage: String = ""
    @State private var connectionStage: ConnectionState = .credentials
    @State private var savedConnections: [SavedConnection] = []
    
    @AppStorage("savedConnections") private var savedConnectionsData: Data = Data()
    
    @ViewBuilder private var content: some View {
        switch connectionStage {
        case .credentials:
            CredentialsForm(
                isConnecting: $isConnecting,
                shouldSave: $shouldSave,
                connectionName: $connectionName,
                savedConnections: $savedConnections,
                onDisconnect: {
                    Task { await disconnectFromServer() }
                }
            )
                
        case .shareSelection:
            ShareSelectionView(
                selectedShare: $selectedShare,
                onConnectToSelectedShare: connectToSelectedShare
            )
        }
    }
    
    private var navigationTitle: String {
        switch connectionStage {
        case .credentials:
            return viewModel.connectionState == .connected ? "Connected" : "Connect to Server"
        case .shareSelection:
            return "Select Share"
        }
    }
    
    var body: some View {
        content
            .navigationTitle(navigationTitle)
            .onAppear(perform: setupInitialState)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    switch connectionStage {
                    case .credentials:
                        Button("Connect") {
                            Task {
                                await connectToServer()
                            }
                        }
                        .disabled(!viewModel.isCredentialsValid || isConnecting)
                        
                    case .shareSelection:
                        Button("Done") {
                            connectToSelectedShare()
                        }
                        .disabled(selectedShare.isEmpty)
                    }
                }
            }
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text("Connection Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
    }
}

extension ConnectionSheetView {
    private func setupInitialState() {
        connectionStage = .credentials
        
        if connectionName.isEmpty && !viewModel.credentials.host.isEmpty {
            connectionName = viewModel.currentDirectory
        }
        
        // Load saved connections
        loadSavedConnections()
    }
    
    private func loadSavedConnections() {
        do {
            let decoder = JSONDecoder()
            if !savedConnectionsData.isEmpty {
                savedConnections = try decoder.decode([SavedConnection].self, from: savedConnectionsData)
            }
        } catch {
            print("Failed to load saved connections: \(error)")
        }
    }
    
    private func connectToServer() async {
        if viewModel.connectionState == .connected {
            await disconnectFromServer()
        }
        
        // Save the connection if requested
        if shouldSave {
            saveConnection()
        }
        
        isConnecting = true
        
        do {
            try await viewModel.connect()
            
            // Once connected, fetch available shares
            try await viewModel.fetchShares()
            
            await MainActor.run {
                isConnecting = false
                
                // Proceed to share selection stage instead of dismissing
                connectionStage = .shareSelection
            }
        } catch {
            await MainActor.run {
                isConnecting = false
                errorMessage = error.localizedDescription
                showingError = true
            }
            print("Connection error: \(error.localizedDescription)")
        }
    }
    
    private func disconnectFromServer() async {
        isConnecting = true
        
        do {
            try await viewModel.disconnect()
            await MainActor.run {
                isConnecting = false
                isPresented = false
            }
        } catch {
            await MainActor.run {
                isConnecting = false
                errorMessage = error.localizedDescription
                showingError = true
            }
            print("Disconnection error: \(error.localizedDescription)")
        }
    }
    
    private func saveConnection() {
        do {
            // Decode existing connections
            var savedConnections: [SavedConnection] = []
            if !savedConnectionsData.isEmpty {
                savedConnections = try JSONDecoder().decode([SavedConnection].self, from: savedConnectionsData)
            }
            
            // Create a new connection object
            let newConnection = SavedConnection(
                name: connectionName.isEmpty ? viewModel.credentials.host : connectionName,
                host: viewModel.credentials.host,
                port: UInt16(viewModel.credentials.port),
                username: viewModel.credentials.username,
                domain: viewModel.credentials.domain
            )
            
            // Add it if it doesn't already exist
            if !savedConnections.contains(where: { $0.host == newConnection.host && $0.username == newConnection.username }) {
                savedConnections.append(newConnection)
                
                // Save back to AppStorage
                savedConnectionsData = try JSONEncoder().encode(savedConnections)
            }
        } catch {
            print("Failed to save connection: \(error)")
        }
    }
    
    private func connectToSelectedShare() {
        guard !selectedShare.isEmpty else { return }
        
        Task {
            isConnecting = true
            
            do {
                try await viewModel.connectToShare(selectedShare)
                
                await MainActor.run {
                    isConnecting = false
                    isPresented = false // Now dismiss the sheet after share is selected
                }
            } catch {
                await MainActor.run {
                    isConnecting = false
                    errorMessage = "Failed to connect to share: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

struct ConnectionSheetView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionSheetView(
            isPresented: .constant(true)
        )
        .environmentObject(FileTransferViewModel())
        .environmentObject(LocalViewModel())
    }
}
