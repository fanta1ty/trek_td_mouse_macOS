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
    @State private var isShowingPreview = false
    @State private var previewFile: PreviewFileInfo? = nil
    
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
                    transferProgress: $transferProgress,
                    onDownloadFile: downloadFile
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
                    isDraggingSmbToLocal: $isDraggingSmbToLocal,
                    onUploadFile: uploadFile
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
                    viewModel: smbViewModel,
                    stats: stats,
                    isPresented: $smbViewModel.showTransferSummary
                )
            }
        }
        .sheet(isPresented: $isShowingPreview) {
            if let fileInfo = previewFile {
                UniversalFilePreviewView(
                    title: fileInfo.name,
                    fileProvider: fileInfo.fileProvider,
                    fileExtension: fileInfo.fileExtension
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
            
            // Set up notification handlers for file operations
            NotificationCenter.default.addObserver(
                forName: Notification.Name("PreviewSMBFile"),
                object: nil,
                queue: .main
            ) { notification in
                if let file = notification.object as? File {
                    showSmbFilePreview(file)
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: Notification.Name("PreviewLocalFile"),
                object: nil,
                queue: .main
            ) { notification in
                if let file = notification.object as? LocalFile {
                    showLocalFilePreview(file)
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: Notification.Name("DownloadSMBFile"),
                object: nil,
                queue: .main
            ) { notification in
                if let file = notification.object as? File {
                    downloadFile(file)
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: Notification.Name("UploadLocalFile"),
                object: nil,
                queue: .main
            ) { notification in
                if let file = notification.object as? LocalFile {
                    uploadFile(file)
                }
            }
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

// MARK: - Private Functions
extension DualPaneFileTransferView {
    private func showSmbFilePreview(_ file: File) {
        previewFile = PreviewFileInfo(
            name: file.name,
            fileProvider: {
                return try await smbViewModel.downloadFile(fileName: file.name, trackTransfer: false)
            },
            fileExtension: file.name.components(separatedBy: ".").last ?? ""
        )
        isShowingPreview = true
    }

    private func showLocalFilePreview(_ file: LocalFile) {
        previewFile = PreviewFileInfo(
            name: file.name,
            fileProvider: {
                return try Data(contentsOf: file.url)
            },
            fileExtension: file.name.components(separatedBy: ".").last ?? ""
        )
        isShowingPreview = true
    }
    
    private func downloadFile(_ file: File) {
        // Download to current local directory
        let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(file.name)
        
        Task {
            transferManager.activeTransfer = .toLocal
            transferManager.currentTransferItem = file.name
            transferProgress = 0
            
            do {
                let data = try await smbViewModel.downloadFile(fileName: file.name)
                try data.write(to: localURL)
                
                // Refresh local files
                localViewModel.refreshFiles()
                transferProgress = 1.0
                
                // Give time for UI to show completion before removing status
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                transferManager.activeTransfer = nil
                transferManager.currentTransferItem = ""
            } catch {
                print("Download failed: \(error)")
                transferManager.activeTransfer = nil
                transferManager.currentTransferItem = ""
            }
        }
    }
    
    private func uploadFile(_ file: LocalFile) {
        Task {
            transferManager.activeTransfer = .toRemote
            transferManager.currentTransferItem = file.name
            transferProgress = 0
            
            do {
                try await smbViewModel.uploadLocalFile(url: file.url)
                transferProgress = 1.0
                
                // Give time for UI to show completion before removing status
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                transferManager.activeTransfer = nil
                transferManager.currentTransferItem = ""
            } catch {
                print("Upload error: \(error)")
                transferManager.activeTransfer = nil
                transferManager.currentTransferItem = ""
            }
        }
    }
}
