//
//  LocalFileRowView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI
import Combine

struct LocalFileRowView: View {
    let file: LocalFile
    @ObservedObject var viewModel: LocalFileViewModel
    
    var body: some View {
        HStack {
            // Icon
            Image(systemName: file.icon)
                .foregroundColor(file.isDirectory ? .blue : .gray)
                .frame(width: 30)
            
            // Filename and details
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .fontWeight(file.isDirectory ? .medium : .regular)
                
                HStack(spacing: 8) {
                    if let date = file.modificationDate {
                        Text(formatDate(date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !file.isDirectory {
                        Text(viewModel.formatFileSize(file.size))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Quick action buttons
            if !file.isDirectory {
                if Helpers.isPreviewableFileType(file.name) {
                    Button {
                        // Preview file
                        NotificationCenter.default.post(
                            name: Notification.Name("PreviewLocalFile"),
                            object: file
                        )
                    } label: {
                        Image(systemName: "eye")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 4)
                }
                
                Button {
                    // Upload to SMB
                    NotificationCenter.default.post(
                        name: Notification.Name("UploadLocalFile"),
                        object: file
                    )
                } label: {
                    Image(systemName: "arrow.up.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
