import SwiftUI
import Combine
import UniformTypeIdentifiers
import AppKit
import SMBClient

struct DualPaneFileTransferView: View {
    @StateObject private var smbViewModel = FileTransferViewModel()
    @StateObject private var localViewModel = LocalFileViewModel()
    @State private var isConnectSheetPresented = false
    @State private var isCreateFolderSheetPresented = false
    @State private var newFolderName = ""
    @State private var activeTransfer: TransferDirection?
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
            
            // Main content with two-pane file browser
            HStack(spacing: 0) {
                if isSidebarVisible {
                    SharesSidebarView(
                        viewModel: smbViewModel,
                        isConnectSheetPresented: $isConnectSheetPresented
                    )
                    
                    Divider()
                }
                
                // Left pane - SMB server files
                SMBPaneView(
                    viewModel: smbViewModel,
                    onFileTap: handleSmbFileTap
                )
                
                // Divider
                Divider()
                
                // Right pane - Local files
                LocalPaneView(
                    viewModel: localViewModel,
                    onFileTap: handleLocalFileTap,
                    onFileDrop: handleSmbFilesDrop
                )
            }
            
            // Status bar
            StatusBarView(
                smbViewModel: smbViewModel,
                localViewModel: localViewModel,
                activeTransfer: activeTransfer
            )
        }
        // Setup drop handling for local file uploads
        .onDrop(of: [.fileURL], isTargeted: nil) { providers -> Bool in
            handleLocalFileURLDrop(providers)
            return true
        }
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
        .alert("Error", isPresented: .init(
            get: { !smbViewModel.errorMessage.isEmpty },
            set: { if !$0 { smbViewModel.errorMessage = "" } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(smbViewModel.errorMessage)
        }
        .alert("Error", isPresented: .init(
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
            // Initialize local file system browser
            localViewModel.initialize()
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
        // Download to current local directory
        Task {
            activeTransfer = .toLocal
            defer { activeTransfer = nil }
            
            do {
                let data = try await smbViewModel.downloadFile(fileName: file.name)
                let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(file.name)
                try data.write(to: localURL)
                
                // Refresh local files
                localViewModel.refreshFiles()
            } catch {
                print("Download failed: \(error)")
            }
        }
    }
    
    private func uploadFile(_ file: LocalFile) {
        let fileURL = localViewModel.currentDirectoryURL.appendingPathComponent(file.name)
        
        Task {
            activeTransfer = .toRemote
            defer { activeTransfer = nil }
            
            do {
                try await smbViewModel.uploadLocalFile(url: fileURL)
            } catch {
                print("Upload error: \(error)")
            }
        }
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
    }
}

// MARK: - Preview

struct DualPaneFileTransferView_Previews: PreviewProvider {
    static var previews: some View {
        DualPaneFileTransferView()
    }
}
