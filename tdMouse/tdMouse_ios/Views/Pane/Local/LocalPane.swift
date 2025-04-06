//
//  LocalPane.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import SwiftUI

struct LocalPane: View {
    @EnvironmentObject private var viewModel: LocalViewModel
    @EnvironmentObject private var smbViewModel: FileTransferViewModel
    @EnvironmentObject private var transferManager: TransferManager

    @Binding var currentPreviewFile: PreviewFileInfo?
    @Binding var activePaneIndex: Int
    @Binding var showPreviewSheet: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            LocalPaneHeaderView()
                .padding(.vertical, 4)
            
            // Path indicator
            LocalPanePathIndicatorView()
                .padding(.bottom, 4)
            
            // Local file list
            LocalPaneFileListView(
                onTap: handleLocalFileTap
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.5), lineWidth: activePaneIndex == 0 ? 0.5 : 0)
        )
        .padding(2)
        .onTapGesture {
            activePaneIndex = 1
        }
        .dropDestination(for: String.self) { items, _ in
            handleFileDrop(items)
            return true
        }
    }
}

extension LocalPane {
    private func handleLocalFileTap(_ file: LocalFile) {
        if file.isDirectory {
            viewModel.navigateToDirectory(localFile: file)
        } else if Helpers.isPreviewableFileType(file.name) {
            previewLocalFile(file)
        }
    }
    
    private func previewLocalFile(_ file: LocalFile) {
        currentPreviewFile = PreviewFileInfo(
            title: file.name,
            provider: {
                try Data(contentsOf: file.url)
            },
            extension: file.name.components(separatedBy: ".").last ?? ""
        )
        showPreviewSheet = true
    }

    private func handleFileDrop(_ items: [String]) {
        guard !items.isEmpty else { return }

        for item in items {
            // Try to parse as JSON first
            if let data = item.data(using: .utf8),
               let fileInfo = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let fileName = fileInfo["name"],
               let isDirectoryStr = fileInfo["isDirectory"],
               fileInfo["type"] == "smbFile" {

                // Get the file from SMB view model
                guard let file = smbViewModel.getFileByName(fileName) else {
                    return
                }

                let isDirectory = isDirectoryStr == "true"

                Task {
                    if isDirectory {
                        // Handle folder download
                        guard let destURL = viewModel.currentDirectory?.appendingPathComponent(fileName) else {
                            return
                        }

                        await transferManager.startFolderDownload(
                            folder: file,
                            destination: destURL,
                            smbViewModel: smbViewModel) {
                                viewModel.refreshLocalFiles()
                            }

                    } else {
                        // Handle single file download
                        guard let destURL = viewModel.currentDirectory?.appendingPathComponent(fileName) else {
                            return
                        }

                        await transferManager.startSingleFileDownload(
                            file: file,
                            destinationURL: destURL,
                            smbViewModel: smbViewModel) {
                                viewModel.refreshLocalFiles()
                            }
                    }
                }

            } else {
                // Try as simple file name
                guard let file = smbViewModel.getFileByName(item) else {
                    return
                }

                Task {
                    guard let destURL = viewModel.currentDirectory?.appendingPathComponent(file.name) else {
                        return
                    }

                    await transferManager.startSingleFileDownload(
                        file: file,
                        destinationURL: destURL,
                        smbViewModel: smbViewModel) {
                            viewModel.refreshLocalFiles()
                        }
                }
            }
        }
    }
}

struct LocalPane_Previews: PreviewProvider {
    static var previews: some View {
        LocalPane(
            currentPreviewFile: .constant(nil),
            activePaneIndex: .constant(0),
            showPreviewSheet: .constant(false)
        )
        .environmentObject(FileTransferViewModel())
        .environmentObject(LocalViewModel())
        .environmentObject(TransferManager())
    }
}
