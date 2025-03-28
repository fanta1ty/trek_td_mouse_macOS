//
//  LocalFileActionSheet.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 28/3/25.
//

import SwiftUI

struct LocalFileActionSheet: View {
    @ObservedObject var viewModel: LocalFileViewModel
    @Binding var isPresented: Bool
    
    let file: LocalFile
    let onTap: (LocalFile) -> Void
    
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPreview = false
    
    // File type for icon
    private var fileIcon: String {
        if file.isDirectory {
            return "folder.fill"
        } else {
            return file.icon
        }
    }
    
    // File color
    private var fileColor: Color {
        if file.isDirectory {
            return .blue
        } else {
            let ext = file.name.components(separatedBy: ".").last?.lowercased() ?? ""
            switch ext {
            case "pdf":
                return .red
            case "jpg", "jpeg", "png", "gif":
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
                return .gray
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with file icon and name
            VStack(spacing: 8) {
                Image(systemName: fileIcon)
                    .font(.system(size: 36))
                    .foregroundColor(fileColor)
                    .padding(.top, 8)
                
                Text(file.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
                .padding(.horizontal)
            
            // Actions section
            VStack(spacing: 12) {
                if file.isDirectory {
                    // Directory actions
                    Button(action: {
                        onTap(file)
                        isPresented = false
                    }) {
                        Label {
                            Text("Open Folder")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } icon: {
                            Image(systemName: "folder")
                                .frame(width: 24)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button(action: {
                        NotificationCenter.default.post(
                            name: Notification.Name("UploadLocalFolder"),
                            object: file
                        )
                        isPresented = false
                    }) {
                        Label {
                            Text("Upload Folder to Server")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } icon: {
                            Image(systemName: "arrow.up.circle")
                                .frame(width: 24)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                } else {
                    // File actions
                    Button(action: {
                        NotificationCenter.default.post(
                            name: Notification.Name("UploadLocalFile"),
                            object: file
                        )
                        isPresented = false
                    }) {
                        Label {
                            Text("Upload to Server")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } icon: {
                            Image(systemName: "arrow.up.circle")
                                .frame(width: 24)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    if isPreviewableFileType(file.name) {
                        Button(action: {
                            showPreview = true
                        }) {
                            Label {
                                Text("Preview File")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } icon: {
                                Image(systemName: "eye")
                                    .frame(width: 24)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
                
                Button(action: {
                    deleteFile()
                }) {
                    Label {
                        Text("Delete")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } icon: {
                        if isDeleting {
                            ProgressView()
                                .frame(width: 24)
                        } else {
                            Image(systemName: "trash")
                                .frame(width: 24)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .foregroundColor(.red)
                .disabled(isDeleting)
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.horizontal)
            
            // Cancel button
            Button("Cancel") {
                isPresented = false
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 8)
            .keyboardShortcut(.cancelAction)
        }
        .frame(width: 320)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showPreview) {
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
    }
    
    private func deleteFile() {
        isDeleting = true
        
        Task {
            do {
                viewModel.deleteFile(file)
                
                // Add a small delay to show the spinner
                try await Task.sleep(nanoseconds: 500_000_000)
                
                await MainActor.run {
                    isDeleting = false
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = "Delete failed: \(error.localizedDescription)"
                    showError = true
                }
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
