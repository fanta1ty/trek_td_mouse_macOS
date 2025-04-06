//
//  LocalPaneFileListView.swift
//  tdMouse
//
//  Created by mobile on 3/4/25.
//

import SwiftUI
import Photos

struct LocalPaneFileListView: View {
    @EnvironmentObject private var viewModel: LocalViewModel
    
    let onTap: (LocalFile) -> Void
    
    var body: some View {
        if viewModel.isLoading {
            ProgressView("Loading files...")
                .frame(maxWidth: .infinity)
        } else if viewModel.localFiles.isEmpty {
            EmptyStateView(
                systemName: "folder",
                title: "No Files",
                message: "This folder is empty"
            )
        } else {
            List {
                ForEach(viewModel.localFiles) { file in
                    LocalPaneFileRowView(
                        showActionSheet: .constant(false),
                        file: file,
                        onTap: onTap
                    )
                    .padding(.vertical, 2)
                    .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                    .contentShape(Rectangle())
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                             deleteFile(file)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        }
    }
}

extension LocalPaneFileListView {
    private func deleteFile(_ file: LocalFile) {
        Task {
            do {
                if let photoAsset = file.photoAsset {
                    try await deletePhotoAsset(photoAsset)
                } else {
                    try FileManager.default.removeItem(at: file.url)
                    await MainActor.run {
                        viewModel.refreshLocalFiles()
                    }
                }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = "Failed to delete file: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deletePhotoAsset(_ asset: PHAsset) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                // Create a change request to delete the asset
                PHAssetChangeRequest.deleteAssets([asset] as NSArray)
            }) { success, error in
                if success {
                    continuation.resume()
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "PHAsset",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to delete photo asset"]
                    ))
                }
            }
        }
    }
}

struct LocalPaneFileListView_Previews: PreviewProvider {
    static var previews: some View {
        LocalPaneFileListView(
            onTap: { _ in }
        )
        .environmentObject(FileTransferViewModel())
        .environmentObject(LocalViewModel())
    }
}
