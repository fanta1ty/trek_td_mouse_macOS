//
//  SMBPaneFileListView.swift
//  tdMouse
//
//  Created by mobile on 3/4/25.
//

import SwiftUI
import SMBClient

struct SMBPaneFileListView: View {
    @EnvironmentObject private var viewModel: FileTransferViewModel
    
    let onTap: (File) -> Void
    
    var body: some View {
        if viewModel.files.isEmpty {
            EmptyStateView(
                systemName: "folder",
                title: "No Files",
                message: "This folder is empty"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.files.filter{ $0.name != "." && $0.name != ".." }, id: \.name) { file in
                        SMBPaneFileRowWithSwipeView(
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

extension SMBPaneFileListView {
    private func deleteFile(_ file: File) {
        Task {
            if viewModel.isDirectory(file) {
                try await viewModel.deleteDirectoryRecursively(name: file.name)
            } else {
                try await viewModel.deleteItem(name: file.name, isDirectory: viewModel.isDirectory(file))
            }
        }
    }
}

struct SMBPaneFileListView_Previews: PreviewProvider {
    static var previews: some View {
        SMBPaneFileListView(
            onTap: { _ in }
        )
        .environmentObject(FileTransferViewModel())
        .environmentObject(LocalViewModel())
    }
}
