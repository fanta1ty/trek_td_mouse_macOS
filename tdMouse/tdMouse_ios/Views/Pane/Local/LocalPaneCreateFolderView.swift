//
//  LocalPaneCreateFolderView.swift
//  tdMouse
//
//  Created by mobile on 6/4/25.
//

import SwiftUI
import SMBClient

struct LocalPaneCreateFolderView: View {
    @EnvironmentObject private var viewModel: LocalViewModel
    
    @State private var folderName: String = ""
    @State private var errorMessage: String = ""
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
                .disabled(folderName.isEmpty)
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

extension LocalPaneCreateFolderView {
    private func createFolder() {
        guard !folderName.isEmpty else { return }
        
        do {
            try viewModel.createDirectory(directoryName: folderName)
            isPresented = false
            folderName = ""
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
