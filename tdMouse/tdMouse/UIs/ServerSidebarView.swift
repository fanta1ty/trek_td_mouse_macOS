//
//  SidebarView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI

struct ServerSidebarView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    
    var body: some View {
        List {
            Section("Server") {
                if viewModel.connectionState == .connected {
                    Text(viewModel.credentials.host)
                        .font(.subheadline)
                } else {
                    Text("Not connected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if viewModel.connectionState == .connected {
                Section("Shares") {
                    ForEach(viewModel.availableShares, id: \.self) { share in
                        Button(action: {
                            Task {
                                try await viewModel.connectToShare(share)
                            }
                        }, label: {
                            HStack {
                                Image(systemName: "folder")
                                Text(share)
                                
                                if viewModel.shareName == share {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        })
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 180)
    }
}

struct ServerSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        ServerSidebarView(viewModel: FileTransferViewModel())
    }
}
