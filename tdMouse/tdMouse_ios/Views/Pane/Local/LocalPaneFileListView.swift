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
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.localFiles.filter({ $0.name != ".DS_Store"} ), id: \.id) { file in
                        LocalPaneFileRowWithSwipeView(
                            file: file,
                            onTap: onTap,
                            onDelete: { deleteFile(file) }
                        )
                    }
                }
            }
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
