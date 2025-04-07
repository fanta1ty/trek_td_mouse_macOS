//
//  ConnectionStatusBarView.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI

struct ConnectionStatusBarView: View {
    @EnvironmentObject private var viewModel: FileTransferViewModel
    
    @Binding var isConnectSheetPresented: Bool
    
    var body: some View {
        HStack {
            // Connection status indicator
            Circle()
                .fill(viewModel.connectionState == .connected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            if viewModel.connectionState == .connected {
                Text("Connected to \(viewModel.credentials.host)")
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
            } else {
                Text("Not connected")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                isConnectSheetPresented = true
            } label: {
                Image(systemName: viewModel.connectionState == .connected ? "arrow.triangle.2.circlepath" : "link")
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
}

struct ConnectionStatusBarView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionStatusBarView(
            isConnectSheetPresented: .constant(true)
        )
        .environmentObject(FileTransferViewModel())
        .environmentObject(LocalViewModel())
    }
}
