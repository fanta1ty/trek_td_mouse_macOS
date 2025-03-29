//
//  SMBFilesListContainerView.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI
import SMBClient
import UniformTypeIdentifiers

struct SMBFilesListContainerView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @ObservedObject var localViewModel: LocalFileViewModel
    @ObservedObject var transferManager: TransferManager
    
    @Binding var draggedSmbFile: File?
    @Binding var previewingSmbFile: File?
    @Binding var draggedLocalFile: LocalFile?
    @Binding var previewingLocalFile: LocalFile?
    @Binding var isConnectSheetPresented: Bool
    @Binding var isDraggingLocalToSmb: Bool
    @Binding var previewingFile: Bool
    @Binding var transferProgress: Double
    
    var body: some View {
        ZStack {
            if viewModel.connectionState == .connected {
                if viewModel.files.isEmpty {
                    LocalEmptyFilesView(
                        message: "No Files",
                        description: "This folder is empty"
                    )
                } else {
                    SMBFilesListView(
                        viewModel: viewModel,
                        localViewModel: localViewModel,
                        transferManager: transferManager,
                        draggedSmbFile: $draggedSmbFile,
                        previewingFile: $previewingFile,
                        previewingSmbFile: $previewingSmbFile,
                        previewingLocalFile: $previewingLocalFile,
                        transferProgress: $transferProgress
                    )
                }
            } else {
                // Not connected placeholder
                VStack(spacing: 20) {
                    Image(systemName: "network.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.secondary)
                    
                    Text("No Connected")
                        .font(.headline)
                    
                    Button("Connect") {
                        isConnectSheetPresented.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Enable drop of local file to TD Mouse
        .onDrop(of: [UTType.data.identifier], isTargeted: $isDraggingLocalToSmb) { providers in
            if let localFile = draggedLocalFile, viewModel.connectionState == .connected {
                handleLocalFileDroppedToSMB(localFile)
                return true
            }
            return false
        }
        .background(isDraggingLocalToSmb ? Color.blue.opacity(0.1) : Color.clear)
    }
}

// MARK: - Private Functions

extension SMBFilesListContainerView {
    private func handleLocalFileDroppedToSMB(_ file: LocalFile) {
        Task {
            if file.isDirectory {
                await transferManager.startFolderUpload(
                    folder: file,
                    smbViewModel: viewModel
                ) {
                    Task {
                        try? await viewModel.listFiles(viewModel.currentDirectory)
                    }
                }
            } else {
                await transferManager.startSingleFileUpload(
                    file: file,
                    smbViewModel: viewModel
                ) {
                    Task {
                        try? await viewModel.listFiles(viewModel.currentDirectory)
                    }
                }
            }
        }
    }
}
