//
//  FileListView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI
import SMBClient

struct FileListView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @Binding var selectedFile: File?
    @Binding var showFileActions: Bool
    
    var body: some View {
        List {
            ForEach(viewModel.files, id: \.name) { file in
                FileRowView(viewModel: viewModel, file: file)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        handleFileTap(file)
                    }
                    .contextMenu {
                        fileContextMenu(file: file)
                    }
            }
        }
        .listStyle(InsetListStyle())
    }
    
    private func handleFileTap(_ file: File) {
        if viewModel.isDirectory(file) {
            Task {
                try await viewModel.navigateToDirectory(file.name)
            }
        } else {
            downloadFile(file)
        }
    }
    
    private func downloadFile(_ file: File) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = file.name
        panel.canCreateDirectories = true
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task {
                    do {
                        let data = try await viewModel.downloadFile(fileName: file.name)
                        try data.write(to: url)
                    } catch {
                        print("Download error: \(error)")
                    }
                }
            }
        }
    }
    
    private func fileContextMenu(file: File) -> some View {
        Group {
            if viewModel.isDirectory(file) {
                Button("Open") {
                    handleFileTap(file)
                }
            } else {
                Button("Download") {
                    downloadFile(file)
                }
            }
            
            Button("Delete") {
                Task {
                    try await viewModel.deleteItem(
                        name: file.name,
                        isDirectory: viewModel.isDirectory(file)
                    )
                }
            }
            
            Button("More Options...") {
                selectedFile = file
                showFileActions = true
            }
        }
    }
}

struct FileListView_PReview: PreviewProvider {
    static var previews: some View {
        FileListView(
            viewModel: FileTransferViewModel(),
            selectedFile: .constant(nil),
            showFileActions: .constant(true)
        )
    }
}
