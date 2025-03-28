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
    
    @State private var showPassword: Bool = false
    @State private var connectionName: String = ""
    @State private var shouldSave: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    
    @AppStorage("savedConnections") private var savedConnectionsData: Data = Data()
    
    var body: some View {
        NavigationView {
            Form {
                // Server Details Section
                Section(header: Text("Server Details")) {
                    TextField("Host", text: $viewModel.credentials.host)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    HStack {
                        Text("Port:")
                        TextField("445", value: $viewModel.credentials.port, format: .number)
                            .keyboardType(.numberPad)
                    }
                    
                    TextField("Domain (optional)", text: $viewModel.credentials.domain)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                // Credentials Section
                Section(header: Text("Credentials")) {
                    TextField("Username", text: $viewModel.credentials.username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .textContentType(.username)
                    
                    HStack {
                        if showPassword {
                            TextField("Password", text: $viewModel.credentials.password)
                                .textContentType(.password)
                        } else {
                            SecureField("Password", text: $viewModel.credentials.password)
                                .textContentType(.password)
                        }
                        
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Save Connection Section
                Section(header: Text("Save Connection")) {
                    Toggle("Save connection for future use", isOn: $shouldSave)
                    
                    if shouldSave {
                        TextField("Connection Name", text: $connectionName)
                            .autocapitalization(.words)
                        
                        Text("Note: Password will not be saved")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Saved Connection Section
                let savedConnections = getSavedConnections()
                if !savedConnections.isEmpty {
                    Section(header: Text("Saved Connections")) {
                        ForEach(savedConnections, id: \.id) { connection in
                            Button {
                                loadSavedConnection(connection)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(connection.name)
                                            .fontWeight(.medium)
                                        Text("\(connection.username)@\(connection.host)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.forward.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                            .buttonStyle(PlainListStyle())
                        }
                        .onDelete(perform: deleteSavedConnection)
                    }
                }
            }
            .navigationTitle("Connect To TD Mouse")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(viewModel.connectionState == .connected ? "Reconnect" : "Connect") {
                        Task {
                            await connectToServer()
                        }
                    }
                    .disabled(!viewModel.isCredentialsValid)
                }
            }
            .onAppear {
                
            }
            .alert("Connection Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            
        }
    }
}

// MARK: - Private Functions
extension ConnectionSheet {
    private func connectToServer() async {
        if viewModel.connectionState == .connected {
            await disconnectFromServer()
        }
        
        // Save the connection if required
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
            return try JSONDecoder().decode(
                [SavedConnection].self,
                from: savedConnectionsData
            )
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
}

struct ConnectionSheet_Preview: PreviewProvider {
    static var previews: some View {
        ConnectionSheet(
            viewModel: FileTransferViewModel(),
            isPresented: .constant(true)
        )
    }
}
