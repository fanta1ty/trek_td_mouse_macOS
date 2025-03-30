//
//  SMBBrowserSection.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI
import SMBClient
import UniformTypeIdentifiers

struct SMBBrowserSection: View {
    @EnvironmentObject var smbViewModel: FileTransferViewModel
    @EnvironmentObject var transferManager: TransferManager
    @State private var selectedFile: File?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("SMB Server")
                    .font(.headline)
                
                Spacer()
                
                if smbViewModel.connectionState == .connected {
                    Button(action: {
                        Task {
                            try await smbViewModel.navigateUp()
                        }
                    }) {
                        Image(systemName: "arrow.up")
                    }
                    .disabled(smbViewModel.currentDirectory.isEmpty)
                    
                    Button(action: {
                        Task {
                            try await smbViewModel.refreshCurrentDirectory()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Path indicator
            if smbViewModel.connectionState == .connected {
                SMBPathIndicator(viewModel: smbViewModel)
            }
            
            // File list or placeholder
            if smbViewModel.connectionState != .connected {
                SMBPlaceholderView()
            } else if smbViewModel.files.isEmpty {
                EmptyFolderView(type: .smb)
            } else {
                SMBFileList()
            }
        }
        .background(Color(UIColor.systemBackground))
        .onDrop(of: [UTType.plainText.identifier], isTargeted: nil) { providers in
            self.handleDrop(providers: providers)
            return true
        }
    }
    
    // Move the drop handling directly into the view
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard smbViewModel.connectionState == .connected else { return false }
        
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
        // Try to parse the JSON data
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
           let type = json["type"], type == "localFile",
           let path = json["path"] {
            
            let url = URL(fileURLWithPath: path)
            let isDirectory = json["isDirectory"] == "true"
            
            Task {
                let localFile = LocalFile(
                    name: url.lastPathComponent,
                    url: url,
                    isDirectory: isDirectory,
                    size: 0,
                    modificationDate: nil
                )
                
                if isDirectory {
                    await transferManager.startFolderUpload(
                        folder: localFile,
                        smbViewModel: smbViewModel
                    ) {}
                } else {
                    await transferManager.startSingleFileUpload(
                        file: localFile,
                        smbViewModel: smbViewModel
                    ) {}
                }
            }
        }
    }
}
