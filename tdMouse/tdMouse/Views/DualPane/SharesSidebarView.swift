//
//  SharesSidebarView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI
import SMBClient

struct SharesSidebarView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: FileTransferViewModel
    @Binding var isConnectSheetPresented: Bool
    
    @AppStorage("savedConnections") private var savedConnectionsData: Data = Data()
    @State private var savedConnections: [SavedConnection] = []
    @State private var connectionToEdit: SavedConnection?
    @State private var isEditSheetPresented = false
    @State private var isHovering: String? = nil
    @State private var showDeleteAlert = false
    @State private var connectionToDelete: SavedConnection?
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header with modern styling
            sidebarHeader
            
            // Connection status panel
            connectionStatusPanel
            
            // Main content
            ScrollView {
                VStack(spacing: 16) {
                    // Saved connections section
                    savedConnectionsSection
                    
                    // Available shares section (when connected)
                    if viewModel.connectionState == .connected {
                        availableSharesSection
                    }
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
            
            // Bottom action bar
            actionBar
        }
        .frame(width: 240)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .onAppear(perform: loadSavedConnections)
        .sheet(isPresented: $isEditSheetPresented) {
            if let connection = connectionToEdit {
                EditConnectionView(
                    connection: connection,
                    isPresented: $isEditSheetPresented,
                    onSave: { updatedConnection in
                        updateSavedConnection(updatedConnection)
                    }
                )
            }
        }
        .alert("Delete Connection", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let connection = connectionToDelete {
                    deleteSavedConnection(connection)
                }
            }
        } message: {
            if let connection = connectionToDelete {
                Text("Are you sure you want to delete the connection to '\(connection.displayName)'?")
            } else {
                Text("Are you sure you want to delete this connection?")
            }
        }
    }
    
    // MARK: - UI Components
    
    private var sidebarHeader: some View {
        HStack {
            Label("Connections", systemImage: "network")
                .font(.headline)
            
            Spacer()
            
            Button(action: {
                isConnectSheetPresented = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                    .imageScale(.medium)
            }
            .buttonStyle(.plain)
            .help("Add new connection")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            Color(NSColor.windowBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        )
    }
    
    private var connectionStatusPanel: some View {
        HStack(spacing: 8) {
            // Connection status indicator
            Group {
                switch viewModel.connectionState {
                case .connected:
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                case .connecting:
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 10, height: 10)
                case .error:
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                case .disconnected:
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 10, height: 10)
                }
            }
            .animation(.easeInOut, value: viewModel.connectionState)
            
            // Connection info
            if viewModel.connectionState == .connected {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.credentials.host)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Text(viewModel.credentials.username)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            } else if case .connecting = viewModel.connectionState {
                Text("Connecting...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if case .error = viewModel.connectionState {
                Text("Connection Error")
                    .font(.subheadline)
                    .foregroundColor(.red)
            } else {
                Text("Not connected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            colorScheme == .dark ?
                Color.black.opacity(0.2) :
                Color.white.opacity(0.8)
        )
    }
    
    private var savedConnectionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Text("SAVED CONNECTIONS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
            
            // Connections list
            if savedConnections.isEmpty {
                emptyConnectionsView
            } else {
                ForEach(savedConnections) { connection in
                    connectionRow(connection)
                }
            }
        }
    }
    
    private var emptyConnectionsView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "bookmark.slash")
                    .font(.title)
                    .foregroundColor(.secondary)
                Text("No saved connections")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button("Add Connection") {
                    isConnectSheetPresented = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }
    
    private func connectionRow(_ connection: SavedConnection) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Connection icon
                Image(systemName: "network")
                    .foregroundColor(.accentColor)
                    .frame(width: 24, height: 24)
                
                // Connection details
                VStack(alignment: .leading, spacing: 2) {
                    Text(connection.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("\(connection.username)\(connection.domain.isEmpty ? "" : "@\(connection.domain)")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Action buttons (visible on hover)
                if isHovering == connection.id.uuidString {
                    HStack(spacing: 8) {
                        Button(action: {
                            connectionToEdit = connection
                            isEditSheetPresented = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Edit connection")
                        
                        Button(action: {
                            connectionToDelete = connection
                            showDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Delete connection")
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        isHovering == connection.id.uuidString ?
                            (colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)) :
                            Color.clear
                    )
                    .padding(.horizontal, 4)
            )
            .onTapGesture {
                connectTo(connection)
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering ? connection.id.uuidString : nil
                }
            }
            .contextMenu {
                Button {
                    connectTo(connection)
                } label: {
                    Label("Connect", systemImage: "link")
                }
                
                Button {
                    connectionToEdit = connection
                    isEditSheetPresented = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    connectionToDelete = connection
                    showDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
    
    private var availableSharesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Text("AVAILABLE SHARES")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
            
            if viewModel.availableShares.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Loading shares...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                ForEach(viewModel.availableShares, id: \.self) { share in
                    shareRow(share)
                }
            }
        }
    }
    
    private func shareRow(_ share: String) -> some View {
        HStack(spacing: 12) {
            // Share icon
            Image(systemName: "folder.fill")
                .foregroundColor(viewModel.shareName == share ? .accentColor : .secondary)
                .frame(width: 24, height: 24)
            
            // Share name
            Text(share)
                .font(.subheadline)
                .fontWeight(viewModel.shareName == share ? .semibold : .regular)
                .lineLimit(1)
            
            Spacer()
            
            // Connected indicator
            if viewModel.shareName == share {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(viewModel.shareName == share ?
                    (colorScheme == .dark ? Color.accentColor.opacity(0.2) : Color.accentColor.opacity(0.1)) :
                    Color.clear)
                .padding(.horizontal, 4)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            connectToShare(share)
        }
    }
    
    private var actionBar: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                // Primary action button (Connect/Disconnect)
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
                        Image(systemName: viewModel.connectionState == .connected ? "link.badge.minus" : "link")
                        Text(viewModel.connectionState == .connected ? "Disconnect" : "Connect")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                // Save connection button
                if viewModel.connectionState == .connected {
                    Button(action: {
                        saveCurrentConnection()
                    }) {
                        Image(systemName: "bookmark.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .help("Save current connection")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Helper Methods
    
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
        connectionToDelete = nil
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
    
    private func updateSavedConnection(_ connection: SavedConnection) {
        if let index = savedConnections.firstIndex(where: { $0.id == connection.id }) {
            savedConnections[index] = connection
            saveConnections()
        }
    }
}

// MARK: - Preview
struct SharesSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample view model with connected state
        let connectedViewModel: FileTransferViewModel = {
            let vm = FileTransferViewModel()
            vm.credentials = SMBServerCredentials(
                host: "fileserver.local",
                port: 445,
                username: "admin",
                password: "password",
                domain: "WORKGROUP"
            )
            
            // Mock connected state
            return vm
        }()
        
        Group {
            // Connected state
            SharesSidebarView(
                viewModel: connectedViewModel,
                isConnectSheetPresented: .constant(false)
            )
            .previewDisplayName("Connected (Light)")
            
            // Disconnected state
            SharesSidebarView(
                viewModel: FileTransferViewModel(),
                isConnectSheetPresented: .constant(false)
            )
            .previewDisplayName("Disconnected (Light)")
            .preferredColorScheme(.light)
            
            // Dark mode
            SharesSidebarView(
                viewModel: connectedViewModel,
                isConnectSheetPresented: .constant(false)
            )
            .previewDisplayName("Connected (Dark)")
            .preferredColorScheme(.dark)
        }
        .frame(height: 600)
    }
}
