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
    @Binding var connectionName: String
    @Binding var savedConnections: [SavedConnection]
    
    @State private var showPassword: Bool = false
    
    let onDisconnect: () -> Void
    
    var body: some View {
        Form {
            // Saved connections section
            if !savedConnections.isEmpty {
                Section(header: Text("Saved Connections")) {
                    ForEach(savedConnections, id: \.id) { connection in
                        Button {
                            fillFromSavedConnection(connection)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(connection.displayName)
                                        .fontWeight(.medium)
                                    
                                    Text(connection.username)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                    }
                }
            }
            
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
                    TextField("Connection Name", text: $connectionName)
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
                            Label("Disconnect", systemImage: "link.circle")
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

// MARK: - Private Functions
extension CredentialsForm {
    private func fillFromSavedConnection(_ connection: SavedConnection) {
        viewModel.credentials.host = connection.host
        viewModel.credentials.port = Int(connection.port)
        viewModel.credentials.username = connection.username
        viewModel.credentials.domain = connection.domain
        
        connectionName = connection.name
        shouldSave = true
    }
}

struct CredentialsForm_Previews: PreviewProvider {
    static var previews: some View {
        CredentialsForm(
            isConnecting: .constant(false),
            shouldSave: .constant(false),
            connectionName: .constant(""),
            savedConnections: .constant([
                SavedConnection(
                    name: "name 1",
                    host: "192.168.1.1",
                    port: 445,
                    username: "test1",
                    domain: ""
                ),
                SavedConnection(
                    name: "name 2",
                    host: "192.168.1.2",
                    port: 445,
                    username: "test2",
                    domain: ""
                ),
            ]),
            onDisconnect: { }
        )
        .environmentObject(FileTransferViewModel())
    }
}
