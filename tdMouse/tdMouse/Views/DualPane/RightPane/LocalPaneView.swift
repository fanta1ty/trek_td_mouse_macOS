//
//  LocalPaneView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI
import UniformTypeIdentifiers
import SMBClient

struct LocalPaneView: View {
    @ObservedObject var viewModel: LocalFileViewModel
    @ObservedObject var transferManager: TransferManager
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var showDirectoryPicker = false
    
    let onFileTap: (LocalFile) -> Void
    let onFolderUpload: (LocalFile) -> Void
    let onSmbFileDrop: (NSItemProvider) -> Void
    
    private var filteredFiles: [LocalFile] {
        if searchText.isEmpty {
            return viewModel.files
        } else {
            return viewModel.files.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern header with status and controls
            LocalPaneHeader(viewModel: viewModel)
            
            // Modern breadcrumb path bar
            LocalBreadcrumbPathView(viewModel: viewModel)
            
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
            
            // File list with enhanced styling
            if viewModel.isLoading {
                LoadingView()
            } else if filteredFiles.isEmpty {
                EmptyFolderView(isSearching: isSearching, searchText: searchText)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredFiles, id: \.id) { file in
                            LocalFileRow(
                                viewModel: viewModel,
                                file: file,
                                onTap: onFileTap
                            )
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
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
                
                Button(action: { showDirectoryPicker = true }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.green)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .buttonStyle(.plain)
                .help("Select Directory")
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .onDrop(of: [UTType.plainText.identifier], isTargeted: nil) { providers -> Bool in
            for provider in providers {
                onSmbFileDrop(provider)
            }
            return true
        }
        .onChange(of: showDirectoryPicker) { isShowing in
            if isShowing {
                viewModel.selectDirectory()
                showDirectoryPicker = false
            }
        }
    }
}

// MARK: - Supporting Components

struct LocalPaneHeader: View {
    @ObservedObject var viewModel: LocalFileViewModel
    
    var body: some View {
        HStack {
            // Local files label with icon
            Label {
                Text("Local Files")
                    .font(.headline)
            } icon: {
                Image(systemName: "folder.fill")
                    .foregroundColor(.accentColor)
            }
            .padding(.leading, 4)
            
            Spacer()
            
            // Navigation controls
            Button(action: {
                viewModel.navigateUp()
            }) {
                Image(systemName: "arrow.up")
                    .foregroundColor(viewModel.canNavigateUp ? .blue : .gray)
            }
            .disabled(!viewModel.canNavigateUp)
            .buttonStyle(.plain)
            .help("Navigate Up")
            
            Button(action: {
                viewModel.refreshFiles()
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("Refresh")
            
            Button(action: {
                viewModel.selectDirectory()
            }) {
                Image(systemName: "folder.badge.plus")
            }
            .buttonStyle(.plain)
            .help("Select Directory")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Color(NSColor.controlBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        )
    }
}

struct LocalBreadcrumbPathView: View {
    @ObservedObject var viewModel: LocalFileViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                let pathComponents = viewModel.currentDirectoryURL.pathComponents
                
                ForEach(0..<pathComponents.count, id: \.self) { index in
                    let component = pathComponents[index]
                    
                    // Skip empty components
                    if !component.isEmpty {
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        // Create a path URL up to this component
                        let subPath = pathComponents[0...index].joined(separator: "/")
                        let subPathURL = URL(fileURLWithPath: subPath)
                        
                        Button(action: {
                            viewModel.navigateToURL(subPathURL)
                        }) {
                            HStack(spacing: 4) {
                                // Choose appropriate icon
                                if component == "/" {
                                    Image(systemName: "macwindow")
                                        .font(.system(size: 10))
                                } else if index == 0 {
                                    Image(systemName: "externaldrive.fill")
                                        .font(.system(size: 10))
                                } else {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 10))
                                }
                                
                                Text(component == "/" ? "Root" : component)
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                index == pathComponents.count - 1 ?
                                    Color.blue.opacity(0.15) :
                                    Color.secondary.opacity(0.1)
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color(NSColor.textBackgroundColor))
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .padding(.bottom, 8)
            
            Text("Loading Files...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyFolderView: View {
    let isSearching: Bool
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            if isSearching {
                // No search results state
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("No files match '\(searchText)'")
                    .font(.title3)
            } else {
                // Empty folder state
                Image(systemName: "folder.badge.minus")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("This folder is empty")
                    .font(.title3)
                
                Text("Add files or select another directory")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LocalPaneView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LocalPaneView(
                viewModel: LocalFileViewModel(),
                transferManager: TransferManager(),
                onFileTap: { _ in },
                onFolderUpload: { _ in },
                onSmbFileDrop: { _ in false }
            )
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
            
            LocalPaneView(
                viewModel: LocalFileViewModel(),
                transferManager: TransferManager(),
                onFileTap: { _ in },
                onFolderUpload: { _ in },
                onSmbFileDrop: { _ in false }
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
