//
//  DualPaneFileView.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI
import SMBClient
import UniformTypeIdentifiers

struct DualPaneFileView: View {
    @EnvironmentObject private var viewModel: FileTransferViewModel
    @EnvironmentObject private var localViewModel: LocalViewModel
    
    @State private var currentPreviewFile: PreviewFileInfo?
    @State private var isConnectSheetPresented: Bool = false
    @State private var showPreviewSheet: Bool = false
    @State private var activePaneIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
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
                        showPreviewSheet: $showPreviewSheet
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
                        showPreviewSheet: $showPreviewSheet
                    )
                    .frame(height: geometry.size.height * 0.45)
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            
            // Transfer status bar
            TransferStatusBarView()
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
        }
        .sheet(isPresented: $isConnectSheetPresented) {
            NavigationView {
                ConnectionSheetView(isPresented: $isConnectSheetPresented)
                    .navigationBarTitleDisplayMode(.inline)
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
