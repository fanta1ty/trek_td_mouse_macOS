//
//  SMBHeaderView.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI

struct SMBHeaderView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    
    @Binding var isCreateFolderSheetPresented: Bool
    @Binding var isConnectSheetPresented: Bool
    
    var body: some View {
        HStack  {
            Text("TD Mouse")
                .font(.headline)
                .padding(.leading)
            
            Spacer()
            
            if viewModel.connectionState == .connected {
                Button {
                    Task {
                        try await viewModel.navigateUp()
                    }
                } label: {
                    Image(systemName: "arrow.up")
                }
                .disabled(viewModel.currentDirectory.isEmpty)
                .padding(.horizontal, 4)

                Button {
                    Task {
                        try await viewModel.listFiles(viewModel.currentDirectory)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .padding(.horizontal, 4)
                
                Button(action: {
                    isCreateFolderSheetPresented.toggle()
                }) {
                    Image(systemName: "folder.badge.plus")
                }
                .padding(.horizontal, 4)
            }
            
            Button(action: {
                isConnectSheetPresented.toggle()
            }) {
                Image(systemName: viewModel.connectionState == .connected ? "link" : "link.badge.plus")
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.tertiarySystemBackground))
    }
}

struct SMBHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SMBHeaderView(
            viewModel: FileTransferViewModel(),
            isCreateFolderSheetPresented: .constant(true),
            isConnectSheetPresented: .constant(true)
        )
    }
}
