//
//  FileActionSheet.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI
import SMBClient
import AppKit

struct FileActionSheet: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @Binding var isPresented: Bool
    @State private var isDownloading = false
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPreview = false
    
    let file: File
    let transferManager: TransferManager
    let localViewModel: LocalFileViewModel
    
    // Determine file type for icon
    private var fileIcon: String {
        if viewModel.isDirectory(file) {
            return "folder.fill"
        } else {
            // Select appropriate icon based on file extension
            let ext = file.name.components(separatedBy: ".").last?.lowercased() ?? ""
            switch ext {
            case "pdf":
                return "doc.fill"
            case "jpg", "jpeg", "png", "gif":
                return "photo.fill"
            case "mp3", "wav", "m4a":
                return "music.note"
            case "mp4", "mov", "avi":
                return "film.fill"
            case "doc", "docx":
                return "doc.text.fill"
            case "xls", "xlsx":
                return "chart.bar.doc.horizontal.fill"
            case "ppt", "pptx":
                return "chart.bar.doc.horizontal.fill"
            case "zip", "rar", "7z":
                return "archivebox.fill"
            default:
                return "doc.fill"
            }
        }
    }
    
    // File color based on type
    private var fileColor: Color {
        if viewModel.isDirectory(file) {
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
    
    // Check if the file type is previewable
    private var isPreviewable: Bool {
        if viewModel.isDirectory(file) {
            return false
        }
        
        return Helpers.isPreviewableFileType(file.name)
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
                if viewModel.isDirectory(file) {
                    // Directory actions
                    Button(action: {
                        Task {
                            do {
                                try await viewModel.navigateToDirectory(file.name)
                                isPresented = false
                            } catch {
                                errorMessage = "Failed to open folder: \(error.localizedDescription)"
                                showError = true
                            }
                        }
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
                        downloadFolder()
                    }) {
                        Label {
                            Text("Download Folder")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } icon: {
                            if isDownloading {
                                ProgressView()
                                    .frame(width: 24)
                            } else {
                                Image(systemName: "arrow.down.circle")
                                    .frame(width: 24)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(isDownloading)
                } else {
                    // File actions
                    Button(action: {
                        downloadFile(file)
                    }) {
                        Label {
                            Text("Download File")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } icon: {
                            if isDownloading {
                                ProgressView()
                                    .frame(width: 24)
                            } else {
                                Image(systemName: "arrow.down.circle")
                                    .frame(width: 24)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isDownloading)
                    
                    if isPreviewable {
                        Button(action: {
                            previewFile()
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
            if !viewModel.isDirectory(file) {
                UniversalFilePreviewView(
                    title: file.name,
                    fileProvider: {
                        return try await viewModel.downloadFile(fileName: file.name)
                    },
                    fileExtension: file.name.components(separatedBy: ".").last ?? ""
                )
            }
        }
    }
    
    private func downloadFile(_ file: File) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = file.name
        panel.canCreateDirectories = true
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task {
                    do {
                        await MainActor.run {
                            isDownloading = true
                        }
                        
                        let data = try await viewModel.downloadFile(fileName: file.name)
                        try data.write(to: url)
                        
                        await MainActor.run {
                            isDownloading = false
                            isPresented = false
                        }
                    } catch {
                        await MainActor.run {
                            isDownloading = false
                            errorMessage = "Download failed: \(error.localizedDescription)"
                            showError = true
                        }
                        print("Download error: \(error)")
                    }
                }
            }
        }
    }
    
    private func downloadFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Choose Download Location"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task {
                    do {
                        await MainActor.run {
                            isDownloading = true
                        }
                        
                        // Create destination URL for the folder
                        let destinationURL = url.appendingPathComponent(file.name)
                        
                        // Start folder download using the TransferManager
                        await transferManager.startFolderDownload(
                            folder: file,
                            destination: destinationURL,
                            smbViewModel: viewModel
                        ) {
                            // This will be called when the download completes
                            localViewModel.refreshFiles()
                        }
                        
                        await MainActor.run {
                            isDownloading = false
                            isPresented = false
                        }
                    } catch {
                        await MainActor.run {
                            isDownloading = false
                            errorMessage = "Download failed: \(error.localizedDescription)"
                            showError = true
                        }
                    }
                }
            }
        }
    }
    
    private func previewFile() {
        // Show the preview sheet
        if isPreviewable {
            showPreview = true
        } else {
            errorMessage = "This file type cannot be previewed"
            showError = true
        }
    }
    
    private func deleteFile() {
        Task {
            do {
                await MainActor.run {
                    isDeleting = true
                }
                
                try await viewModel.deleteItem(
                    name: file.name,
                    isDirectory: viewModel.isDirectory(file)
                )
                
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
                print("Delete error: \(error)")
            }
        }
    }
}
