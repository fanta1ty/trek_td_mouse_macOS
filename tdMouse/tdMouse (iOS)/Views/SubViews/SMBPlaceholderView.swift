//
//  SMBPlaceholderView.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI

struct SMBPlaceholderView: View {
    @EnvironmentObject var smbViewModel: FileTransferViewModel
    @State private var isConnectSheetPresented = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: smbViewModel.connectionState == .connecting ?
                             "network.badge.shield.half.filled" : "network.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .opacity(0.6)
            
            if smbViewModel.connectionState == .connecting {
                Text("Connecting to Server...")
                    .font(.headline)
                
                ProgressView()
                    .padding()
            } else if case .error(let message) = smbViewModel.connectionState {
                Text("Connection Error")
                    .font(.headline)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else if smbViewModel.connectionState == .connected &&
                     smbViewModel.availableShares.isEmpty {
                Text("No Shares Available")
                    .font(.headline)
                
                Text("The server doesn't have any accessible shares")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("Not Connected to SMB Server")
                    .font(.headline)
                
                Text("Connect to a server to browse and transfer files")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if smbViewModel.connectionState != .connecting {
                Button(action: {
                    isConnectSheetPresented = true
                }) {
                    Label(smbViewModel.connectionState == .connected ? "Change Server" : "Connect to Server",
                          systemImage: "link")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .sheet(isPresented: $isConnectSheetPresented) {
                    ConnectionSheet()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
