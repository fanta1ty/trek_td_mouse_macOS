//
//  LocalFilesBrowserSection.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct LocalFilesBrowserSection: View {
    @EnvironmentObject var localViewModel: LocalFileViewModel
    @EnvironmentObject var smbViewModel: FileTransferViewModel
    @EnvironmentObject var transferManager: TransferManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Local Files")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    localViewModel.navigateUp()
                }) {
                    Image(systemName: "arrow.up")
                }
                .disabled(!localViewModel.canNavigateUp)
                
                Button(action: {
                    localViewModel.refreshFiles()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                
                Button(action: {
                    localViewModel.selectDirectory()
                }) {
                    Image(systemName: "folder.badge.plus")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Path indicator
            LocalPathIndicator(viewModel: localViewModel)
            
            // File list or placeholder
            if localViewModel.isLoading {
                ProgressView("Loading files...")
            } else if localViewModel.files.isEmpty {
                EmptyFolderView(type: .local)
            } else {
                LocalFileList()
            }
        }
        .background(Color(UIColor.systemBackground))
        .onDrop(of: [UTType.plainText.identifier], isTargeted: nil) { providers in
            self.handleDrop(providers: providers)
            return true
        }
    }
    
    // Drop handling directly in the view
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { (data, error) in
                guard error == nil else { return }
                
                if let data = data as? Data, let string = String(data: data, encoding: .utf8) {
                    self.handleDroppedText(string)
                } else if let string = data as? String {
                    self.handleDroppedText(string)
                }
            }
        }
        
        return true
    }
    
    private func handleDroppedText(_ text: String) {
        // Try to parse the JSON data for SMB file information
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
           let type = json["type"], type == "smbFile",
           let name = json["name"],
           let isDirectoryStr = json["isDirectory"] {
            
            let isDirectory = isDirectoryStr == "true"
            
            // Make sure we have a valid SMB file
            if let file = smbViewModel.getFileByName(name) {
                let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(name)
                
                Task {
                    if isDirectory {
                        // Start folder download
                        await self.transferManager.startFolderDownload(
                            folder: file,
                            destination: localURL,
                            smbViewModel: smbViewModel
                        ) {
                            localViewModel.refreshFiles()
                        }
                    } else {
                        // Start file download
                        await self.transferManager.startSingleFileDownload(
                            file: file,
                            destinationURL: localURL,
                            smbViewModel: smbViewModel
                        ) {
                            localViewModel.refreshFiles()
                        }
                    }
                }
            }
        }
    }
}
