//
//  FileActionSheet.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI
import SMBClient

struct FileActionSheet: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @Binding var isPresented: Bool
    
    let file: File
    
    var body: some View {
        VStack {
            Text(file.name)
                .font(.headline)
                .padding()
            
            if viewModel.isDirectory(file) {
                Button("Open") {
                    Task {
                        try await viewModel.navigateToDirectory(file.name)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(width: 200)
                .padding(.bottom, 5)
            } else {
                Button("Download") {
                    downloadFile(file)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(width: 200)
                .padding(.bottom, 5)
            }
            
            Button("Delete") {
                Task {
                    try await viewModel.deleteItem(
                        name: file.name,
                        isDirectory: viewModel.isDirectory(file)
                    )
                    
                    isPresented = false
                }
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            .controlSize(.large)
            .frame(width: 200)
            .padding(.bottom, 5)
            
            Button("Cancel") {
                isPresented = false
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(width: 200)
            .padding(.bottom)
            .keyboardShortcut(.cancelAction)
        }
        .frame(width: 300)
    }
    
    private func downloadFile(_ file: File) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = file.name
        panel.canCreateDirectories = true
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task {
                    do {
                        let data = try await viewModel.downloadFile(fileName: file.name)
                        try data.write(to: url)
                    } catch {
                        print("Download error: \(error)")
                    }
                }
            }
        }
    }
}
