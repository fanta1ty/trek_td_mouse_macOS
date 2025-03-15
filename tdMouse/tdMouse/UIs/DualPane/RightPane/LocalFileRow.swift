//
//  LocalFileRow.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI

struct LocalFileRow: View {
    let file: LocalFile
    @ObservedObject var viewModel: LocalFileViewModel
    let onFileTap: (LocalFile) -> Void
    
    var body: some View {
        LocalFileRowView(viewModel: viewModel, file: file)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                onFileTap(file)
            }
            .onDrag {
                let provider = NSItemProvider(object: file.url as NSURL)
                return provider
            }
            .contextMenu {
                fileContextMenu()
            }
    }
    
    @ViewBuilder
    private func fileContextMenu() -> some View {
        if file.isDirectory {
            Button("Open") {
                onFileTap(file)
            }
        } else {
            Button("Upload to SMB") {
                NotificationCenter.default.post(name: Notification.Name("UploadLocalFile"), object: file)
            }
        }
        
        Button("Delete") {
            viewModel.deleteFile(file)
        }
    }
}

struct LocalFileRow_Preview: PreviewProvider {
    static var previews: some View {
        LocalFileRow(
            file: .init(
                name: "Name",
                url: .homeDirectory,
                isDirectory: false,
                size: 100
            ),
            viewModel: LocalFileViewModel(),
            onFileTap: { _ in }
        )
    }
}
