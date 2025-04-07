import SwiftUI
import Combine
import UniformTypeIdentifiers
import AppKit
import SMBClient

struct DualPaneFileTransferView: View {
    // MARK: - View Models and State
    @StateObject private var transferManager = TransferManager()
    @StateObject private var smbViewModel = FileTransferViewModel()
    @StateObject private var localViewModel = LocalFileViewModel()
    
    // UI State
    @State private var isConnectSheetPresented = false
    @State private var isCreateFolderSheetPresented = false
    @State private var newFolderName = ""
    @State private var isSidebarVisible = true
    @State private var showPreviewSheet = false
    @State private var currentPreviewFile: PreviewFileInfo?
    @State private var splitPosition: CGFloat = 0.5
    @State private var activeView: ActivePane = .smb
    
    // Activity indicators
    @State private var isRefreshing = false
    
    private enum ActivePane {
        case smb, local
    }
    
    // MARK: - Main View
    var body: some View {
        VStack(spacing: 0) {
            // Modern app toolbar with action buttons
            ModernToolbarView(
                smbViewModel: smbViewModel,
                onConnect: { isConnectSheetPresented.toggle() },
                onRefresh: refreshCurrentPane,
                onNewFolder: { isCreateFolderSheetPresented.toggle() }
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Color(NSColor.windowBackgroundColor)
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            )
            
            // Main content with three-pane file browser
            HStack(spacing: 0) {
                // Left sidebar for SMB Shares
                if isSidebarVisible {
                    SharesSidebarView(
                        viewModel: smbViewModel,
                        isConnectSheetPresented: $isConnectSheetPresented
                    )
                    .frame(width: 220)
                    .transition(.move(edge: .leading))
                    
                    Divider()
                }
                
                // Content panes with a split view
                HSplitView {
                    // SMB server files pane
                    SMBPaneView(
                        viewModel: smbViewModel,
                        onFileTap: handleSmbFileTap,
                        onLocalFileDrop: handleLocalFilesDropOnSMB
                    )
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .onTapGesture {
                        activeView = .smb
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(activeView == .smb ? Color.accentColor : Color.clear, lineWidth: 2)
                            .padding(1)
                            .animation(.easeInOut(duration: 0.2), value: activeView)
                    )
                    
                    // Local files pane
                    LocalPaneView(
                        viewModel: localViewModel,
                        transferManager: transferManager,
                        onFileTap: handleLocalFileTap,
                        onFolderUpload: uploadFolder,
                        onSmbFileDrop: handleSmbFilesDropOnLocal
                    )
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .onTapGesture {
                        activeView = .local
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(activeView == .local ? Color.accentColor : Color.clear, lineWidth: 2)
                            .padding(1)
                            .animation(.easeInOut(duration: 0.2), value: activeView)
                    )
                }
            }
            
            // Enhanced status bar with transfer info
            EnhancedStatusBarView(
                smbViewModel: smbViewModel,
                localViewModel: localViewModel,
                transferManager: transferManager
            )
        }
        .toolbar {
            // Toolbar customization
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSidebarVisible.toggle()
                    }
                }) {
                    Label("Toggle Sidebar", systemImage: "sidebar.left")
                }
                .help("Toggle sidebar")
                .keyboardShortcut("s", modifiers: [.command, .option])
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: refreshCurrentPane) {
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .help("Refresh current view")
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(isRefreshing)
            }
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
        .sheet(isPresented: $showPreviewSheet) {
            if let fileInfo = currentPreviewFile {
                UniversalFilePreviewView(
                    title: fileInfo.title,
                    fileProvider: fileInfo.provider,
                    fileExtension: fileInfo.extension
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
    
    private func refreshCurrentPane() {
        Task {
            isRefreshing = true
            
            switch activeView {
            case .smb:
                try await smbViewModel.listFiles(smbViewModel.currentDirectory)
            case .local:
                localViewModel.refreshFiles()
            }
            
            // Add a small delay for visual feedback
            try await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
    
    private func handleSmbFileTap(_ file: File) {
        if smbViewModel.isDirectory(file) {
            Task {
                try await smbViewModel.navigateToDirectory(file.name)
            }
        } else if isPreviewableFileType(file.name) {
            previewSmbFile(file)
        } else {
            Task {
                await downloadFile(file)
            }
        }
    }
    
    private func handleLocalFileTap(_ file: LocalFile) {
        if file.isDirectory {
            localViewModel.navigateToDirectory(file.name)
        } else if isPreviewableFileType(file.name) {
            previewLocalFile(file)
        } else {
            Task {
                await uploadFile(file)
            }
        }
    }
    
    private func downloadFile(_ file: File) async {
        let localURL = localViewModel.currentDirectoryURL.appendingPathComponent(file.name)
        await transferManager.startSingleFileDownload(
            file: file,
            destinationURL: localURL,
            smbViewModel: smbViewModel
        ) {
            // Refresh on completion
            localViewModel.refreshFiles()
        }
    }
    
    private func uploadFile(_ file: LocalFile) async {
        await transferManager.startSingleFileUpload(
            file: file,
            smbViewModel: smbViewModel,
            onComplete: {}
        )
    }
    
    private func downloadFolder(_ file: File) async {
        let destURL = localViewModel.currentDirectoryURL.appendingPathComponent(file.name)
        await transferManager.startFolderDownload(folder: file, destination: destURL, smbViewModel: smbViewModel) {
            localViewModel.refreshFiles()
        }
    }
    
    private func uploadFolder(_ file: LocalFile) {
        Task {
            await transferManager.startFolderUpload(folder: file, smbViewModel: smbViewModel, onComplete: {})
        }
    }
    
    private func previewSmbFile(_ file: File) {
        currentPreviewFile = PreviewFileInfo(
            title: file.name,
            provider: {
                try await smbViewModel.downloadFile(fileName: file.name, trackTransfer: false)
            },
            extension: file.name.components(separatedBy: ".").last ?? ""
        )
        showPreviewSheet = true
    }
    
    private func previewLocalFile(_ file: LocalFile) {
        currentPreviewFile = PreviewFileInfo(
            title: file.name,
            provider: {
                try Data(contentsOf: file.url)
            },
            extension: file.name.components(separatedBy: ".").last ?? ""
        )
        showPreviewSheet = true
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
                Task {
                    await downloadFile(file)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("PreviewSMBFile"),
            object: nil,
            queue: .main
        ) { notification in
            if let file = notification.object as? File {
                previewSmbFile(file)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("PreviewLocalFile"),
            object: nil,
            queue: .main
        ) { notification in
            if let file = notification.object as? LocalFile {
                previewLocalFile(file)
            }
        }
        
        // Folder download notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DownloadSMBFolder"),
            object: nil,
            queue: .main
        ) { notification in
            if let folder = notification.object as? File {
                Task {
                    await downloadFolder(folder)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("UploadLocalFile"),
            object: nil,
            queue: .main
        ) { notification in
            if let file = notification.object as? LocalFile {
                Task {
                    await uploadFile(file)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ProcessSMBFileDrop"),
            object: nil,
            queue: .main
        ) { notification in
            if let fileName = notification.object as? String,
               let file = smbViewModel.getFileByName(fileName) {
                Task {
                    await downloadFile(file)
                }
            }
        }
        
        // Folder upload notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UploadLocalFolder"),
            object: nil,
            queue: .main
        ) { notification in
            if let folder = notification.object as? LocalFile {
                Task {
                    await uploadFolder(folder)
                }
            }
        }
    }
}

// MARK: - Enhanced Components

struct ModernToolbarView: View {
    @ObservedObject var smbViewModel: FileTransferViewModel
    
    let onConnect: () -> Void
    let onRefresh: () -> Void
    let onNewFolder: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // App icon and title
            Label {
                Text("TD Mouse")
                    .font(.headline)
            } icon: {
                Image(systemName: "network.badge.shield.half.filled")
                    .foregroundColor(.accentColor)
            }
            
            Divider()
                .frame(height: 20)
            
            // Connection status & button
            Button(action: onConnect) {
                HStack {
                    Circle()
                        .fill(smbViewModel.connectionState == .connected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(smbViewModel.connectionState == .connected ? "Connected" : "Connect")
                        .font(.subheadline)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                if smbViewModel.connectionState == .connected {
                    Button(action: onNewFolder) {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                    .help("Create new folder on server")
                    
                    Button(action: onRefresh) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .help("Refresh")
                }
            }
        }
    }
}

struct EnhancedStatusBarView: View {
    @ObservedObject var smbViewModel: FileTransferViewModel
    @ObservedObject var localViewModel: LocalFileViewModel
    @ObservedObject var transferManager: TransferManager
    
    var body: some View {
        HStack {
            // Connection status
            if smbViewModel.connectionState == .connected {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Connected to \(smbViewModel.credentials.host)")
                        .font(.caption)
                }
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text("Disconnected")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            // Transfer status
            if let activeTransfer = transferManager.activeTransfer {
                HStack(spacing: 8) {
                    if activeTransfer == .toLocal {
                        Label("Downloading", systemImage: "arrow.down.circle")
                            .font(.caption)
                    } else {
                        Label("Uploading", systemImage: "arrow.up.circle")
                            .font(.caption)
                    }
                    
                    Text(transferManager.currentTransferItem)
                        .font(.caption)
                        .lineLimit(1)
                    
                    if transferManager.totalTransferItems > 0 {
                        Text("\(transferManager.processedTransferItems)/\(transferManager.totalTransferItems)")
                            .font(.caption.monospacedDigit())
                    }
                    
                    ProgressView(value: Double(transferManager.processedTransferItems) / Double(max(1, transferManager.totalTransferItems)))
                        .frame(width: 100)
                }
                .transition(.opacity)
            } else {
                // File statistics
                HStack(spacing: 4) {
                    let smbCount = smbViewModel.files.count
                    let localCount = localViewModel.files.count
                    
                    Image(systemName: "doc.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(smbCount) SMB files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "doc.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(localCount) local files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            }
        }
        .padding(8)
        .background(Color(NSColor.windowBackgroundColor))
        .animation(.easeInOut(duration: 0.2), value: transferManager.activeTransfer)
    }
}

// MARK: - Preview
struct DualPaneFileTransferView_Previews: PreviewProvider {
    static var previews: some View {
        DualPaneFileTransferView()
            .frame(width: 1200, height: 800)
            .previewLayout(.sizeThatFits)
    }
}
