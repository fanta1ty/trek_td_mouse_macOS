//
//  CredentialsForm.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 31/3/25.
//

import SwiftUI
import SMBClient

struct CredentialsForm: View {
    @EnvironmentObject var viewModel: FileTransferViewModel
    @Binding var isConnecting: Bool
    @Binding var shouldSave: Bool
    @Binding var connectioName: String
    
    @State private var showPassword: Bool = false
    
    let onDisconnect: () -> Void
    
    var body: some View {
        Form {
            Section(header: Text("Server Details")) {
                TextField("Host", text: $viewModel.credentials.host)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                HStack {
                    Text("Port")
                    Spacer()
                    TextField("445", value: $viewModel.credentials.port, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
            
            Section(header: Text("Credentials")) {
                TextField("Username", text: $viewModel.credentials.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Group {
                    if showPassword {
                        TextField("Password", text: $viewModel.credentials.password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                    } else {
                        SecureField("Password", text: $viewModel.credentials.password)
                    }
                }
                
                Button {
                    showPassword.toggle()
                } label: {
                    Label(showPassword ? "Hide password" : "Show password", systemImage: showPassword ? "eye.slash.fill" : "eye.fill")
                }
            }
            
            Section(header: Text("Save Connection")) {
                Toggle("Save for future use", isOn: $shouldSave)
                
                if shouldSave {
                    TextField("Connection Name", text: $connectioName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Text("Note: Password will not be saved")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if viewModel.connectionState == .connected {
                Section {
                    Button {
                        onDisconnect()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Disconnect", systemImage: "link.badge.minus")
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                }
            }
        }
        .disabled(isConnecting)
    }
}

struct CredentialsForm_Previews: PreviewProvider {
    static var previews: some View {
        CredentialsForm(
            isConnecting: .constant(false),
            shouldSave: .constant(false),
            connectioName: .constant(""),
            onDisconnect: { }
        )
        .environmentObject(FileTransferViewModel())
    }
}
