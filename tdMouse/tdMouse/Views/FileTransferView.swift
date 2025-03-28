//
//  FileTransferView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI
import Combine
import SMBClient

struct FileTransferView: View {
    @StateObject private var viewModel: FileTransferViewModel = .init()
    @StateObject private var localViewModel: LocalFileViewModel = .init()
    
    @State private var isConnectSheetPresented = false
    @State private var isCreateFolderSheetPresented = false
    @State private var isImportFilePickerPresented = false
    @State private var isTransferSummaryPresented = false
    @State private var newFolderName = ""
    
    // Notification observers for menu commands
    private let connectObserver = FileNotificationCenter.shared.openConnectDialogPublisher()
    private let uploadObserver = FileNotificationCenter.shared.openUploadDialogPublisher()
    private let newFolderObserver = FileNotificationCenter.shared.openNewFolderDialogPublisher()
    private let refreshObserver = FileNotificationCenter.shared.refreshFileListPublisher()
    
    var body: some View {
        NavigationView {
            // Sidebar with shares
            ServerSidebarView(viewModel: viewModel)
            
            // Main content with file listing
            if viewModel.connectionState == .connected {
                FileListContainerView(
                    viewModel: viewModel,
                    localViewModel: localViewModel
                )
            } else {
                DisconnectedPlaceholderView {
                    isConnectSheetPresented.toggle()
                }
            }
        }
        .navigationTitle("TD Mouse")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    isConnectSheetPresented.toggle()
                }, label: {
                    if viewModel.connectionState == .connected {
                        Label("Disconnect", systemImage: "network.slash")
                    } else {
                        Label("Connect", systemImage: "network")
                    }
                })
            }
            
            if viewModel.connectionState == .connected && !viewModel.shareName.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        isCreateFolderSheetPresented.toggle()
                    }) {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        isImportFilePickerPresented.toggle()
                    }) {
                        Label("Upload", systemImage: "arrow.up.doc")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Task {
                            try await viewModel.listFiles(viewModel.currentDirectory)
                        }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .sheet(isPresented: $isConnectSheetPresented) {
            ConnectionSheet(viewModel: viewModel, isPresented: $isConnectSheetPresented)
        }
        .sheet(isPresented: $isCreateFolderSheetPresented, content: {
            CreateFolderSheet(
                viewModel: viewModel,
                isPresented: $isCreateFolderSheetPresented,
                folderName: $newFolderName
            )
        })
        .fileImporter(
            isPresented: $isImportFilePickerPresented,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false,
            onCompletion: { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task {
                            do {
                                try await viewModel.uploadLocalFile(url: url)
                            } catch {
                                print("Upload error: \(error)")
                            }
                        }
                    }
                    
                case .failure(let error):
                    print("File picker error: \(error)")
                }
            })
        .alert("Error", isPresented: .init(
            get: { !viewModel.errorMessage.isEmpty },
            set: { if !$0 {
                viewModel.errorMessage = ""
            }
            }), actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(viewModel.errorMessage)
            })
        .sheet(isPresented: $viewModel.showTransferSummary, content: {
            if let stats = viewModel.lastTransferStats {
                TransferSummaryView(
                    isPresented: $viewModel.showTransferSummary,
                    stats: stats
                )
            }
        })
        .onReceive(connectObserver) { _ in
            isConnectSheetPresented = true
        }
        .onReceive(uploadObserver, perform: { _ in
            if viewModel.connectionState == .connected && !viewModel.shareName.isEmpty {
                isImportFilePickerPresented = true
            }
        })
        .onReceive(newFolderObserver, perform: { _ in
            if viewModel.connectionState == .connected && !viewModel.shareName.isEmpty {
                isCreateFolderSheetPresented = true
            }
        })
        .onReceive(refreshObserver) { _ in
            if viewModel.connectionState == .connected && !viewModel.shareName.isEmpty {
                Task {
                    try await viewModel.listFiles(viewModel.currentDirectory)
                }
            }
        }
    }
}

struct FileTransferView_Previews: PreviewProvider {
    static var previews: some View {
        FileTransferView()
    }
}
