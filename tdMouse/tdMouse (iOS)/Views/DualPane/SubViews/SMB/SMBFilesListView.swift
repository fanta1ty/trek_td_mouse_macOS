//
//  SMBFilesListView.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI
import SMBClient

struct SMBFilesListView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @ObservedObject var localViewModel: LocalFileViewModel
    @ObservedObject var transferManager: TransferManager
    
    @Binding var draggedSmbFile: File?
    @Binding var previewingFile: Bool
    @Binding var previewingSmbFile: File?
    @Binding var previewingLocalFile: LocalFile?
    @Binding var transferProgress: Double
    
    var body: some View {
        List {
            ForEach(viewModel.files, id: \.name) { file in
                SMBFileRowView(viewModel: viewModel, file: file)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleSmbFileTap(file)
                    }
                    .contextMenu {
                        SMBFileContextMenu(
                            viewModel: viewModel,
                            localViewModel: localViewModel,
                            transferManager: transferManager,
                            previewingFile: $previewingFile,
                            previewingSmbFile: $previewingSmbFile,
                            previewingLocalFile: $previewingLocalFile,
                            transferProgress: $transferProgress,
                            onDownloadFile: downloadFile,
                            onHandleSmbFileTap: handleSmbFileTap,
                            onShowSmbFilePreview: showSmbFilePreview,
                            file: file
                        )
                    }
                // Enable dragging from SMB to local
                    .onDrag {
                        self.draggedSmbFile = file
                        return NSItemProvider(object: file.name as NSString)
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Private Functions
extension SMBFilesListView {
    private func handleSmbFileTap(_ file: File) {
        if viewModel.isDirectory(file) {
            Task {
                try await viewModel.navigateToDirectory(file.name)
            }
        } else if viewModel.connectionState == .connected {
            // Show file preview for non-directory items
            if Helpers.isPreviewableFileType(file.name) {
                showSmbFilePreview(file)
            } else {
                downloadFile(file)
            }
        }
    }
    
    private func downloadFile(_ file: File) {
        // Download to current local directory
        let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(file.name)
        
        Task {
            transferManager.activeTransfer = .toLocal
            transferManager.currentTransferItem = file.name
            transferProgress = 0
            
            do {
                let data = try await viewModel.downloadFile(fileName: file.name)
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
    
    private func showSmbFilePreview(_ file: File) {
        previewingSmbFile = file
        previewingFile = true
    }
}
