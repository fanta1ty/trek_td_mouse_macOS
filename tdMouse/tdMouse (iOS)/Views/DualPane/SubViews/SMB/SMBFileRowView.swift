//
//  SmbFileRowView.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI
import SMBClient

struct SMBFileRowView: View {
    let file: File
    @ObservedObject var viewModel: FileTransferViewModel
    
    var body: some View {
        HStack {
            // Icon based on file type
            Image(systemName: viewModel.isDirectory(file) ? "folder" : getFileIcon(fileName: file.name))
                .foregroundColor(viewModel.isDirectory(file) ? .blue : .gray)
                .frame(width: 30)
            
            // File name and details
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .fontWeight(viewModel.isDirectory(file) ? .medium : .regular)
                
                HStack(spacing: 8) {
                    Text(formatDate(file.creationTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !viewModel.isDirectory(file) {
                        Text(formatFileSize(file.size))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Quick action buttons (download/preview)
            if !viewModel.isDirectory(file) {
                if Helpers.isPreviewableFileType(file.name) {
                    Button {
                        // Preview file
                        NotificationCenter.default.post(
                            name: Notification.Name("PreviewSMBFile"),
                            object: file
                        )
                    } label: {
                        Image(systemName: "eye")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 4)
                }
                
                Button {
                    // Download file
                    NotificationCenter.default.post(
                        name: Notification.Name("DownloadSMBFile"),
                        object: file
                    )
                } label: {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ size: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    private func getFileIcon(fileName: String) -> String {
        let fileExtension = fileName.components(separatedBy: ".").last?.lowercased() ?? ""
        
        switch fileExtension {
        case "pdf":
            return "doc.text"
        case "jpg", "jpeg", "png", "gif", "heic", "webp":
            return "photo"
        case "mp4", "mov", "avi":
            return "film"
        case "mp3", "wav", "m4a", "aac":
            return "music.note"
        case "doc", "docx":
            return "doc.richtext"
        case "xls", "xlsx":
            return "chart.bar.doc.horizontal"
        case "ppt", "pptx":
            return "chart.bar.doc.horizontal"
        case "zip", "rar", "7z":
            return "doc.zipper"
        default:
            return "doc"
        }
    }
}
