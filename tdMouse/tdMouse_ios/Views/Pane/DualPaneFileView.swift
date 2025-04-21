import SwiftUI
import SMBClient
import UniformTypeIdentifiers

struct DualPaneFileView: View {
    @EnvironmentObject private var viewModel: FileTransferViewModel
    @EnvironmentObject private var localViewModel: LocalViewModel
    @StateObject private var bleManager = BLEManager()
    
    @State private var currentPreviewFile: PreviewFileInfo?
    @State private var isConnectSheetPresented: Bool = false
    @State private var isBLEConnectSheetPresented: Bool = false
    @State private var showPreviewSheet: Bool = false
    @State private var showTransferSummary: Bool = false
    @State private var isCreateLocalFolderSheetPresented = false
    @State private var isCreateSMBFolderSheetPresented = false
    @State private var activePaneIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // BLE Connection Status
            VStack(spacing: 0) {
                BLEConnectionStatusView(isBLEConnectSheetPresented: $isBLEConnectSheetPresented)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemBackground))
                
                // Thêm BLEDeviceStatusView khi kết nối BLE
                if bleManager.isConnected {
                    BLEDeviceStatusView()
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: bleManager.isConnected)
                }
            }
            
            // Connection status bar
            ConnectionStatusBarView(
                isConnectSheetPresented: $isConnectSheetPresented
            )
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground))
            
            // Content panes
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Text("TD Mouse Files")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        .padding(.leading)
                    
                    SMBPane(
                        currentPreviewFile: $currentPreviewFile,
                        activePaneIndex: $activePaneIndex,
                        showPreviewSheet: $showPreviewSheet,
                        isCreateFolderSheetPresented: $isCreateSMBFolderSheetPresented
                    )
                    .frame(height: geometry.size.height * 0.45)
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    Text("Local Files")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    
                    LocalPane(
                        currentPreviewFile: $currentPreviewFile,
                        activePaneIndex: $activePaneIndex,
                        showPreviewSheet: $showPreviewSheet,
                        isCreateFolderSheetPresented: $isCreateLocalFolderSheetPresented
                    )
                    .frame(height: geometry.size.height * 0.45)
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            
            .onAppear {
                // Khi DualPaneFileView xuất hiện, tự động mở popup BLE
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isBLEConnectSheetPresented = true
                }
            }
            
        }
        .sheet(isPresented: $isConnectSheetPresented) {
            NavigationView {
                ConnectionSheetView(isPresented: $isConnectSheetPresented)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $isBLEConnectSheetPresented) {
            NavigationView {
                BLEConnectView(isPresented: $isBLEConnectSheetPresented)
                    .navigationBarTitleDisplayMode(.inline)
                    .environmentObject(bleManager)
            }
        }
        .sheet(isPresented: $showPreviewSheet) {
            NavigationView {
                if let currentPreviewFile {
                    FilePreviewView(
                        showPreviewSheet: $showPreviewSheet,
                        title: currentPreviewFile.title,
                        fileProvider: currentPreviewFile.provider,
                        fileExtension: currentPreviewFile.extension
                    )
                } else {
                    FilePreparingPreviewView(
                        showPreviewSheet: $showPreviewSheet
                    )
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $isCreateSMBFolderSheetPresented, content: {
            NavigationView {
                SMBPaneCreateFolderView(
                    isPresented: $isCreateSMBFolderSheetPresented
                )
                .navigationTitle("New Folder")
                .navigationBarTitleDisplayMode(.inline)
            }
        })
        .sheet(isPresented: $isCreateLocalFolderSheetPresented, content: {
            NavigationView {
                LocalPaneCreateFolderView(
                    isPresented: $isCreateLocalFolderSheetPresented
                )
                .navigationTitle("New Folder")
                .navigationBarTitleDisplayMode(.inline)
            }
        })
        .sheet(isPresented: $viewModel.showTransferSummary) {
            if let stats = viewModel.lastTransferStats {
                TransferSummaryView(
                    summary: .init(
                        type: stats.transferType == .download ? .download : .upload,
                        fileCount: -1,
                        directoryCount: -1,
                        totalBytes: stats.fileSize,
                        startTime: stats.startTime,
                        endDate: stats.endTime,
                        isSuccess: true,
                        errorMessage: nil,
                        speedSamples: stats.speedSamples
                    ),
                    isPresented: $viewModel.showTransferSummary
                )
            }
        }
        .environmentObject(bleManager)
        .toolbar {
            ToolbarItem {
                Menu {
                    if viewModel.connectionState == .connected {
                        Button {
                            Task {
                                try await viewModel.disconnect()
                            }
                        } label: {
                            Label("Disconnect", systemImage: "link.circle")
                        }
                    } else {
                        Button {
                            isConnectSheetPresented = true
                        } label: {
                            Label("Connect to Server", systemImage: "link")
                        }
                    }
                    
                    // Thêm option cho BLE connection
                    Divider()
                    
                    if bleManager.isConnected {
                        Button {
                            bleManager.disconnect()
                        } label: {
                            Label("Disconnect BLE", systemImage: "antenna.radiowaves.left.and.right.slash")
                        }
                    } else {
                        Button {
                            isBLEConnectSheetPresented = true
                        } label: {
                            Label("Connect BLE", systemImage: "antenna.radiowaves.left.and.right")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

struct DualPaneFileView_Previews: PreviewProvider {
    static var previews: some View {
        DualPaneFileView()
            .environmentObject(FileTransferViewModel())
            .environmentObject(LocalViewModel())
            .environmentObject(TransferManager())
    }
}
