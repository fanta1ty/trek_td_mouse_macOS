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
    
    let onFileTap: (LocalFile) -> Void
    let onFolderUpload: (LocalFile) -> Void
    let onSmbFileDrop: (NSItemProvider) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Local Files")
                    .font(.headline)
                    .padding(.leading)
                
                Spacer()
                
                Button(action: {
                    viewModel.navigateUp()
                }) {
                    Image(systemName: "arrow.up")
                }
                .disabled(!viewModel.canNavigateUp)
                .padding(.trailing)
                
                Button(action: {
                    viewModel.refreshFiles()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .padding(.trailing)
            }
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Path bar
            HStack {
                Text(viewModel.currentDirectoryURL.path)
                    .truncationMode(.middle)
                    .lineLimit(1)
                    .font(.caption)
                    .padding(.horizontal)
            }
            .frame(height: 24)
            .background(Color(NSColor.textBackgroundColor))
            
            // File list
            if viewModel.isLoading {
                ProgressView("Loading files...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.files.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "doc.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Files")
                        .font(.title2)
                    Text("This folder is empty")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.files, id: \.id) { file in
                        LocalFileRow(
                            viewModel: viewModel,
                            file: file,
                            onTap: onFileTap
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .onDrop(of: [UTType.plainText.identifier], isTargeted: nil) { providers -> Bool in
            for provider in providers {
                onSmbFileDrop(provider)
            }
            return true
        }
    }
}

struct LocalPaneView_Previews: PreviewProvider {
    static var previews: some View {
        LocalPaneView(
            viewModel: LocalFileViewModel(),
            transferManager: TransferManager(),
            onFileTap: { _ in },
            onFolderUpload: { _ in },
            onSmbFileDrop: { _ in }
        )
    }
}
