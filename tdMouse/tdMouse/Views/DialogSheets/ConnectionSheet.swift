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
    
    @State private var showPassword = false
    @State private var connectionName = ""
    @State private var shouldSave = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @AppStorage("savedConnections") private var savedConnectionsData: Data = Data()
    
    private let accentColor = Color.blue
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with modern styling
            HStack {
                Text("Connect to TD Mouse")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 8)
            
            // Form content with improved spacing
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    serverDetailsSection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    credentialsSection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    saveConnectionSection
                }
                .padding(.bottom)
            }
            .frame(maxHeight: .infinity)
            
            // Action buttons with modern styling
            buttonRow
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 450, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear(perform: setupInitialState)
        .alert("Connection Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Extracted View Components
    
    private var serverDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Server Details")
                .font(.headline)
                .foregroundStyle(accentColor)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // Host field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Host")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "network")
                            .foregroundStyle(.secondary)
                        TextField("Enter IP address", text: $viewModel.credentials.host)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled()
                    }
                }
                .padding(.horizontal)
                
                // Port field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Port")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "menubar.dock.rectangle")
                            .foregroundColor(.secondary)
                        
                        TextField("445", value: $viewModel.credentials.port, formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                
            }
        }
    }
    
    private var credentialsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Credentials")
                .font(.headline)
                .foregroundColor(accentColor)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // Username field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Username")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.secondary)
                        
                        TextField("Enter username", text: $viewModel.credentials.username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled()
                    }
                }
                .padding(.horizontal)
                
                // Password field with visibility toggle
                VStack(alignment: .leading, spacing: 4) {
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.secondary)
                        
                        if showPassword {
                            TextField("Enter password", text: $viewModel.credentials.password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            SecureField("Enter password", text: $viewModel.credentials.password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help(showPassword ? "Hide password" : "Show password")
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var saveConnectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Save Connection")
                .font(.headline)
                .foregroundColor(accentColor)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Save connection for future use", isOn: $shouldSave)
                    .toggleStyle(.switch)
                    .padding(.horizontal)
                
                if shouldSave {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connection Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(.secondary)
                            
                            TextField("Enter a name for this connection", text: $connectionName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                    
                    Text("Note: Password will not be saved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: shouldSave)
        }
    }
    
    private var buttonRow: some View {
        HStack {
            Button("Cancel") {
                isPresented = false
            }
            .keyboardShortcut(.cancelAction)
            .buttonStyle(.bordered)
            
            Spacer()
            
            if viewModel.connectionState == .connected {
                Button(action: {
                    Task {
                        await disconnectFromServer()
                    }
                }) {
                    Label("Disconnect", systemImage: "link.circle")
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            
            Button(action: {
                Task {
                    await connectToServer()
                }
            }) {
                Label(
                    viewModel.connectionState == .connected ? "Reconnect" : "Connect",
                    systemImage: viewModel.connectionState == .connected ? "arrow.triangle.2.circlepath" : "link"
                )
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isCredentialsValid)
            .keyboardShortcut(.defaultAction)
        }
    }
}

// MARK: - Methods
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
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
            print("Connection error: \(error.localizedDescription)")
        }
    }
    
    private func disconnectFromServer() async {
        do {
            try await viewModel.disconnect()
            await MainActor.run {
                isPresented = false
            }
        } catch {
            await MainActor.run {
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

struct ConnectionSheet_Preview: PreviewProvider {
    static var previews: some View {
        ConnectionSheet(
            viewModel: FileTransferViewModel(),
            isPresented: .constant(true)
        )
    }
}
