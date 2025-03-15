//
//  FileRowView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI
import SMBClient

struct FileRowView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    let file: File
    
    var body: some View {
        HStack {
            if viewModel.isDirectory(file) {
                Image(systemName: "folder")
                    .foregroundStyle(Color.accentColor)
            } else {
                Image(systemName: Helpers.iconForFile(file.name))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading) {
                Text(file.name)
                    .fontWeight(viewModel.isDirectory(file) ? .medium : .regular)
                
                HStack {
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
            
            Button {
                FileNotificationCenter.shared.postFileSelected(file)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
