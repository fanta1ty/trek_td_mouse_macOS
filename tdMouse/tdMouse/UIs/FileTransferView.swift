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
    @State private var isConnectSheetPresented = false
    @State private var isCreateFolderSheetPresented = false
    @State private var isImportFilePickerPresented = false
    @State private var newFolderName = ""
    
    // Notification observers for menu commands
    private let connectObserver = NotificationCenter.default.publisher(
        for: .init("OpenConnectDialog"), object: nil
    )
    private let uploadObserver = NotificationCenter.default.publisher(
        for: .init("OpenUploadDialog"), object: nil
    )
    private let newFolderObserver = NotificationCenter.default.publisher(
        for: .init("OpenNewFolderDialog"), object: nil
    )
    private let refreshObserver = NotificationCenter.default.publisher(
        for: .init("RefreshFileList"), object: nil
    )
    
    var body: some View {
        NavigationView {
            ServerSidebarView(viewModel: viewModel)
            
            // Main content with file listing
            if viewModel.connectionState == .connected {
            
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
        }
    }
}

struct FileTransferView_Previews: PreviewProvider {
    static var previews: some View {
        FileTransferView()
    }
}
