//
//  ConnectionSheet.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI

import SwiftUI

struct ConnectionSheet: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @Binding var isPresented: Bool
    @State private var showPassword = false
    @State private var connectionName = ""
    @State private var shouldSave = false
    
    var body: some View {
        VStack {
            Text("Connect to SMB Server")
                .font(.headline)
                .padding()
            
            Form {
                Section("Server Details") {
                    TextField("Host", text: $viewModel.credentials.host)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        Text("Port:")
                        TextField("Port", value: $viewModel.credentials.port, formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    TextField("Domain (optional)", text: $viewModel.credentials.domain)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("Credentials") {
                    TextField("Username", text: $viewModel.credentials.username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        if showPassword {
                            TextField("Password", text: $viewModel.credentials.password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            SecureField("Password", text: $viewModel.credentials.password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                Section("Save Connection") {
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
            .padding()
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                if viewModel.connectionState == .connected {
                    Button("Disconnect") {
                        Task {
                            try await viewModel.disconnect()
                            isPresented = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                
                Button(viewModel.connectionState == .connected ? "Reconnect" : "Connect") {
                    Task {
                        if viewModel.connectionState == .connected {
                            try await viewModel.disconnect()
                        }
                        
                        // Save the connection if requested
                        if shouldSave {
                            saveConnection()
                        }
                        
                        try await viewModel.connect()
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isCredentialsValid)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 450)
        .onAppear {
            // Pre-fill the connection name with host if empty
            if connectionName.isEmpty && !viewModel.credentials.host.isEmpty {
                connectionName = viewModel.credentials.host
            }
        }
    }
    
    private func saveConnection() {
        // Get the AppStorage from UserDefaults
        if let savedConnectionsData = UserDefaults.standard.data(forKey: "savedConnections") {
            do {
                let decoder = JSONDecoder()
                var savedConnections = try decoder.decode([SharesSidebarView.SavedConnection].self, from: savedConnectionsData)
                
                // Create a new connection object
                let newConnection = SharesSidebarView.SavedConnection(
                    name: connectionName.isEmpty ? viewModel.credentials.host : connectionName,
                    host: viewModel.credentials.host,
                    port: UInt16(viewModel.credentials.port),
                    username: viewModel.credentials.username,
                    domain: viewModel.credentials.domain
                )
                
                // Add it if it doesn't already exist
                if !savedConnections.contains(where: { $0.host == newConnection.host && $0.username == newConnection.username }) {
                    savedConnections.append(newConnection)
                    
                    // Save back to UserDefaults
                    let encoder = JSONEncoder()
                    if let encodedData = try? encoder.encode(savedConnections) {
                        UserDefaults.standard.set(encodedData, forKey: "savedConnections")
                    }
                }
            } catch {
                print("Failed to save connection: \(error)")
            }
        } else {
            // No existing connections, create a new array
            let newConnection = SharesSidebarView.SavedConnection(
                name: connectionName.isEmpty ? viewModel.credentials.host : connectionName,
                host: viewModel.credentials.host,
                port: UInt16(viewModel.credentials.port),
                username: viewModel.credentials.username,
                domain: viewModel.credentials.domain
            )
            
            let connections = [newConnection]
            let encoder = JSONEncoder()
            if let encodedData = try? encoder.encode(connections) {
                UserDefaults.standard.set(encodedData, forKey: "savedConnections")
            }
        }
    }
}

struct ConnectionSheet_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionSheet(
            viewModel: FileTransferViewModel(),
            isPresented: .constant(true)
        )
    }
}
