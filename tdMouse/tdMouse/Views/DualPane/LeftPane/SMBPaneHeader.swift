//
//  SMBPaneHeader.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 28/3/25.
//

import SwiftUI
import SMBClient

struct SMBPaneHeader: View {
    @ObservedObject var viewModel: FileTransferViewModel
    
    var body: some View {
        HStack {
            // Connection status indicator
            Circle()
                .fill(viewModel.connectionState == .connected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            // Connected server info
            Text(viewModel.connectionState == .connected ? "SMB: \(viewModel.credentials.host)" : "SMB Server")
                .font(.headline)
            
            Spacer()
            
            if viewModel.connectionState == .connected {
                // Up button
                Button(action: {
                    Task {
                        try await viewModel.navigateUp()
                    }
                }) {
                    Image(systemName: "arrow.up")
                        .foregroundColor(viewModel.currentDirectory.isEmpty ? .gray : .blue)
                }
                .disabled(viewModel.currentDirectory.isEmpty)
                .buttonStyle(.plain)
                .help("Navigate Up")
                
                // Refresh button
                Button(action: {
                    Task {
                        try await viewModel.refreshCurrentDirectory()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help("Refresh")
                
                // Spacer to separate button groups
                Spacer()
                    .frame(width: 8)
                
                // Connect button
                Button(action: {
                    NotificationCenter.default.post(name: Notification.Name("OpenSMBConnect"), object: nil)
                }) {
                    Label("Connect", systemImage: "link")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Color(NSColor.controlBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        )
    }
}
