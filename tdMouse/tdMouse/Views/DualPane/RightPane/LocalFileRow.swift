//
//  LocalFileRow.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI

struct LocalFileRow: View {
    @ObservedObject var viewModel: LocalFileViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    let file: LocalFile
    let onTap: (LocalFile) -> Void
    
    @State private var isHovering = false
    @State private var showPreview = false
    @State private var showActionSheet = false
    
    // File type-based color
    private var fileColor: Color {
        if file.isDirectory {
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
            // File icon with modern styling
            ZStack {
                // Background shape
                RoundedRectangle(cornerRadius: 6)
                    .fill(fileColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                // Icon
                Image(systemName: file.icon)
                    .font(.system(size: 16))
                    .foregroundColor(fileColor)
            }
            .padding(.leading, 2)
            
            // File name and details
            VStack(alignment: .leading, spacing: 3) {
                Text(file.name)
                    .font(.system(size: 14))
                    .fontWeight(file.isDirectory ? .medium : .regular)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    if let date = file.modificationDate {
                        Label {
                            Text(formatDate(date))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "calendar")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    if !file.isDirectory {
                        Label {
                            Text(viewModel.formatFileSize(file.size))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "arrow.up.doc")
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
                    if !file.isDirectory {
                        // Upload button for files
                        Button {
                            NotificationCenter.default.post(
                                name: Notification.Name("UploadLocalFile"),
                                object: file
                            )
                        } label: {
                            Image(systemName: "arrow.up.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Upload to Server")
                        
                        // Preview button for compatible files
                        if isPreviewableFileType(file.name) {
                            Button {
                                showPreview = true
                            } label: {
                                Image(systemName: "eye")
                                    .font(.system(size: 18))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Preview File")
                        }
                    } else {
                        // Upload folder button
                        Button {
                            NotificationCenter.default.post(
                                name: Notification.Name("UploadLocalFolder"),
                                object: file
                            )
                        } label: {
                            Image(systemName: "arrow.up.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Upload Folder")
                        
                        // Open button for folders
                        Button {
                            onTap(file)
                        } label: {
                            Image(systemName: "folder.badge.arrow.right")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Open Folder")
                    }
                    
                    // More actions button
                    Button {
                        showActionSheet = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("More Actions")
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
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onTap(file)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
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
        .sheet(isPresented: $showPreview) {
            // Preview file in sheet
            if !file.isDirectory {
                UniversalFilePreviewView(
                    title: file.name,
                    fileProvider: {
                        return try Data(contentsOf: file.url)
                    },
                    fileExtension: file.name.components(separatedBy: ".").last ?? ""
                )
            }
        }
        .sheet(isPresented: $showActionSheet) {
            // File action sheet with comprehensive options
            LocalFileActionSheet(
                viewModel: viewModel,
                isPresented: $showActionSheet,
                file: file,
                onTap: onTap
            )
        }
    }
    
    @ViewBuilder
    private func fileContextMenu() -> some View {
        Group {
            if file.isDirectory {
                Button {
                    onTap(file)
                } label: {
                    Label("Open", systemImage: "folder")
                }
                
                Button {
                    NotificationCenter.default.post(
                        name: Notification.Name("UploadLocalFolder"),
                        object: file
                    )
                } label: {
                    Label("Upload Folder to Server", systemImage: "arrow.up.doc")
                }
            } else {
                Button {
                    NotificationCenter.default.post(
                        name: Notification.Name("UploadLocalFile"),
                        object: file
                    )
                } label: {
                    Label("Upload to Server", systemImage: "arrow.up")
                }
                
                if isPreviewableFileType(file.name) {
                    Button {
                        showPreview = true
                    } label: {
                        Label("Preview", systemImage: "eye")
                    }
                }
            }
            
            Divider()
            
            Button(role: .destructive) {
                viewModel.deleteFile(file)
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
    
    // Helper date formatter
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper function to check previewable file types
    private func isPreviewableFileType(_ fileName: String) -> Bool {
        let fileExtension = fileName.components(separatedBy: ".").last?.lowercased() ?? ""
        
        // Common previewable file types
        let previewableExtensions = [
            // Images
            "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic",
            
            // Documents
            "pdf", "txt", "rtf", "md", "csv", "json", "xml",
            
            // Media
            "mp3", "wav", "m4a", "mp4", "mov", "avi", "m4v",
            
            // Web
            "html", "htm", "xhtml",
            
            // Code
            "swift", "js", "py", "css", "java", "c", "cpp", "h"
        ]
        
        return previewableExtensions.contains(fileExtension)
    }
}

struct LocalFileRow_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            LocalFileRow(
                viewModel: LocalFileViewModel(),
                file: .init(
                    name: "Presentation.pdf",
                    url: .homeDirectory,
                    isDirectory: false,
                    size: 1024 * 1024,
                    modificationDate: Date()
                ),
                onTap: { _ in }
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.light)
            
            LocalFileRow(
                viewModel: LocalFileViewModel(),
                file: .init(
                    name: "Documents",
                    url: .homeDirectory,
                    isDirectory: true,
                    size: 0,
                    modificationDate: Date()
                ),
                onTap: { _ in }
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.dark)
        }
    }
}
