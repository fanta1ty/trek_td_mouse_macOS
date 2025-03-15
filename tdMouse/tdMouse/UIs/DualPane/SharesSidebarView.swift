//
//  SharesSidebarView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI
import SMBClient

struct SharesSidebarView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @Binding var isConnectSheetPresented: Bool
    
    @AppStorage("savedConnections") private var savedConnectionsData: Data = Data()
    @State private var savedConnections: [SavedConnection] = []
    
    struct SavedConnection: Identifiable, Codable {
        var id = UUID()
        var name: String
        var host: String
        var port: UInt16
        var username: String
        var domain: String
        
        var displayName: String {
            return name.isEmpty ? host : name
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Connections")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    isConnectSheetPresented = true
                }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Add new connection")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Connection status
            HStack {
                if viewModel.connectionState == .connected {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text(viewModel.credentials.host)
                        .font(.subheadline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else if case .connecting = viewModel.connectionState {
                    ProgressView()
                        .scaleEffect(0.5)
                    Text("Connecting...")
                        .font(.subheadline)
                } else if case .error(let message) = viewModel.connectionState {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("Error")
                        .font(.subheadline)
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                    Text("Not connected")
                        .font(.subheadline)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            // Saved connections list
            List {
                Section("Saved Connections") {
                    ForEach(savedConnections) { connection in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(connection.displayName)
                                    .fontWeight(.medium)
                                Text(connection.username + (connection.domain.isEmpty ? "" : "@\(connection.domain)"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                connectTo(connection)
                            }) {
                                Text("Connect")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .contextMenu {
                            Button("Connect") {
                                connectTo(connection)
                            }
                            Button("Edit") {
                                // Edit connection (for future implementation)
                            }
                            Divider()
                            Button("Delete") {
                                deleteSavedConnection(connection)
                            }
                        }
                    }
                    
                    if savedConnections.isEmpty {
                        Text("No saved connections")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }
                
                if viewModel.connectionState == .connected {
                    Section("Available Shares") {
                        ForEach(viewModel.availableShares, id: \.self) { share in
                            Button(action: {
                                connectToShare(share)
                            }) {
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundColor(.accentColor)
                                    Text(share)
                                    
                                    Spacer()
                                    
                                    if viewModel.shareName == share {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Bottom action buttons
            HStack {
                Button(action: {
                    if viewModel.connectionState == .connected {
                        Task {
                            try await viewModel.disconnect()
                        }
                    } else {
                        isConnectSheetPresented = true
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.connectionState == .connected ? "network.slash" : "network")
                        Text(viewModel.connectionState == .connected ? "Disconnect" : "Connect")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Spacer()
                
                Button(action: {
                    if viewModel.connectionState == .connected {
                        saveCurrentConnection()
                    }
                }) {
                    Image(systemName: "bookmark")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.connectionState != .connected)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 240)
        .onAppear(perform: loadSavedConnections)
    }
    
    private func connectTo(_ connection: SavedConnection) {
        // Create credentials from saved connection
        let credentials = SMBServerCredentials(
            host: connection.host,
            port: Int(connection.port),
            username: connection.username,
            password: "", // Password not saved for security
            domain: connection.domain
        )
        
        // Set credentials and connect
        viewModel.credentials = credentials
        
        // Show connection sheet since we don't store passwords
        isConnectSheetPresented = true
    }
    
    private func connectToShare(_ shareName: String) {
        Task {
            try await viewModel.connectToShare(shareName)
        }
    }
    
    private func saveCurrentConnection() {
        let creds = viewModel.credentials
        let newConnection = SavedConnection(
            name: creds.host,
            host: creds.host,
            port: UInt16(creds.port),
            username: creds.username,
            domain: creds.domain
        )
        
        // Avoid duplicates
        if !savedConnections.contains(where: { $0.host == newConnection.host && $0.username == newConnection.username }) {
            savedConnections.append(newConnection)
            saveConnections()
        }
    }
    
    private func deleteSavedConnection(_ connection: SavedConnection) {
        savedConnections.removeAll { $0.id == connection.id }
        saveConnections()
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
    
    private func saveConnections() {
        do {
            let encoder = JSONEncoder()
            savedConnectionsData = try encoder.encode(savedConnections)
        } catch {
            print("Failed to save connections: \(error)")
        }
    }
}
