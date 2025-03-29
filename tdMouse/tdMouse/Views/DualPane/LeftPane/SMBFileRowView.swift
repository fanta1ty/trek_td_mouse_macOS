//
//  SMBFileRowView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI
import SMBClient

struct SMBFileRowView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    let file: File
    @State private var isHovering = false
    
    private var fileColor: Color {
        if viewModel.isDirectory(file) {
            return .accentColor
        } else {
            let ext = file.name.components(separatedBy: ".").last?.lowercased() ?? ""
            switch ext {
            case "pdf":
                return .red
            case "jpg", "jpeg", "png", "gif", "heic":
                return .green
            case "mp3", "wav", "m4a":
                return .pink
            case "mp4", "mov", "avi":
                return .purple
            case "doc", "docx":
                return .blue
            case "xls", "xlsx":
                return .green
            case "ppt", "pptx":
                return .orange
            case "zip", "rar", "7z":
                return .gray
            default:
                return .secondary
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // File icon with improved visual style
            ZStack {
                // Background shape
                RoundedRectangle(cornerRadius: 6)
                    .fill(fileColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                // Icon
                Image(systemName: viewModel.isDirectory(file)
                      ? "folder.fill"
                      : Helpers.iconForFile(file.name))
                    .font(.system(size: 16))
                    .foregroundStyle(fileColor)
            }
            .padding(.leading, 2)
            
            // Filename and details
            VStack(alignment: .leading, spacing: 3) {
                Text(file.name)
                    .font(.system(size: 14))
                    .fontWeight(viewModel.isDirectory(file) ? .medium : .regular)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // Date information
                    Label {
                        Text(Helpers.formatDate(file.lastWriteTime))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                    
                    // Size information (for files only)
                    if !viewModel.isDirectory(file) {
                        Label {
                            Text(Helpers.formatFileSize(file.size))
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Quick actions that appear on hover
            if isHovering {
                HStack(spacing: 12) {
                    if !viewModel.isDirectory(file) {
                        // Download button for files
                        Button {
                            NotificationCenter.default.post(
                                name: Notification.Name("DownloadSMBFile"),
                                object: file
                            )
                        } label: {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Download")
                        
                        // Preview button for compatible files
                        if Helpers.isPreviewableFileType(file.name) {
                            Button {
                                NotificationCenter.default.post(
                                    name: Notification.Name("PreviewSMBFile"),
                                    object: file
                                )
                            } label: {
                                Image(systemName: "eye")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Preview")
                        }
                    } else {
                        // Open button for folders
                        Button {
                            Task {
                                try await viewModel.navigateToDirectory(file.name)
                            }
                        } label: {
                            Image(systemName: "folder.badge.arrow.right")
                                .font(.system(size: 18))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Open Folder")
                    }
                }
                .padding(.trailing, 4)
                .transition(.opacity)
            }
        }
        .frame(height: 44)
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? (colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}
