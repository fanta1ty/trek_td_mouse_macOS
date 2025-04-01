//
//  SMBPane.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 31/3/25.
//

import SwiftUI
import SMBClient

struct SMBPane: View {
    @EnvironmentObject private var viewModel: FileTransferViewModel
    
    @Binding var activePaneIndex: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                
                if viewModel.connectionState == .connected {
                    // Navigation controls
                    HStack(spacing: 12) {
                        Button {
                            Task {
                                try await viewModel.navigateUp()
                            }
                        } label: {
                            Image(systemName: "arrow.up")
                                .foregroundStyle(viewModel.currentDirectory.isEmpty ? .gray : .blue)
                        }
                        .disabled(viewModel.currentDirectory.isEmpty)
                        
                        Button {
                            Task {
                                try await viewModel.listFiles(viewModel.currentDirectory)
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.vertical, 4)
            
            if viewModel.connectionState == .connected {
                // Breadcrumb path
                HStack {
                    Text("\(viewModel.shareName)/\(viewModel.currentDirectory)")
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                }
                .padding(.bottom, 4)
                
                // File list
                if viewModel.files.isEmpty {
                    EmptyStateView(
                        systemName: "folder",
                        title: "No Files",
                        message: "This folder is empty"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.files.filter{ $0.name != "." && $0.name != ".." }, id: \.name) { file in
                                SMBFileRowView(
                                    file: file,
                                    onTap: handleSMBFileTap
                                )
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            } else {
                EmptyStateView(
                    systemName: "link.slash",
                    title: "Not Connected",
                    message: "Connect to a TD Mouse to view files"
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.5), lineWidth: activePaneIndex == 0 ? 0.5 : 0)
        )
        .padding(2)
        .onTapGesture {
            activePaneIndex = 0
        }
    }
}

extension SMBPane {
    private func handleSMBFileTap(_ file: File) {
        if viewModel.isDirectory(file) {
            Task {
                try await viewModel.navigateToDirectory(file.name)
            }
        }
    }
}

struct SMBPane_Previews: PreviewProvider {
    static var previews: some View {
        SMBPane(
            activePaneIndex: .constant(0)
        )
        .environmentObject(FileTransferViewModel())
    }
}
