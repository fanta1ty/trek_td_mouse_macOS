//
//  LocalPane.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import SwiftUI

struct LocalPane: View {
    @EnvironmentObject private var viewModel: LocalViewModel
    
    @Binding var currentPreviewFile: PreviewFileInfo?
    @Binding var activePaneIndex: Int
    @Binding var showPreviewSheet: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            LocalPaneHeaderView()
            .padding(.vertical, 4)
            
            // Path indicator
            LocalPathIndicatorView()
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
    }
}

extension LocalPane {
    private func handleLocalFileTap(_ file: LocalFile) {
        if file.isDirectory {
            viewModel
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
    }
}
