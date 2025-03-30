//
//  SingleScreenFileTransferView.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI

struct SingleScreenFileTransferView: View {
    @EnvironmentObject var transferManager: TransferManager
    @EnvironmentObject var smbViewModel: FileTransferViewModel
    @EnvironmentObject var localViewModel: LocalFileViewModel
    @State private var isConnectSheetPresented = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Connection status bar
                ConnectionStatusBar(viewModel: smbViewModel)
                
                // Top section: SMB browser
                SMBBrowserSection()
                    .frame(height: UIScreen.main.bounds.height * 0.45)
                
                // Divider with transfer controls
                TransferControlDivider()
                
                // Bottom section: Local files browser
                LocalFilesBrowserSection()
                    .frame(height: UIScreen.main.bounds.height * 0.45)
            }
            .navigationTitle("TD Mouse")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isConnectSheetPresented = true }) {
                        Label("Connect", systemImage: "link")
                    }
                }
            }
            .sheet(isPresented: $isConnectSheetPresented) {
                ConnectionSheet()
            }
        }
    }
}
