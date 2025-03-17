import SwiftUI
import Combine
import UniformTypeIdentifiers
import AppKit
import SMBClient

struct DualPaneFileTransferView: View {
    @ObservedObject private var transferManager = TransferManager()
    @StateObject private var smbViewModel = FileTransferViewModel()
    @StateObject private var localViewModel = LocalFileViewModel()
    @State private var isConnectSheetPresented = false
    @State private var isCreateFolderSheetPresented = false
    @State private var newFolderName = ""
    @State private var isSidebarVisible = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar at the top
            ToolbarView(
                smbViewModel: smbViewModel,
                onConnect: { isConnectSheetPresented.toggle() },
                onRefresh: {
                    Task {
                        try await smbViewModel.listFiles(smbViewModel.currentDirectory)
                    }
                },
                onNewFolder: { isCreateFolderSheetPresented.toggle() }
            )
            
            // Main content with three-pane file browser
            HStack(spacing: 0) {
                // Left sidebar for SMB Shares
                if isSidebarVisible {
                    SharesSidebarView(
                        viewModel: smbViewModel,
                        isConnectSheetPresented: $isConnectSheetPresented
                    )
                    
                    Divider()
                }
                
                // Middle pane - SMB server files
                SMBPaneView(
                    viewModel: smbViewModel,
                    onFileTap: handleSmbFileTap,
                    onLocalFileDrop: handleLocalFilesDropOnSMB
                )
                
                // Divider
                Divider()
                
                // Right pane - Local files
                LocalPaneView(
                    viewModel: localViewModel,
                    transferManager: transferManager,
                    onFileTap: handleLocalFileTap,
                    onFolderUpload: uploadFolder,
                    onSmbFileDrop: handleSmbFilesDropOnLocal
                )
            }
            
            // Status bar
            StatusBarView(
                smbViewModel: smbViewModel,
                localViewModel: localViewModel,
                transferManager: transferManager
            )
        }
        .toolbar(content: {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    isSidebarVisible.toggle()
                }) {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle sidebar")
                .keyboardShortcut("s", modifiers: [.command, .option])
            }
        })
        // Sheets
        .sheet(isPresented: $isConnectSheetPresented) {
            ConnectionSheet(viewModel: smbViewModel, isPresented: $isConnectSheetPresented)
        }
        .sheet(isPresented: $isCreateFolderSheetPresented) {
            CreateFolderSheet(
                viewModel: smbViewModel,
                isPresented: $isCreateFolderSheetPresented,
                folderName: $newFolderName
            )
        }
        .sheet(isPresented: $smbViewModel.showTransferSummary) {
            if let stats = smbViewModel.lastTransferStats {
                TransferSummaryView(
                    isPresented: $smbViewModel.showTransferSummary, stats: stats
                )
            }
        }
        // Alerts
        .alert("TD Mouse Error", isPresented: .init(
            get: { !smbViewModel.errorMessage.isEmpty },
            set: { if !$0 { smbViewModel.errorMessage = "" } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(smbViewModel.errorMessage)
        }
        .alert("Local Error", isPresented: .init(
            get: { !localViewModel.errorMessage.isEmpty },
            set: { if !$0 { localViewModel.errorMessage = "" } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(localViewModel.errorMessage)
        }
        // Setup notification observers
        .onAppear {
             setupNotificationObservers()
             localViewModel.initialize()
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleSmbFileTap(_ file: File) {
        if smbViewModel.isDirectory(file) {
            Task {
                try await smbViewModel.navigateToDirectory(file.name)
            }
        } else {
            downloadFile(file)
        }
    }
    
    private func handleLocalFileTap(_ file: LocalFile) {
        if file.isDirectory {
            localViewModel.navigateToDirectory(file.name)
        } else {
            uploadFile(file)
        }
    }
    
    private func downloadFile(_ file: File) {
        let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(file.name)
        transferManager.startSingleFileDownload(
            file: file,
            destinationURL: localURL,
            smbViewModel: smbViewModel
        ) {
            // Refresh on completion
            localViewModel.refreshFiles()
        }
    }
    
    private func uploadFile(_ file: LocalFile) {
        transferManager.startSingleFileUpload(
            file: file,
            smbViewModel: smbViewModel,
            onComplete: {}
        )
    }
    
    private func downloadFolder(_ file: File) {
        let destURL = localViewModel.currentDirectoryURL.appendingPathComponent(file.name)
        transferManager.startFolderDownload(folder: file, destination: destURL, smbViewModel: smbViewModel) {
            localViewModel.refreshFiles()
        }
    }
    
    private func uploadFolder(_ file: LocalFile) {
        transferManager.startFolderUpload(folder: file, smbViewModel: smbViewModel, onComplete: {})
    }
    
    private func handleSmbFilesDropOnLocal(_ provider: NSItemProvider) {
        transferManager.handleSmbFileDroppedToLocal(
            provider: provider,
            smbViewModel: smbViewModel,
            localViewModel: localViewModel
        )
    }
    
    private func handleLocalFilesDropOnSMB(_ provider: NSItemProvider) {
        transferManager.handleLocalFileDroppedToSMB(
            provider: provider,
            smbViewModel: smbViewModel
        )
    }
    
    private func handleSmbFilesDrop(_ files: [File]) {
        // Handle dropping SMB files onto the local pane
        for file in files {
            if !smbViewModel.isDirectory(file) {
                downloadFile(file)
            }
        }
    }
    
    private func handleLocalFileURLDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { urlData, error in
                guard error == nil else { return }
                
                DispatchQueue.main.async {
                    if let urlData = urlData as? Data,
                       let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                        Task {
                            do {
                                try await self.smbViewModel.uploadLocalFile(url: url)
                            } catch {
                                print("Upload error: \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func setupNotificationObservers() {
        // Add observers for notifications from subviews
        NotificationCenter.default.addObserver(
            forName: Notification.Name("OpenSMBConnect"),
            object: nil,
            queue: .main
        ) { _ in
            
            isConnectSheetPresented = true
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("DownloadSMBFile"),
            object: nil,
            queue: .main
        ) { notification in
            if let file = notification.object as? File {
                downloadFile(file)
            }
        }
        
        // Folder download notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DownloadSMBFolder"),
            object: nil,
            queue: .main
        ) { notification in
            if let folder = notification.object as? File {
                downloadFolder(folder)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("UploadLocalFile"),
            object: nil,
            queue: .main
        ) { notification in
            if let file = notification.object as? LocalFile {
                uploadFile(file)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ProcessSMBFileDrop"),
            object: nil,
            queue: .main
        ) { notification in
            if let fileName = notification.object as? String,
               let file = smbViewModel.getFileByName(fileName) {
                downloadFile(file)
            }
        }
        
        // Folder upload notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UploadLocalFolder"),
            object: nil,
            queue: .main
        ) { notification in
            if let folder = notification.object as? LocalFile {
                uploadFolder(folder)
            }
        }
    }
}

// MARK: - Preview

struct DualPaneFileTransferView_Previews: PreviewProvider {
    static var previews: some View {
        DualPaneFileTransferView()
    }
}
