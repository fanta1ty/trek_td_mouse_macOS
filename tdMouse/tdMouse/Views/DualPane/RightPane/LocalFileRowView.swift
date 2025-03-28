//
//  LocalFileRowView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI
import Combine

struct LocalFileRowView: View {
    @ObservedObject var viewModel: LocalFileViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    let file: LocalFile
    @State private var isHovering = false
    
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
            // Enhanced file icon with background
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(fileColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: file.icon)
                    .font(.system(size: 16))
                    .foregroundColor(fileColor)
            }
            
            // Filename and details with improved typography
            VStack(alignment: .leading, spacing: 3) {
                Text(file.name)
                    .font(.system(size: 14))
                    .fontWeight(file.isDirectory ? .medium : .regular)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let date = file.modificationDate {
                        Label {
                            Text(Helpers.formatDate(date))
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
                            Text(Helpers.formatFileSize(UInt64(file.size)))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "doc.size")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Enhanced action buttons
            HStack(spacing: 8) {
                if !file.isDirectory {
                    Button(action: {
                        NotificationCenter.default.post(
                            name: Notification.Name("UploadLocalFile"),
                            object: file
                        )
                    }) {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 16))
                            .foregroundColor(isHovering ? .accentColor : .secondary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Upload to Server")
                    
                    // Only show preview button when hovering
                    if isHovering && isPreviewableFileType(file.name) {
                        Button(action: {
                            NotificationCenter.default.post(
                                name: Notification.Name("PreviewLocalFile"),
                                object: file
                            )
                        }) {
                            Image(systemName: "eye")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Preview File")
                        .transition(.opacity)
                    }
                } else if isHovering {
                    // Upload folder button
                    Button(action: {
                        NotificationCenter.default.post(
                            name: Notification.Name("UploadLocalFolder"),
                            object: file
                        )
                    }) {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("Upload Folder")
                    .transition(.opacity)
                }
            }
            .padding(.trailing, 4)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
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
    
    // Helper function to determine if a file type is previewable
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

struct LocalFileRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LocalFileRowView(
                viewModel: LocalFileViewModel(),
                file: .init(
                    name: "Document.pdf",
                    url: .homeDirectory,
                    isDirectory: false,
                    size: 1024 * 1024,
                    modificationDate: Date()
                )
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.light)
            
            LocalFileRowView(
                viewModel: LocalFileViewModel(),
                file: .init(
                    name: "Images",
                    url: .homeDirectory,
                    isDirectory: true,
                    size: 0,
                    modificationDate: Date()
                )
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.dark)
        }
    }
}
