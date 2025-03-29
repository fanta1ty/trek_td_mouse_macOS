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
    
    let onDownloadFile: (_ file: File) -> Void
    
    var body: some View {
        List {
            ForEach(viewModel.files, id: \.name) { file in
                SMBFileRowView(file: file, viewModel: viewModel)
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
                            onDownloadFile: onDownloadFile,
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
                onDownloadFile(file)
            }
        }
    }
    
    private func showSmbFilePreview(_ file: File) {
        previewingSmbFile = file
        previewingFile = true
    }
}
