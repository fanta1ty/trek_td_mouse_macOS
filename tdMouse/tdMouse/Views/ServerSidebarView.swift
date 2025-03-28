//
//  SidebarView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI

struct ServerSidebarView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: FileTransferViewModel
    @State private var isConnectSheetPresented = false
    @State private var searchText = ""
    @State private var hoveredShare: String? = nil
    
    // Filtered shares based on search
    private var filteredShares: [String] {
        if searchText.isEmpty {
            return viewModel.availableShares
        } else {
            return viewModel.availableShares.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Server connection status and action header
            serverConnectionHeader
            
            // Search field (when connected)
            if viewModel.connectionState == .connected && !viewModel.availableShares.isEmpty {
                searchField
            }
            
            // Main content list
            List {
                if viewModel.connectionState == .connected {
                    // Recent connections section (optional)
                    recentConnectionsSection
                    
                    // Available shares section
                    sharesSection
                    
                    // Shortcuts section
                    shortcutsSection
                } else {
                    // Display a placeholder when not connected
                    notConnectedPlaceholder
                }
            }
            .listStyle(SidebarListStyle())
            
            // Bottom toolbar with common actions
            actionToolbar
        }
        .frame(minWidth: 200)
        .sheet(isPresented: $isConnectSheetPresented) {
            ConnectionSheet(viewModel: viewModel, isPresented: $isConnectSheetPresented)
        }
    }
    
    // MARK: - View Components
    
    private var serverConnectionHeader: some View {
        HStack {
            // Status indicator dot
            Circle()
                .fill(viewModel.connectionState == .connected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            // Current connection info
            if viewModel.connectionState == .connected {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.credentials.host)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text(viewModel.credentials.username)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !viewModel.credentials.domain.isEmpty {
                            Text("@\(viewModel.credentials.domain)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("Not Connected")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Connection action button
            Button(action: {
                if viewModel.connectionState == .connected {
                    Task {
                        try await viewModel.disconnect()
                    }
                } else {
                    isConnectSheetPresented = true
                }
            }) {
                Image(systemName: viewModel.connectionState == .connected ? "xmark.circle" : "plus.circle")
                    .font(.system(size: 16))
                    .foregroundColor(viewModel.connectionState == .connected ? .red : .accentColor)
            }
            .buttonStyle(.plain)
            .help(viewModel.connectionState == .connected ? "Disconnect" : "Connect to server")
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search shares", text: $searchText)
                .textFieldStyle(.plain)
                .font(.subheadline)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(NSColor.textBackgroundColor).opacity(0.5))
    }
    
    private var recentConnectionsSection: some View {
        Section(header: Text("Recent")) {
            // We could store and display recently used shares here
            // For now showing the current share if it's active
            if !viewModel.shareName.isEmpty {
                shareRowView(
                    name: viewModel.shareName,
                    systemImage: "clock.arrow.circlepath",
                    isActive: true
                )
            }
        }
    }
    
    private var sharesSection: some View {
        Section(header: Text("Shares")) {
            if filteredShares.isEmpty && !searchText.isEmpty {
                Text("No matching shares found")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 5)
            } else if filteredShares.isEmpty {
                Text("No shares available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 5)
            } else {
                ForEach(filteredShares, id: \.self) { share in
                    shareRowView(
                        name: share,
                        systemImage: "folder",
                        isActive: viewModel.shareName == share
                    )
                    .contextMenu {
                        shareContextMenu(share: share)
                    }
                }
            }
        }
    }
    
    private var shortcutsSection: some View {
        Section(header: Text("Actions")) {
            Button(action: {
                // Show connection details
                isConnectSheetPresented = true
            }) {
                Label("Connection Settings", systemImage: "gearshape")
            }
            .buttonStyle(.plain)
        }
    }
    
    private var notConnectedPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "network.slash")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
            
            Text("Not connected to any server")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Connect") {
                isConnectSheetPresented = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .listRowBackground(Color.clear)
    }
    
    private var actionToolbar: some View {
        HStack(spacing: 16) {
            Button(action: {
                isConnectSheetPresented = true
            }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .help("Connect to server")
            
            Spacer()
            
            Button(action: {
                // Toggle sidebar collapse in parent view
                NotificationCenter.default.post(
                    name: Notification.Name("ToggleSidebar"),
                    object: nil
                )
            }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .help("Toggle sidebar")
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Helper Functions
    
    private func shareRowView(name: String, systemImage: String, isActive: Bool) -> some View {
        Button(action: {
            Task {
                try await viewModel.connectToShare(name)
            }
        }) {
            HStack {
                // Share icon with selected state
                ZStack {
                    Image(systemName: systemImage)
                        .foregroundColor(isActive ? .accentColor : .primary)
                    
                    if isActive {
                        // Optional background for selected item
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: 22, height: 22)
                    }
                }
                
                // Share name
                Text(name)
                    .foregroundColor(isActive ? .accentColor : .primary)
                
                Spacer()
                
                // Active indicator
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .background(
            hoveredShare == name && !isActive ?
                Color.gray.opacity(0.1) : Color.clear
        )
        .cornerRadius(4)
        .onHover { isHovered in
            hoveredShare = isHovered ? name : nil
        }
    }
    
    @ViewBuilder
    private func shareContextMenu(share: String) -> some View {
        Button(action: {
            Task {
                try await viewModel.connectToShare(share)
            }
        }) {
            Label("Connect", systemImage: "link")
        }
        
        Button(action: {
            // Copy share path to clipboard
            let fullPath = "\\\\\(viewModel.credentials.host)\\\(share)"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(fullPath, forType: .string)
        }) {
            Label("Copy Share Path", systemImage: "doc.on.doc")
        }
        
        if share == viewModel.shareName {
            Button(action: {
                Task {
                    try await viewModel.navigateToDirectory("")
                }
            }) {
                Label("Go to Root Directory", systemImage: "folder.fill")
            }
        }
    }
}

// MARK: - Preview

struct ServerSidebarView_Previews: PreviewProvider {
    static var mockViewModel: FileTransferViewModel = {
        let vm = FileTransferViewModel()
        // Configure for preview
        return vm
    }()
    
    static var previews: some View {
        Group {
            // Disconnected state
            ServerSidebarView(viewModel: FileTransferViewModel())
                .frame(width: 240, height: 400)
                .previewDisplayName("Disconnected")
            
            // Connected state with shares
            ServerSidebarView(viewModel: mockViewModel)
                .frame(width: 240, height: 400)
                .previewDisplayName("Connected")
        }
    }
}
