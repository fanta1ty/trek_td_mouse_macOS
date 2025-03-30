//
//  ConnectionSheet.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI

struct ConnectionSheet: View {
    @EnvironmentObject var viewModel: FileTransferViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showPassword = false
    @State private var connectionName = ""
    @State private var shouldSave = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showShareSelector = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Server details section
                Section(header: Text("Server Details")) {
                    TextField("Host", text: $viewModel.credentials.host)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    TextField("Port", value: $viewModel.credentials.port, format: .number)
                        .keyboardType(.numberPad)
                }
                
                // Credentials section
                Section(header: Text("Credentials")) {
                    TextField("Username", text: $viewModel.credentials.username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    if showPassword {
                        TextField("Password", text: $viewModel.credentials.password)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("Password", text: $viewModel.credentials.password)
                    }
                    
                    Toggle("Show password", isOn: $showPassword)
                    
                    TextField("Domain (Optional)", text: $viewModel.credentials.domain)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                // Save connection section
                Section {
                    Toggle("Save connection", isOn: $shouldSave)
                    
                    if shouldSave {
                        TextField("Connection name", text: $connectionName)
                    }
                } header: {
                    Text("Save Connection")
                } footer: {
                    Text("Note: Password will not be saved")
                }
            }
            .navigationTitle("Connect to Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") {
                        Task {
                            await connectToServer()
                        }
                    }
                    .disabled(!viewModel.isCredentialsValid)
                }
            }
            .alert("Connection Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showShareSelector) {
                SharesSelectorView()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShareSelectedDismissConnection"))) { _ in
                // Dismiss the connection sheet when share is selected
                dismiss()
            }
        }
    }
    
    private func connectToServer() async {
        // Save connection if requested
        if shouldSave && !connectionName.isEmpty {
            // Save connection logic
        }
        
        do {
            try await viewModel.connect()
            
            // After successful connection, fetch available shares
            try await viewModel.fetchShares()
            
            // Show share selector
            await MainActor.run {
                showShareSelector = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}
