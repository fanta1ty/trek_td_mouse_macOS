//
//  LocalFileRow.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI

struct LocalFileRow: View {
    @ObservedObject var viewModel: LocalFileViewModel
    let file: LocalFile
    let onTap: (LocalFile) -> Void
    
    var body: some View {
        LocalFileRowView(viewModel: viewModel, file: file)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                onTap(file)
            }
            .onDrag {
                let fileInfo = [
                    "path": file.url.path,
                    "name": file.name,
                    "isDirectory": file.isDirectory ? "true" : "false",
                    "type": "localFile"
                ]
                
                // Convert to JSON
                if let jsonData = try? JSONSerialization.data(withJSONObject: fileInfo),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    let provider = NSItemProvider()
                    provider.registerObject(jsonString as NSString, visibility: .all)
                    return provider
                }
                
                // Fallback to simple URL provider
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
                onTap(file)
            }
            
            Button("Upload Folder to TD Mouse") {
                NotificationCenter.default.post(
                    name: Notification.Name("UploadLocalFolder"),
                    object: file
                )
            }
        } else {
            Button("Upload to TD Mouse") {
                NotificationCenter.default.post(
                    name: Notification.Name("UploadLocalFile"),
                    object: file
                )
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
            viewModel: LocalFileViewModel(), file: .init(
                name: "Name",
                url: .homeDirectory,
                isDirectory: false,
                size: 100
            ),
            onTap: { _ in }
        )
    }
}
