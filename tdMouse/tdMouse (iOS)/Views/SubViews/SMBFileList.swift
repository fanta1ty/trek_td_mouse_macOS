//
//  SMBFileList.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI
import SMBClient

struct SMBFileList: View {
    @EnvironmentObject var smbViewModel: FileTransferViewModel
    @EnvironmentObject var transferManager: TransferManager
    @EnvironmentObject var localViewModel: LocalFileViewModel
    
    var body: some View {
        List {
            ForEach(smbViewModel.files.filter { $0.name != "." && $0.name != ".." }, id: \.name) { file in
                SMBFileRow(file: file)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleFileTap(file)
                    }
                    .onDrag {
                        // Enable drag with file data
                        let fileInfo = [
                            "name": file.name,
                            "isDirectory": file.isDirectory ? "true" : "false",
                            "type": "smbFile"
                        ]
                        
                        if let data = try? JSONSerialization.data(withJSONObject: fileInfo),
                           let string = String(data: data, encoding: .utf8) {
                            return NSItemProvider(object: string as NSString)
                        }
                        
                        return NSItemProvider(object: file.name as NSString)
                    }
                    .contextMenu {
                        // Context menu for additional actions
                        Button(action: {
                            handleFileTap(file)
                        }) {
                            Label(smbViewModel.isDirectory(file) ? "Open" : "Preview",
                                  systemImage: smbViewModel.isDirectory(file) ? "folder" : "eye")
                        }
                        
                        if !smbViewModel.isDirectory(file) {
                            Button(action: {
                                downloadFile(file)
                            }) {
                                Label("Download", systemImage: "arrow.down.doc")
                            }
                        } else {
                            Button(action: {
                                downloadFolder(file)
                            }) {
                                Label("Download Folder", systemImage: "arrow.down.doc.on.doc")
                            }
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
    
    private func handleFileTap(_ file: File) {
        if smbViewModel.isDirectory(file) {
            Task {
                try await smbViewModel.navigateToDirectory(file.name)
            }
        } else if Helpers.isPreviewableFileType(file.name) {
            previewFile(file)
        } else {
            downloadFile(file)
        }
    }
    
    private func previewFile(_ file: File) {
        Task {
            do {
                let data = try await smbViewModel.downloadFile(fileName: file.name, trackTransfer: false)
                let fileExt = file.name.components(separatedBy: ".").last ?? ""
                
                DispatchQueue.main.async {
                    FilePreviewManager.shared.showPreview(
                        title: "Preview",
                        data: data,
                        fileExtension: fileExt,
                        originalFileName: file.name
                    )
                }
            } catch {
                print("Preview error: \(error)")
            }
        }
    }
    
    private func downloadFile(_ file: File) {
        let destURL = localViewModel.currentDirectoryURL.appendingPathComponent(file.name)
        
        Task {
            await transferManager.startSingleFileDownload(
                file: file,
                destinationURL: destURL,
                smbViewModel: smbViewModel
            ) {
                localViewModel.refreshFiles()
            }
        }
    }
    
    private func downloadFolder(_ file: File) {
        let destURL = localViewModel.currentDirectoryURL.appendingPathComponent(file.name)
        
        Task {
            await transferManager.startFolderDownload(
                folder: file,
                destination: destURL,
                smbViewModel: smbViewModel
            ) {
                localViewModel.refreshFiles()
            }
        }
    }
    
    private func deleteFile(_ file: File) {
        Task {
            do {
                try await smbViewModel.deleteItem(name: file.name, isDirectory: smbViewModel.isDirectory(file))
            } catch {
                print("Delete error: \(error)")
            }
        }
    }
}
