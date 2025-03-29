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
    @State private var previewingFile: Bool = false
    @State private var previewingSmbFile: File?
    @State private var previewingLocalFile: LocalFile?
    
    var body: some View {
        VStack(spacing: 0) {
            // Top View - TD Mouse
            VStack(spacing: 0) {
                // SMB Header
                SMBHeaderView(
                    viewModel: smbViewModel,
                    isCreateFolderSheetPresented: $isCreateFolderSheetPresented,
                    isConnectSheetPresented: $isConnectSheetPresented
                )
                
                // Path bar
                SMBPathBarView(viewModel: smbViewModel)
                
                // SMB File List
                SMBFilesListContainerView(
                    viewModel: smbViewModel,
                    localViewModel: localViewModel,
                    transferManager: transferManager,
                    draggedSmbFile: $draggedSmbFile,
                    previewingSmbFile: $previewingSmbFile,
                    draggedLocalFile: $draggedLocalFile,
                    previewingLocalFile: $previewingLocalFile,
                    isConnectSheetPresented: $isConnectSheetPresented,
                    isDraggingLocalToSmb: $isDraggingLocalToSmb,
                    previewingFile: $previewingFile,
                    transferProgress: $transferProgress
                )
            }
            .frame(height: UIScreen.main.bounds.height * 0.45)
            
            // Divider
            Divider()
                .padding(.vertical, 4)
            
            // Bottom view - local files
            VStack(spacing: 0) {
                // Local Files header
                LocalHeaderView(viewModel: localViewModel)
                
                // Path bar
                LocalPathBarView(viewModel: localViewModel)
                
                // Local Files list
                LocalFilesListContainerView(
                    viewModel: localViewModel,
                    smbViewModel: smbViewModel,
                    transferManager: transferManager,
                    previewingLocalFile: $previewingLocalFile,
                    previewingSmbFile: $previewingSmbFile,
                    previewingFile: $previewingFile,
                    transferProgress: $transferProgress,
                    draggedSmbFile: $draggedSmbFile,
                    isDraggingSmbToLocal: $isDraggingSmbToLocal
                )
            }
            .frame(maxHeight: .infinity)
        }
        .overlay(transferOverlay)
        .sheet(isPresented: $isConnectSheetPresented, content: {
            ConnectionSheet(
                viewModel: smbViewModel,
                isPresented: $isConnectSheetPresented
            )
        })
        .sheet(isPresented: $isCreateFolderSheetPresented) {
            CreateFolderSheet(
                viewModel: smbViewModel,
                isPresented: $isCreateFolderSheetPresented,
                folderName: $newFolderName
            )
        }
        .sheet(isPresented: $smbViewModel.showTransferSummary) {
            if let stats = smbViewModel.lastTransferStats {
                TransferSummaryView(
                    stats: stats,
                    isPresented: $smbViewModel.showTransferSummary
                )
            }
        }
        .alert("SMB Error", isPresented: .init(
            get: { !smbViewModel.errorMessage.isEmpty },
            set: { if !$0 { smbViewModel.errorMessage = "" } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(smbViewModel.errorMessage)
        }
        .alert("Local Error", isPresented: .init(
            get: { !localViewModel.errorMessage.isEmpty },
            set: { if !$0 { localViewModel.errorMessage = "" } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(localViewModel.errorMessage)
        }
        .onAppear {
            localViewModel.initialize()
        }
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
}

struct DualPaneFileTransferView_Preview: PreviewProvider {
    static var previews: some View {
        DualPaneFileTransferView()
    }
}
