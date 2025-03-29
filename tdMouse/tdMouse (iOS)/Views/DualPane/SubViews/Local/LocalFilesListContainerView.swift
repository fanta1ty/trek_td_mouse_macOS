//
//  LocalFilesListContainerView.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI
import SMBClient
import UniformTypeIdentifiers

struct LocalFilesListContainerView: View {
    @ObservedObject var viewModel: LocalFileViewModel
    @ObservedObject var smbViewModel: FileTransferViewModel
    @ObservedObject var transferManager: TransferManager
    
    @Binding var previewingLocalFile: LocalFile?
    @Binding var previewingSmbFile: File?
    @Binding var previewingFile: Bool
    @Binding var transferProgress: Double
    @Binding var draggedSmbFile: File?
    @Binding var isDraggingSmbToLocal: Bool
    
    let onUploadFile: (_ file: LocalFile) -> Void
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading files...")
                
            } else if viewModel.files.isEmpty {
                LocalEmptyFilesView(
                    message: "No Files",
                    description: "This folder is empty"
                )
                
            } else {
                LocalFilesListView(
                    viewModel: viewModel,
                    smbViewModel: smbViewModel,
                    transferManager: transferManager,
                    previewingLocalFile: $previewingLocalFile,
                    previewingFile: $previewingFile,
                    transferProgress: $transferProgress,
                    onUploadFile: onUploadFile
                )
            }
        }
        .frame(maxWidth: .infinity)
        .onDrop(of: [UTType.data.identifier], isTargeted: $isDraggingSmbToLocal) { providers in
            if let smbFile = draggedSmbFile, smbViewModel.connectionState == .connected {
                handleSmbFileDroppedToLocal(smbFile)
                return true
            }
            return false
        }
        .background(isDraggingSmbToLocal ? Color.blue.opacity(0.1) : Color.clear)
    }
}

// MARK: - Private Functions
extension LocalFilesListContainerView {
    private func handleSmbFileDroppedToLocal(_ file: File) {
        // Download to current local directory
        let localURL = viewModel.currentDirectoryURL.appendingPathComponent(file.name)
        
        Task {
            if smbViewModel.isDirectory(file) {
                await transferManager.startFolderDownload(
                    folder: file,
                    destination: localURL,
                    smbViewModel: smbViewModel
                ) {
                    viewModel.refreshFiles()
                }
            } else {
                await transferManager.startSingleFileDownload(
                    file: file,
                    destinationURL: localURL,
                    smbViewModel: smbViewModel
                ) {
                    viewModel.refreshFiles()
                }
            }
        }
    }
}

struct LocalFilesListContainerView_Previews: PreviewProvider {
    static var previews: some View {
        LocalFilesListContainerView(
            viewModel: LocalFileViewModel(),
            smbViewModel: FileTransferViewModel(),
            transferManager: TransferManager(),
            previewingLocalFile: .constant(
                LocalFile(
                    name: "Local File Name",
                    url: URL(string: "https://www.google.com/")!,
                    isDirectory: false,
                    size: 20,
                    modificationDate: nil
                )
            ),
            previewingSmbFile: .constant(nil),
            previewingFile: .constant(true),
            transferProgress: .constant(0),
            draggedSmbFile: .constant(nil),
            isDraggingSmbToLocal: .constant(true),
            onUploadFile: { _ in }
        )
    }
}
