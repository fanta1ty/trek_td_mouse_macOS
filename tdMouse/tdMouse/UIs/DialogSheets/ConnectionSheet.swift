//
//  ConnectionSheet.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI

struct ConnectionSheet: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            Text("Connect to TD Mouse")
                .font(.headline)
                .padding()
            
            Form {
                TextField("Host", text: $viewModel.credentials.host)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                HStack {
                    Text("Port:")
                    TextField("Port", value: $viewModel.credentials.port, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                
                TextField("Username", text: $viewModel.credentials.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Password", text: $viewModel.credentials.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                if viewModel.connectionState == .connected {
                    Button("Disconnect") {
                        Task {
                            try await viewModel.disconnect()
                            isPresented = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.red)
                }
                
                Button(viewModel.connectionState == .connected ? "Reconnect" : "Connect") {
                    Task {
                        if viewModel.connectionState == .connected {
                            try await viewModel.disconnect()
                        }
                        try await viewModel.connect()
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isCredentialsValid)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 400)
    }
}

struct ConnectionSheet_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionSheet(
            viewModel: FileTransferViewModel(),
            isPresented: .constant(true)
        )
    }
}
