//
//  LocalPaneFileListView.swift
//  tdMouse
//
//  Created by mobile on 3/4/25.
//

import SwiftUI

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
                    ForEach(viewModel.localFiles) { file in
                        LocalPaneFileRowView(
                            showActionSheet: .constant(false),
                            file: file,
                            onTap: onTap
                        )
                        .padding(.vertical, 2)
                    }
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
