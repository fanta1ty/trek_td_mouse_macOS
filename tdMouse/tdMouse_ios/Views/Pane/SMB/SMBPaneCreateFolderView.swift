//
//  SMBPaneCreateFolderView.swift
//  tdMouse
//
//  Created by mobile on 6/4/25.
//

import SwiftUI
import SMBClient

struct SMBPaneCreateFolderView: View {
    @EnvironmentObject private var viewModel: FileTransferViewModel
    
    @State private var folderName: String = ""
    @State private var errorMessage: String = ""
    @State private var isCreating: Bool = false
    @State private var showError: Bool = false
    
    @Binding var isPresented: Bool
    
    var body: some View {
        Form {
            Section {
                TextField("Folder Name", text: $folderName)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .disabled(isCreating)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isPresented = false
                    folderName = ""
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    createFolder()
                }
                .disabled(folderName.isEmpty || isCreating)
            }
        }
        .overlay(Group {
            if isCreating {
                ProgressView("Creating folder...")
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 2)
            }
        })
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

extension SMBPaneCreateFolderView {
    private func createFolder() {
        guard !folderName.isEmpty else { return }
        
        isCreating = true
        
        Task {
            do {
                try await viewModel.createDirectory(directoryName: folderName)
                
                await MainActor.run {
                    isCreating = false
                    isPresented = false
                    folderName = ""
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
