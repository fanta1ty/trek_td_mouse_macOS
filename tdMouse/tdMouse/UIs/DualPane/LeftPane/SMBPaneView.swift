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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            // Root (share) button
                            Button(action: {
                                Task {
                                    try await viewModel.listFiles("")
                                }
                            }) {
                                Text(viewModel.shareName)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            if !viewModel.currentDirectory.isEmpty {
                                Text("/")
                                    .foregroundColor(.secondary)
                                
                                // Split the path and create clickable segments
                                let pathComponents = viewModel.currentDirectory.components(separatedBy: "/")
                                ForEach(0..<pathComponents.count, id: \.self) { index in
                                    let component = pathComponents[index]
                                    
                                    // Build the path up to this segment
                                    let subPath = pathComponents[0...index].joined(separator: "/")
                                    
                                    Button(action: {
                                        Task {
                                            try await viewModel.listFiles(subPath)
                                        }
                                    }) {
                                        Text(component)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    
                                    if index < pathComponents.count - 1 {
                                        Text("/")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .frame(height: 28)
                .background(Color(NSColor.textBackgroundColor))
                
                // File list
                List {
                    ForEach(viewModel.files.filter { $0.name != "." && $0.name != ".." }, id: \.name) { file in
                        SMBFileRow(viewModel: viewModel, file: file, onFileTap: onFileTap)
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
