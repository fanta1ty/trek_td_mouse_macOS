//
//  ConnectionSheet.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI

struct ConnectionSheet: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @Binding var isPresented: Bool
    
    // State declarations
    @State private var showPassword = false
    @State private var connectionName = ""
    @State private var shouldSave = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isConnecting = false
    @State private var isConnected = false
    @State private var availableShares: [String] = []
    @State private var selectedShare: String = ""
    
    @AppStorage("savedConnections") private var savedConnectionsData: Data = Data()
    
    var body: some View {
        NavigationView {
            Form {
                // Server Details Section
                ServerDetailsSection(viewModel: viewModel)
                
                // Credentials Section
                CredentialsSection(
                    viewModel: viewModel,
                    showPassword: $showPassword
                )
                
                // Shares Section (only shown after connecting)
                if isConnected {
                    SharesSection(
                        shares: availableShares,
                        selectedShare: $selectedShare
                    )
                }
                
                // Save Connection Section
                SaveConnectionSection(
                    connectionName: $connectionName,
                    shouldSave: $shouldSave
                )
                
                // Saved Connections Section
                SavedConnectionsSection(
                    savedConnectionsData: savedConnectionsData,
                    savedConnections: getSavedConnections(),
                    onLoadConnection: loadSavedConnection,
                    onDeleteConnection: deleteSavedConnection
                )
            }
            .navigationTitle("Connect To TD Mouse")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if !isConnected {
                        Button(viewModel.connectionState == .connected ? "Reconnect" : "Connect") {
                            Task {
                                await connectToServer()
                            }
                        }
                        .disabled(!viewModel.isCredentialsValid)
                        .font(.system(size: 16, weight: .bold))
                    } else {
                        // Browse button (only after connecting)
                        Button("Browse") {
                            if !selectedShare.isEmpty {
                                Task {
                                    await selectShareAndDismiss()
                                }
                            }
                        }
                        .disabled(selectedShare.isEmpty)
                        .font(.system(size: 16, weight: .bold))
                    }
                    
                }
            }
            .onAppear(perform: setupInitialState)
            .alert("Connection Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {
                    Task {
                        await MainActor.run {
                            errorMessage = ""
                            showingError = false
                        }
                    }
                }
            } message: {
                Text(errorMessage)
            }
            .disabled(isConnecting)
            .overlay(
                Group {
                    if isConnecting {
                        ProgressView("Connecting...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }
                }
            )
        }
    }
}

// MARK: - Private Functions
extension ConnectionSheet {
    private func setupInitialState() {
        if connectionName.isEmpty && !viewModel.credentials.host.isEmpty {
            connectionName = viewModel.credentials.host
        }
    }
    
    private func connectToServer() async {
        if viewModel.connectionState == .connected {
            await disconnectFromServer()
        }
        
        // Save the connection if required
        if shouldSave {
            saveConnection()
        }
        
        await MainActor.run {
            isConnecting = true
        }
        
        do {
            try await viewModel.connect()
            
            await fetchShares()
            
            await MainActor.run {
                isConnecting = false
                isConnected = true
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
    
    private func fetchShares() async {
        do {
            try await viewModel.fetchShares()
            
            await MainActor.run {
                availableShares = viewModel.availableShares
                if !viewModel.availableShares.isEmpty {
                    selectedShare = viewModel.availableShares[0]
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch shares: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private func disconnectFromServer() async {
        do {
            try await viewModel.disconnect()
            await MainActor.run {
                isConnected = false
                availableShares = []
                selectedShare = ""
            }
        } catch {
            await MainActor.run {
                errorMessage = "Disconnection error: \(error.localizedDescription)"
                showingError = true
            }
            print("Disconnection error: \(error.localizedDescription)")
        }
    }
    
    private func deleteSavedConnection(at offsets: IndexSet) {
        do {
            var savedConnections = getSavedConnections()
            savedConnections.remove(atOffsets: offsets)
            savedConnectionsData = try JSONEncoder().encode(savedConnections)
        } catch {
            print("Failed to delete saved connection: \(error)")
        }
    }
    
    private func saveConnection() {
        do {
            // Decode existing connections
            var savedConnections: [SavedConnection] = []
            
            if !savedConnectionsData.isEmpty {
                savedConnections = try JSONDecoder().decode(
                    [SavedConnection].self,
                    from: savedConnectionsData
                )
            }
            
            // Create a new connection object
            let newConnection = SavedConnection(
                name: connectionName.isEmpty ? viewModel.credentials.host : connectionName,
                host: viewModel.credentials.host,
                port: UInt16(viewModel.credentials.host) ?? 445,
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
    
    private func getSavedConnections() -> [SavedConnection] {
        guard !savedConnectionsData.isEmpty else { return [] }
        
        do {
            return try JSONDecoder().decode([SavedConnection].self, from: savedConnectionsData)
        } catch {
            print("Failed to decode saved connections: \(error)")
            return []
        }
    }
    
    private func loadSavedConnection(_ connection: SavedConnection) {
        viewModel.credentials.host = connection.host
        viewModel.credentials.port = Int(connection.port)
        viewModel.credentials.username = connection.username
        viewModel.credentials.domain = connection.domain
        
        // Clear the password field as passwords are not saved
        viewModel.credentials.password = ""
    }
    
    private func selectShareAndDismiss() async {
        do {
            try await viewModel.connectToShare(selectedShare)
            await MainActor.run {
                isPresented = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to select share: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

struct ConnectionSheet_Preview: PreviewProvider {
    static var previews: some View {
        ConnectionSheet(
            viewModel: FileTransferViewModel(),
            isPresented: .constant(true)
        )
    }
}
