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
//                let provider = NSItemProvider(object: file.name as NSString)
//                return provider
                // Create a dictionary with the file information
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
