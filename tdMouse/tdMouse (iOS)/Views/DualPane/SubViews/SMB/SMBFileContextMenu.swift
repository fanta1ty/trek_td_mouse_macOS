//
//  SMBFileContextMenu.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI
import SMBClient

struct SMBFileContextMenu: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @ObservedObject var localViewModel: LocalFileViewModel
    @ObservedObject var transferManager: TransferManager
    
    @Binding var previewingFile: Bool
    @Binding var previewingSmbFile: File?
    @Binding var previewingLocalFile: LocalFile?
    @Binding var transferProgress: Double
    
    let onDownloadFile: (_ file: File) -> Void
    let onHandleSmbFileTap: (_ file: File) -> Void
    let onShowSmbFilePreview: (_ file: File) -> Void
    
    let file: File
    
    var body: some View {
        if viewModel.isDirectory(file) {
            Button {
                onHandleSmbFileTap(file)
            } label: {
                Label("Open", systemImage: "folder")
            }
            
            Button {
                Task {
                    let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(file.name)
                    await transferManager.startFolderDownload(
                        folder: file,
                        destination: localURL,
                        smbViewModel: viewModel
                    ) {
                        localViewModel.refreshFiles()
                    }
                }
            } label: {
                Label("Download Folder", systemImage: "arrow.down.doc.fill")
            }
        } else {
            Button {
                onDownloadFile(file)
            } label: {
                Label("Download", systemImage: "arrow.down.doc")
            }
            
            if Helpers.isPreviewableFileType(file.name) {
                Button {
                    onShowSmbFilePreview(file)
                } label: {
                    Label("Preview", systemImage: "eye")
                }
            }
        }
        
        Button(role: .destructive) {
            Task {
                try await viewModel.deleteItem(name: file.name, isDirectory: viewModel.isDirectory(file))
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}
