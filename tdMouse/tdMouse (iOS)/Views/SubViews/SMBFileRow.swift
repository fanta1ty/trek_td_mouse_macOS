//
//  SMBFileRow.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI
import SMBClient

struct SMBFileRow: View {
    @EnvironmentObject var smbViewModel: FileTransferViewModel
    let file: File
    
    var body: some View {
        HStack(spacing: 12) {
            // File icon
            Image(systemName: smbViewModel.isDirectory(file) ? "folder.fill" : Helpers.iconForFile(file.name))
                .foregroundColor(smbViewModel.isDirectory(file) ? .blue : iconColor(for: file.name))
                .font(.system(size: 22))
                .frame(width: 30)
            
            // File details
            VStack(alignment: .leading, spacing: 3) {
                Text(file.name)
                    .font(.subheadline)
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    Text(Helpers.formatDate(file.lastWriteTime))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if !smbViewModel.isDirectory(file) {
                        Text(Helpers.formatFileSize(file.size))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            if smbViewModel.isDirectory(file) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else if Helpers.isPreviewableFileType(file.name) {
                Button(action: {
                    previewFile()
                }) {
                    Image(systemName: "eye")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconColor(for fileName: String) -> Color {
        let ext = fileName.components(separatedBy: ".").last?.lowercased() ?? ""
        switch ext {
        case "pdf": return .red
        case "jpg", "jpeg", "png", "gif": return .green
        case "mp3", "wav", "m4a": return .pink
        case "mp4", "mov", "avi": return .purple
        default: return .gray
        }
    }
    
    private func previewFile() {
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
}

struct LocalFileRow: View {
    let file: LocalFile
    
    var body: some View {
        HStack(spacing: 12) {
            // File icon
            Image(systemName: file.icon)
                .foregroundColor(file.isDirectory ? .blue : iconColor(for: file.name))
                .font(.system(size: 22))
                .frame(width: 30)
            
            // File details
            VStack(alignment: .leading, spacing: 3) {
                Text(file.name)
                    .font(.subheadline)
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    if let date = file.modificationDate {
                        Text(Helpers.formatDate(date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if !file.isDirectory {
                        Text(Helpers.formatFileSize(UInt64(file.size)))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            if file.isDirectory {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else if file.isPreviewable {
                Button(action: {
                    previewFile()
                }) {
                    Image(systemName: "eye")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconColor(for fileName: String) -> Color {
        let ext = fileName.components(separatedBy: ".").last?.lowercased() ?? ""
        switch ext {
        case "pdf": return .red
        case "jpg", "jpeg", "png", "gif": return .green
        case "mp3", "wav", "m4a": return .pink
        case "mp4", "mov", "avi": return .purple
        default: return .gray
        }
    }
    
    private func previewFile() {
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
}
