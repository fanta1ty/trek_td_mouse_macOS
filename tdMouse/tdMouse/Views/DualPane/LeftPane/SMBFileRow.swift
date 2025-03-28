//
//  SMBFileRow.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI
import SMBClient

struct SMBFileRow: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @State private var showActionSheet = false
    @State private var showFilePreview = false
    
    let file: File
    let onFileTap: (File) -> Void
    
    var body: some View {
        SmbFileRowView(viewModel: viewModel, file: file)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                onFileTap(file)
            }
            .onTapGesture(count: 1) {
                // Single tap can be used for selection if needed
            }
            .onDrag {
                // Create a dictionary with file information for drag operation
                let fileInfo = [
                    "name": file.name,
                    "isDirectory": file.isDirectory ? "true" : "false",
                    "type": "smbFile"
                ]
                
                // Convert to JSON
                if let jsonData = try? JSONSerialization.data(withJSONObject: fileInfo),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    let provider = NSItemProvider()
                    provider.registerObject(jsonString as NSString, visibility: .all)
                    return provider
                }
                
                // Fallback if JSON fails
                let provider = NSItemProvider()
                provider.registerObject(file.name as NSString, visibility: .all)
                return provider
            }
            .contextMenu {
                fileContextMenu()
            }
            .sheet(isPresented: $showActionSheet) {
                FileActionSheet(
                    viewModel: viewModel,
                    isPresented: $showActionSheet,
                    file: file,
                    transferManager: TransferManager(),
                    localViewModel: LocalFileViewModel()
                )
            }
            .sheet(isPresented: $showFilePreview) {
                if !viewModel.isDirectory(file) {
                    UniversalFilePreviewView(
                        title: file.name,
                        fileProvider: {
                            return try await viewModel.downloadFile(fileName: file.name)
                        },
                        fileExtension: file.name.components(separatedBy: ".").last ?? ""
                    )
                }
            }
    }
    
    @ViewBuilder
    private func fileContextMenu() -> some View {
        Group {
            if viewModel.isDirectory(file) {
                Button {
                    onFileTap(file)
                } label: {
                    Label("Open", systemImage: "folder")
                }
                
                Button {
                    NotificationCenter.default.post(
                        name: Notification.Name("DownloadSMBFolder"),
                        object: file
                    )
                } label: {
                    Label("Download Folder", systemImage: "arrow.down.doc")
                }
            } else {
                Button {
                    NotificationCenter.default.post(
                        name: Notification.Name("DownloadSMBFile"),
                        object: file
                    )
                } label: {
                    Label("Download", systemImage: "arrow.down")
                }
                
                if Helpers.isPreviewableFileType(file.name) {
                    Button {
                        showFilePreview = true
                    } label: {
                        Label("Preview", systemImage: "eye")
                    }
                }
            }
            
            Divider()
            
            Button(role: .destructive) {
                Task {
                    if viewModel.isDirectory(file) {
                        try await viewModel.deleteDirectoryRecursively(name: file.name)
                    } else {
                        try await viewModel.deleteItem(name: file.name, isDirectory: viewModel.isDirectory(file))
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Divider()
            
            Button {
                showActionSheet = true
            } label: {
                Label("More Actions...", systemImage: "ellipsis.circle")
            }
        }
    }
}
