//
//  CreateFolderSheet.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 14/3/25.
//

import SwiftUI

struct CreateFolderSheet: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @Binding var isPresented: Bool
    @Binding var folderName: String
    
    var body: some View {
        VStack {
            Text("Create New Folder")
                .font(.headline)
                .padding()
            
            TextField("Folder Name", text: $folderName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                    folderName = ""
                }
                .keyboardShortcut(.cancelAction)

                Spacer()
                
                Button("Create") {
                    Task {
                        try await viewModel.createDirectory(directoryName: folderName)
                        isPresented = false
                        folderName = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(folderName.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 300)
    }
}

struct CreateFolderSheet_Previews: PreviewProvider {
    static var previews: some View {
        CreateFolderSheet(
            viewModel: FileTransferViewModel(),
            isPresented: .constant(true),
            folderName: .constant("Folder A")
        )
    }
}
