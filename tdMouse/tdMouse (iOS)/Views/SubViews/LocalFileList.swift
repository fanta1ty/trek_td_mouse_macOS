//
//  LocalFileList.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI

struct LocalFileList: View {
    @EnvironmentObject var localViewModel: LocalFileViewModel
    @EnvironmentObject var transferManager: TransferManager
    @EnvironmentObject var smbViewModel: FileTransferViewModel
    
    var body: some View {
        List {
            ForEach(localViewModel.files) { file in
                LocalFileRow(file: file)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleFileTap(file)
                    }
                    .onDrag {
                        // Enable drag with file data
                        let fileInfo = [
                            "path": file.url.path,
                            "name": file.name,
                            "isDirectory": file.isDirectory ? "true" : "false",
                            "type": "localFile"
                        ]
                        
                        if let data = try? JSONSerialization.data(withJSONObject: fileInfo),
                           let string = String(data: data, encoding: .utf8) {
                            return NSItemProvider(object: string as NSString)
                        }
                        
                        return NSItemProvider(object: file.url as NSURL)
                    }
                    .contextMenu {
                        // Context menu for additional actions
                        Button(action: {
                            handleFileTap(file)
                        }) {
                            Label(file.isDirectory ? "Open" : "Preview",
                                  systemImage: file.isDirectory ? "folder" : "eye")
                        }
                        
                        if !file.isDirectory {
                            Button(action: {
                                uploadFile(file)
                            }) {
                                Label("Upload to SMB", systemImage: "arrow.up.doc")
                            }
                            .disabled(smbViewModel.connectionState != .connected)
                        } else {
                            Button(action: {
                                uploadFolder(file)
                            }) {
                                Label("Upload Folder to SMB", systemImage: "arrow.up.doc.on.doc")
                            }
                            .disabled(smbViewModel.connectionState != .connected)
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            deleteFile(file)
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func handleFileTap(_ file: LocalFile) {
        if file.isDirectory {
            localViewModel.navigateToDirectory(file.name)
        } else if file.isPreviewable {
            previewFile(file)
        }
    }
    
    private func previewFile(_ file: LocalFile) {
        do {
            let data = try Data(contentsOf: file.url)
            let fileExt = file.name.components(separatedBy: ".").last ?? ""
            
            FilePreviewManager.shared.showPreview(
                title: "Preview",
                data: data,
                fileExtension: fileExt,
                originalFileName: file.name
            )
        } catch {
            print("Preview error: \(error)")
        }
    }
    
    private func uploadFile(_ file: LocalFile) {
        Task {
            await transferManager.startSingleFileUpload(
                file: file,
                smbViewModel: smbViewModel
            ) {}
        }
    }
    
    private func uploadFolder(_ file: LocalFile) {
        Task {
            await transferManager.startFolderUpload(
                folder: file,
                smbViewModel: smbViewModel
            ) {}
        }
    }
    
    private func deleteFile(_ file: LocalFile) {
        localViewModel.deleteFile(file)
    }
}
