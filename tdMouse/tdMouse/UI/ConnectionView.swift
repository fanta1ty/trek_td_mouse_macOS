//
//  ConnectionView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 12/3/25.
//

import SwiftUI
import Combine

struct ConnectionView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Connect to TD Mouse")
                .font(.title)
            
            VStack(alignment: .leading, spacing: 12) {
                TextField("Host", text: $viewModel.credentials.host)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                HStack {
                    Text("Port")
                    TextField("Port", value: $viewModel.credentials.port, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                
                TextField("Username", text: $viewModel.credentials.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Password", text: $viewModel.credentials.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Share Point", text: $viewModel.credentials.sharePoint)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            
            }
            .frame(width: 300)
            
            if let error = viewModel.connectionError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Button {
                Task {
                    await viewModel.connect()
                }
            } label: {
                HStack {
                    if viewModel.isConnecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    }
                    Text(viewModel.isConnecting ? "Connecting..." : "Connect")
                }
                .frame(width: 150)
            }
            .disabled(viewModel.credentials.host.isEmpty ||
                      viewModel.credentials.username.isEmpty ||
                      viewModel.credentials.password.isEmpty ||
                      viewModel.credentials.sharePoint.isEmpty ||
                      viewModel.isConnecting)
            .buttonStyle(.borderedProminent)

        }
        .padding()
    }
}
