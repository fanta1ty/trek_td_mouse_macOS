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
    
    let onUploadFile: (_ file: LocalFile) -> Void
    
    var body: some View {
        List {
            ForEach(viewModel.files, id: \.id) { file in
                LocalFileRowView(
                    file: file,
                    viewModel: viewModel
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
                onUploadFile(file)
            }
        }
    }
    
    private func showLocalFilePreview(_ file: LocalFile) {
        previewingLocalFile = file
        previewingFile = true
    }
}
