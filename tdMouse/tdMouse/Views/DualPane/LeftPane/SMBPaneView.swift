//
//  SMBPaneView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI
import SMBClient
import UniformTypeIdentifiers

struct SMBPaneView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var showsFilterOptions = false
    
    let onFileTap: (File) -> Void
    let onLocalFileDrop: (NSItemProvider) -> Void
    
    private var filteredFiles: [File] {
        let files = viewModel.files.filter { $0.name != "." && $0.name != ".." }
        
        if searchText.isEmpty {
            return files
        } else {
            return files.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with enhanced controls
            SMBPaneHeader(viewModel: viewModel)
            
            if viewModel.connectionState == .connected {
                // Modern breadcrumb path bar
                BreadcrumbPathView(viewModel: viewModel)
                
                // Search bar (appears when isSearching is true)
                if isSearching {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search files...", text: $searchText)
                            .textFieldStyle(.plain)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                }
                
                // File list with modern styling
                if filteredFiles.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        if searchText.isEmpty {
                            // Empty folder state
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("This folder is empty")
                                .font(.title3)
                        } else {
                            // No search results state
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No files match '\(searchText)'")
                                .font(.title3)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(filteredFiles, id: \.name) { file in
                                SMBFileRow(viewModel: viewModel, file: file, onFileTap: onFileTap)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                // Enhanced not-connected placeholder
                ConnectionPlaceholder()
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if viewModel.connectionState == .connected {
                // Floating action buttons
                VStack(spacing: 12) {
                    if isSearching {
                        Button(action: { isSearching = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.gray)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .buttonStyle(.plain)
                        .help("Cancel Search")
                    } else {
                        Button(action: { isSearching = true }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .buttonStyle(.plain)
                        .help("Search Files")
                    }
                    
                    Button(action: {
                        NotificationCenter.default.post(name: Notification.Name("CreateSMBFolder"), object: nil)
                    }) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.green)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .buttonStyle(.plain)
                    .help("Create New Folder")
                }
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .onDrop(of: [UTType.plainText.identifier], isTargeted: nil) { providers -> Bool in
            for provider in providers {
                onLocalFileDrop(provider)
            }
            return true
        }
        .toolbar {
            if viewModel.connectionState == .connected {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Task {
                            try await viewModel.refreshCurrentDirectory()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh")
                }
            }
        }
    }
}

extension FileTransferViewModel {
    func refreshCurrentDirectory() async throws {
        try await listFiles(currentDirectory)
    }
}
