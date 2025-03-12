//
//  SidebarView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 12/3/25.
//

import SwiftUI
import Combine

struct SidebarView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    
    var body: some View {
        List {
            Section(header: Text("Connection")) {
                if viewModel.isConnected {
                    
                } else {
                    Text("Not connected")
                    
                    Button("Connect") {
                        Task {
                            await viewModel.connect()
                        }
                    }
                    .disabled(viewModel.isConnecting)
                }
            }
        }
    }
}
