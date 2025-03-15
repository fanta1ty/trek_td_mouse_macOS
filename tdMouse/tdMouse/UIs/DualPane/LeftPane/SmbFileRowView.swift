//
//  SmbFileRowView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI
import SMBClient

struct SmbFileRowView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    let file: File
    
    var body: some View {
        HStack {
            // Icon
            if viewModel.isDirectory(file) {
                Image(systemName: "folder")
                    .foregroundStyle(Color.accentColor)
            } else {
                Image(systemName: Helpers.iconForFile(file.name))
                    .foregroundStyle(.secondary)
            }
            
            // Filename and details
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .fontWeight(viewModel.isDirectory(file) ? .medium : .regular)
                
                HStack(spacing: 8) {
                    Text(Helpers.formatDate(file.lastWriteTime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if !viewModel.isDirectory(file) {
                        Text(Helpers.formatFileSize(file.size))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
