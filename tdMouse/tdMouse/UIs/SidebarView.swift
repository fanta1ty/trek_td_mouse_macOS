//
//  SidebarView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI
import Combine

struct SidebarView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    
    var body: some View {
        List {
            Section("Server") {
                if viewModel.connectionState == .connected {
                    
                } else {
                    Text("Not connected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
