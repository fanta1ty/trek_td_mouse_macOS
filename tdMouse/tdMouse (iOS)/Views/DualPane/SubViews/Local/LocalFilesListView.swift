//
//  LocalFilesListView.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI

struct LocalFilesListView: View {
    @ObservedObject var viewModel: LocalFileViewModel
    @ObservedObject var smbViewModel: FileTransferViewModel
    @ObservedObject var transferManager: TransferManager
    
    @Binding var previewingLocalFile: LocalFile?
    @Binding var previewingFile: Bool
    @Binding var transferProgress: Double
    
    var body: some View {
        List {
            ForEach(viewModel.files, id: \.id) { file in
                LocalFileRowView(
                    viewModel: viewModel,
                    file: file
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    handleLocalFileTap(file)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let file = viewModel.files[index]
                    viewModel.deleteFile(file)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Private Functions
extension LocalFilesListView {
    private func handleLocalFileTap(_ file: LocalFile) {
        if file.isDirectory {
            viewModel.navigateToDirectory(file.name)
        } else {
            // Show file preview for non-directory items
            if Helpers.isPreviewableFileType(file.name) {
                showLocalFilePreview(file)
            } else if smbViewModel.connectionState == .connected {
                uploadFile(file)
            }
        }
    }
    
    private func showLocalFilePreview(_ file: LocalFile) {
        previewingLocalFile = file
        previewingFile = true
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
