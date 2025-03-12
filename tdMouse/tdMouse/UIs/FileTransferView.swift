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
    @State private var isConnectSheetPresented: Bool = false
    
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
    
    @State private var selectedFile: File?
    @State private var isFileActionSheetPresented = false
    @State private var isCreateFolderSheetPresented = false
    @State private var newFolderName = ""
    @State private var isImportFilePickerPresented = false
    @State private var downloadDestination: URL?
    
    var body: some View {
        NavigationView {
            SidebarView(viewModel: viewModel)
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
