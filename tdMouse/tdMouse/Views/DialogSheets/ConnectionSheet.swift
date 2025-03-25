//
//  ConnectionSheet.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI

struct ConnectionSheet: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @Binding var isPresented: Bool
    
    // State declarations grouped together
    @State private var showPassword = false
    @State private var connectionName = ""
    @State private var shouldSave = false
    
    // Use AppStorage to directly access saved connections without manual encode/decode
    @AppStorage("savedConnections") private var savedConnectionsData: Data = Data()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Connect to SMB Server")
                .font(.headline)
                .padding()
            
            // Form content
            Form {
                serverDetailsSection
                credentialsSection
                saveConnectionSection
            }
            .padding([.horizontal, .top])
            
            // Action buttons
            buttonRow
                .padding()
        }
        .frame(width: 450)
        .onAppear(perform: setupInitialState)
    }
    
    // MARK: - Extracted View Components
    
    private var serverDetailsSection: some View {
        Section(header: Text("Server Details")) {
            TextField("Host", text: $viewModel.credentials.host)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled()
            
            HStack {
                Text("Port:")
                TextField("Port", value: $viewModel.credentials.port, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
            }
            
            TextField("Domain (optional)", text: $viewModel.credentials.domain)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled()
        }
    }
    
    private var credentialsSection: some View {
        Section(header: Text("Credentials")) {
            TextField("Username", text: $viewModel.credentials.username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled()
            
            HStack {
                Group {
                        if showPassword {
                            TextField("Password", text: $viewModel.credentials.password)
                                .textContentType(.password)
                        } else {
                            SecureField("Password", text: $viewModel.credentials.password)
                        }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
    }
    
    private var saveConnectionSection: some View {
        Section(header: Text("Save Connection")) {
            TextField("Connection Name (optional)", text: $connectionName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(!shouldSave)
            
            Toggle("Save connection for future use", isOn: $shouldSave)
                .toggleStyle(.switch)
            
            if shouldSave {
                Text("Note: Password will not be saved")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var buttonRow: some View {
        HStack {
            Button("Cancel") {
                isPresented = false
            }
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            if viewModel.connectionState == .connected {
                Button("Disconnect") {
                    Task {
                        await disconnectFromServer()
                    }
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            
            Button(viewModel.connectionState == .connected ? "Reconnect" : "Connect") {
                Task {
                    await connectToServer()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isCredentialsValid)
            .keyboardShortcut(.defaultAction)
        }
    }
    
    // MARK: - Methods
    
    private func setupInitialState() {
        // Pre-fill the connection name with host if empty
        if connectionName.isEmpty && !viewModel.credentials.host.isEmpty {
            connectionName = viewModel.credentials.host
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
        
        do {
            try await viewModel.connect()
            await MainActor.run {
                isPresented = false
            }
        } catch {
            print("Connection error: \(error.localizedDescription)")
            // Handle connection error if needed
        }
    }
    
    private func disconnectFromServer() async {
        do {
            try await viewModel.disconnect()
            await MainActor.run {
                isPresented = false
            }
        } catch {
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
            
            // Add it if it doesn't already exist (using a more efficient check)
            if !savedConnections.contains(where: { $0.host == newConnection.host && $0.username == newConnection.username }) {
                savedConnections.append(newConnection)
                
                // Save back to AppStorage
                savedConnectionsData = try JSONEncoder().encode(savedConnections)
            }
        } catch {
            print("Failed to save connection: \(error)")
        }
    }
}

// MARK: - Preview
struct ConnectionSheet_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionSheet(
            viewModel: FileTransferViewModel(),
            isPresented: .constant(true)
        )
    }
}
