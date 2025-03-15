//
//  SMBFileRow.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI
import SMBClient

struct SMBFileRow: View {
    let file: File
    @ObservedObject var viewModel: FileTransferViewModel
    let onFileTap: (File) -> Void
    
    var body: some View {
        SmbFileRowView(viewModel: viewModel, file: file)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                onFileTap(file)
            }
            .onDrag {
                let provider = NSItemProvider(object: file.name as NSString)
                return provider
            }
            .contextMenu {
                fileContextMenu()
            }
    }
    
    @ViewBuilder
    private func fileContextMenu() -> some View {
        if viewModel.isDirectory(file) {
            Button("Open") {
                onFileTap(file)
            }
        } else {
            Button("Download") {
                NotificationCenter.default.post(name: Notification.Name("DownloadSMBFile"), object: file)
            }
        }
        
        Button("Delete") {
            Task {
                try await viewModel.deleteItem(name: file.name, isDirectory: viewModel.isDirectory(file))
            }
        }
    }
}
