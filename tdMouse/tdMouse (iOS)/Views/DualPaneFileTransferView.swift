//
//  DualPaneFileTransferView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 28/3/25.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers
import SMBClient

struct DualPaneFileTransferView: View {
    @StateObject private var smbViewModel = FileTransferViewModel()
    @StateObject private var localViewModel = LocalFileViewModel()
    @StateObject private var transferManager = TransferManager()
    
    @State private var isConnectSheetPresented = false
    @State private var isCreateFolderSheetPresented = false
    @State private var newFolderName = ""
    @State private var transferProgress: Double = 0
    @State private var draggedSmbFile: File?
    @State private var draggedLocalFile: LocalFile?
    @State private var isDraggingSmbToLocal = false
    @State private var isDraggingLocalToSmb = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // SMB Header
                smbHeaderView
            }
            .frame(height: UIScreen.main.bounds.height * 0.45)
            
            // Divider
            Divider()
                .padding(.vertical, 4)
            
            // Bottom view - local files
            VStack(spacing: 0) {
                // Local Files header
                localHeaderView
                
                // Path bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Text(localViewModel.currentDirectoryURL.path)
                            .lineLimit(1)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    .frame(height: 30)
                }
                .background(Color(UIColor.secondarySystemBackground))
                
                // Local Files list
                ZStack {
                    if localViewModel.isLoading {
                        ProgressView("Loading files...")
                        
                    } else if localViewModel.files.isEmpty {
                        emptyFilesPlaceholder(message: "No Files", description: "This folder is empty")
                    }
                }
                .frame(maxWidth: .infinity)
                .onDrop(of: [UTType.data.identifier], isTargeted: $isDraggingSmbToLocal) { providers in
                    if let smbFile = draggedSmbFile, smbViewModel.connectionState == .connected {
                        // handleSmbFileDroppedToLocal(smbFile)
                        return true
                    }
                    return false
                }
                .background(isDraggingSmbToLocal ? Color.blue.opacity(0.1) : Color.clear)
            }
            .frame(maxHeight: .infinity)
        }
        .overlay(transferOverlay)
    }
    
    // MARK: - SMB Header View
    private var smbHeaderView: some View {
        HStack  {
            Text("TD Mouse")
                .font(.headline)
                .padding(.leading)
            
            Spacer()
            
            if smbViewModel.connectionState == .connected {
                Button {
                    Task {
                        try await smbViewModel.navigateUp()
                    }
                } label: {
                    Image(systemName: "arrow.up")
                }
                .disabled(smbViewModel.currentDirectory.isEmpty)
                .padding(.horizontal, 4)

                Button {
                    Task {
                        try await smbViewModel.listFiles(smbViewModel.currentDirectory)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .padding(.horizontal, 4)
                
                Button(action: {
                    isCreateFolderSheetPresented.toggle()
                }) {
                    Image(systemName: "folder.badge.plus")
                }
                .padding(.horizontal, 4)
            }
            
            Button(action: {
                isConnectSheetPresented.toggle()
            }) {
                Image(systemName: smbViewModel.connectionState == .connected ? "link" : "link.badge.plus")
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.tertiarySystemBackground))
    }
    
    // MARK: - Local Header View
    private var localHeaderView: some View {
        HStack {
            Text("Local Files")
                .font(.headline)
                .padding(.leading)
            
            Spacer()
            
            Button {
                localViewModel.selectDirectory()
            } label: {
                Image(systemName: "folder.badge.plus")
            }
            .padding(.horizontal, 4)
            
            Button(action: {
                localViewModel.navigateUp()
            }) {
                Image(systemName: "arrow.up")
            }
            .disabled(!localViewModel.canNavigateUp)
            .padding(.horizontal, 4)
            
            Button(action: {
                localViewModel.refreshFiles()
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.tertiarySystemBackground))
    }
    
    // MARK: - Transfer Overlay
    @ViewBuilder
    private var transferOverlay: some View {
        if let activeTransfer = transferManager.activeTransfer {
            VStack {
                Spacer()
                
                HStack {
                    switch activeTransfer {
                    case .toLocal:
                        Image(systemName: "arrow.down")
                            .foregroundColor(.blue)
                        Text("Downloading \(transferManager.currentTransferItem)")
                        
                    case .toRemote:
                        Image(systemName: "arrow.up")
                            .foregroundColor(.blue)
                        Text("Uploading \(transferManager.currentTransferItem)")
                    }
                    
                    Spacer()
                    
                    // Progress information
                    if transferManager.totalTransferItems > 1 {
                        Text("\(transferManager.processedTransferItems)/\(transferManager.totalTransferItems)")
                            .font(.caption)
                    }
                    
                    ProgressView(value: transferProgress)
                        .frame(width: 80)
                    
                    Text("\(Int(transferProgress * 100))%")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
            .padding()
        }
    }
    
    // MARK: - Empty Files Placeholder
    private func emptyFilesPlaceholder(
        message: String,
        description: String
    ) -> some View {
        VStack {
            Spacer()
            Image(systemName: "doc.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(message)
                .font(.headline)
            Text(description)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct DualPaneFileTransferView_Preview: PreviewProvider {
    static var previews: some View {
        DualPaneFileTransferView()
    }
}
