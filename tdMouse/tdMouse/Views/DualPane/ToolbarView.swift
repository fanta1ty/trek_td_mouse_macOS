//
//  ToolbarView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI

struct ToolbarView: View {
    @ObservedObject var smbViewModel: FileTransferViewModel
    let onConnect: () -> Void
    let onRefresh: () -> Void
    let onNewFolder: () -> Void
    
    var body: some View {
        HStack {
            Text("SMB File Transfer")
                .font(.title)
                .padding(.leading)
            
            Spacer()
            
            Button(action: onConnect) {
                if smbViewModel.connectionState == .connected {
                    Label("Disconnect", systemImage: "network.slash")
                } else {
                    Label("Connect", systemImage: "network")
                }
            }
            .padding(.trailing)
            
            if smbViewModel.connectionState == .connected {
                Button(action: onRefresh) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .padding(.trailing)
            }
            
            Button(action: onNewFolder) {
                Label("New Folder", systemImage: "folder.badge.plus")
            }
            .padding(.trailing)
            .disabled(smbViewModel.connectionState != .connected)
        }
        .padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct ToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarView(
            smbViewModel: FileTransferViewModel()) {
                
            } onRefresh: {
                
            } onNewFolder: {
                
            }
    }
}
