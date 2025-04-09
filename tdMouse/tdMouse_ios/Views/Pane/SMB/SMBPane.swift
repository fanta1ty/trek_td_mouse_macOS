//
//  SMBPane.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 31/3/25.
//

import SwiftUI
import SMBClient
import Photos

struct SMBPane: View {
    @EnvironmentObject private var viewModel: FileTransferViewModel
    @EnvironmentObject private var transferManager: TransferManager
    
    @State private var isDropTargetActive: Bool = false
    
    @Binding var currentPreviewFile: PreviewFileInfo?
    @Binding var activePaneIndex: Int
    @Binding var showPreviewSheet: Bool
    @Binding var isCreateFolderSheetPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            SMBPaneHeaderView(
                isCreateFolderSheetPresented: $isCreateFolderSheetPresented
            )
            .padding(.vertical, 4)
            
            if viewModel.connectionState == .connected {
                // Breadcrumb path
                SMBPanePathIndicatorView()
                    .padding(.bottom, 4)
                
                // File list
                SMBPaneFileListView(onTap: handleSMBFileTap)
                
                if isDropTargetActive {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green, lineWidth: 3)
                        .background(Color.green.opacity(0.1))
                        .overlay(
                            VStack {
                                Image(systemName: "arrow.up.doc.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                                Text("Drop to Upload")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                        )
                }
            } else {
                EmptyStateView(
                    systemName: "link.slash",
                    title: "Not Connected",
                    message: "Connect to a TD Mouse to view files"
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.5), lineWidth: activePaneIndex == 0 ? 0.5 : 0)
        )
        .padding(2)
        .onTapGesture {
            activePaneIndex = 0
        }
//        .dropDestination(for: String.self) { items, _ in
//            handleFileDrop(items)
//            return true
//        } isTargeted: { isTargeted in
//            isDropTargetActive = isTargeted
//        }
    }
}

extension SMBPane {
    private func handleSMBFileTap(_ file: File) {
        if viewModel.isDirectory(file) {
            Task {
                try await viewModel.navigateToDirectory(file.name)
            }
        } else if Helpers.isPreviewableFileType(file.name) {
            previewSmbFile(file)
        }
    }
    
    private func previewSmbFile(_ file: File) {
        guard let fileExtension = file.name.components(separatedBy: ".").last else { return }
        
        Task {
            do {
                let downloadedData = try await viewModel.downloadFile(
                    fileName: file.name,
                    trackTransfer: false
                )
                
                await MainActor.run {
                    currentPreviewFile = PreviewFileInfo(
                        title: file.name,
                        provider: {
                            downloadedData
                        },
                        extension: fileExtension
                    )
                    
                    showPreviewSheet = true
                }
            } catch {
                print("Preview file failed: \(error)")
            }
        }
    }
    
    private func handleFileDrop(_ items: [String]) {
        guard !items.isEmpty, viewModel.connectionState == .connected else { return }
        
        for item in items {
            if let data = item.data(using: .utf8),
               let fileInfo = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let fileName = fileInfo["name"],
               let path = fileInfo["path"],
               let isDirectoryStr = fileInfo["isDirectory"],
               fileInfo["type"] == "localFile" {
                
                let isDirectory = isDirectoryStr == "true"
                
                // Check if this is a photo asset
                if fileInfo["isPhotoAsset"] == "true",
                    let assetLocalIdentifier = fileInfo["assetLocalIdentifier"] {
                    
                    // Handle photo asset upload
                    handlePhotoAssetUpload(
                        id: assetLocalIdentifier,
                        fileName: fileName,
                        isDirectory: isDirectory
                    )
                    continue
                }
                
//                let url = URL(filePath: path)
                let url = URL(string: path)!
                
                guard let file = localFileFromURL(url) else {
                    continue
                }
                
                Task {
                    if isDirectory {
                        await transferManager.startFolderUpload(
                            folder: file,
                            smbViewModel: viewModel) {
                                Task {
                                    try? await viewModel.listFiles(viewModel.currentDirectory)
                                }
                            }
                    } else {
                        // Handle single file upload
                        await transferManager.startSingleFileUpload(
                            file: file,
                            smbViewModel: viewModel) {
                                Task {
                                    try? await viewModel.listFiles(viewModel.currentDirectory)
                                }
                            }
                    }
                }
            }
        }
    }
    
    private func localFileFromURL(_ url: URL) -> LocalFile? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [
                .isDirectoryKey,
                .fileSizeKey,
                .contentModificationDateKey
            ])
            let isDirectory = resourceValues.isDirectory ?? false
            let size = resourceValues.fileSize ?? 0
            let modificationDate = resourceValues.contentModificationDate ?? Date()
            
            return LocalFile(
                name: url.lastPathComponent,
                url: url,
                isDirectory: isDirectory,
                size: Int64(size),
                modificationDate: modificationDate
            )
            
        } catch {
            print("Error creating local file from URL: \(error)")
            return nil
        }
    }
    
    private func handlePhotoAssetUpload(
        id: String,
        fileName: String,
        isDirectory: Bool
    ) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        
        guard let photoAsset = fetchResult.firstObject else {
            return
        }
        
        Task {
            await transferManager.startPhotoAssetUpload(
                photoAsset: photoAsset,
                fileName: fileName,
                destinationPath: viewModel.pathForItem(fileName),
                smbViewModel: viewModel) {
                    Task {
                        try? await viewModel.listFiles(viewModel.currentDirectory)
                    }
                }
        }
    }
}

struct SMBPane_Previews: PreviewProvider {
    static var previews: some View {
        SMBPane(
            currentPreviewFile: .constant(nil),
            activePaneIndex: .constant(0),
            showPreviewSheet: .constant(false),
            isCreateFolderSheetPresented: .constant(false)
        )
        .environmentObject(FileTransferViewModel())
        .environmentObject(LocalViewModel())
        .environmentObject(TransferManager())
    }
}
