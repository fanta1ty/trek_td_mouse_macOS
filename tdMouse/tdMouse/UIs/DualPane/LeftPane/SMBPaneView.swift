//
//  SMBPaneView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI
import SMBClient
import UniformTypeIdentifiers

struct SMBPaneView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    let onFileTap: (File) -> Void
    let onLocalFileDrop: (NSItemProvider) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(viewModel.connectionState == .connected ? "SMB: \(viewModel.credentials.host)" : "SMB Server")
                    .font(.headline)
                    .padding(.leading)
                
                Spacer()
                
                if viewModel.connectionState == .connected {
                    Button(action: {
                        Task {
                            try await viewModel.navigateUp()
                        }
                    }) {
                        Image(systemName: "arrow.up")
                    }
                    .disabled(viewModel.currentDirectory.isEmpty)
                    .padding(.trailing)
                }
            }
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            if viewModel.connectionState == .connected {
                // Path bar
                HStack {
                    Text(viewModel.shareName + (viewModel.currentDirectory.isEmpty ? "" : "/" + viewModel.currentDirectory))
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .font(.caption)
                        .padding(.horizontal)
                }
                .frame(height: 24)
                .background(Color(NSColor.textBackgroundColor))
                
                // File list
                List {
                    ForEach(viewModel.files, id: \.name) { file in
                        SMBFileRow(file: file, viewModel: viewModel, onFileTap: onFileTap)
                    }
                }
            } else {
                // Not connected placeholder
                VStack {
                    Spacer()
                    Image(systemName: "network.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Not Connected")
                        .font(.title2)
                        .padding()
                    Button("Connect") {
                        NotificationCenter.default.post(name: Notification.Name("OpenSMBConnect"), object: nil)
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .onDrop(of: [UTType.plainText.identifier], isTargeted: nil) { providers -> Bool in
            for provider in providers {
                onLocalFileDrop(provider)
            }
            return true
        }
    }
}
