//
//  SMBPane.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 31/3/25.
//

import SwiftUI
import SMBClient

struct SMBPane: View {
    @EnvironmentObject private var viewModel: FileTransferViewModel
    
    @Binding var currentPreviewFile: PreviewFileInfo?
    @Binding var activePaneIndex: Int
    @Binding var showPreviewSheet: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            SMBPaneHeaderView()
                .padding(.vertical, 4)
            
            if viewModel.connectionState == .connected {
                // Breadcrumb path
                SMBPathIndicatorView()
                    .padding(.bottom, 4)
                
                // File list
                SMBPaneFileListView(onTap: handleSMBFileTap)
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
        .dropDestination(for: String.self) { items, location in
            return true
        }
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
}

struct SMBPane_Previews: PreviewProvider {
    static var previews: some View {
        SMBPane(
            currentPreviewFile: .constant(nil),
            activePaneIndex: .constant(0),
            showPreviewSheet: .constant(false)
        )
        .environmentObject(FileTransferViewModel())
        .environmentObject(LocalViewModel())
    }
}
