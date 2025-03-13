//
//  FileRowView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI
import SMBClient

struct FileRowView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    let file: File
    
    var body: some View {
        HStack {
            if viewModel.isDirectory(file) {
                Image(systemName: "folder")
                    .foregroundStyle(Color.accentColor)
            } else {
                Image(systemName: fileIcon(for: file.name))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading) {
                Text(file.name)
                    .fontWeight(viewModel.isDirectory(file) ? .medium : .regular)
                
                HStack {
                    Text(formatDate(file.lastWriteTime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if !viewModel.isDirectory(file) {
                        Text(viewModel.formatFileSize(file.size))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button {
                FileNotificationCenter.shared.postFileSelected(file)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Functions
    private func fileIcon(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        
        switch ext {
        case "pdf":
            return "doc.text"
        case "jpg", "jpeg", "png", "gif", "tiff", "bmp":
            return "photo"
        case "mp3", "wav", "aac", "m4a":
            return "music.note"
        case "mp4", "mov", "avi", "mkv":
            return "film"
        case "doc", "docx":
            return "doc.text"
        case "xls", "xlsx":
            return "chart.bar.doc.horizontal"
        case "ppt", "pptx":
            return "chart.bar.doc.horizontal"
        case "zip", "rar", "7z", "tar", "gz":
            return "archivebox"
        case "txt", "rtf":
            return "doc.text"
        default:
            return "doc"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
