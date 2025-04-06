//
//  SMBFileRowView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 31/3/25.
//

import SwiftUI
import SMBClient

struct SMBFileRowView: View {
    @EnvironmentObject private var viewModel: FileTransferViewModel
    @State private var isDragging: Bool = false
    
    private var fileIcon: String {
        if viewModel.isDirectory(file) { return "folder.fill" }
        else { return Helpers.iconForFile(file.name) }
    }
    
    let file: File
    let onTap: (File) -> Void
    let onSwipe: () -> Void
    
    var body: some View {
        Button {
            onTap(file)
        } label: {
            VStack(alignment: .leading) {
                HStack(spacing: 12) {
                    // File icon with background
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(file.fileColor().opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: fileIcon)
                            .font(.system(size: 18))
                            .foregroundStyle(file.fileColor())
                    }
                    
                    // File Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.name)
                            .font(.system(size: 16))
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                        
                        HStack {
                            if !viewModel.isDirectory(file) {
                                Text(Helpers.formatFileSize(file.size))
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(Helpers.formatDate(file.creationTime))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Action Button
                    Button {
                        onSwipe()
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(8)
//                .background(Color(UIColor.systemBackground))
                .contentShape(Rectangle())
                
                Divider()
                    .frame(height: 1)
                    .padding(.horizontal, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onDrag {
            isDragging = true
            
            let provider = NSItemProvider()
            
            let fileData: [String: String] = [
                "name": file.name,
                "isDirectory": viewModel.isDirectory(file) ? "true": "false",
                "type": "smbFile",
                "path": viewModel.currentDirectory.isEmpty ? file.name : "\(viewModel.currentDirectory)/\(file.name)"
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: fileData),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                provider.registerObject(jsonString as NSString, visibility: .all)
                
            } else {
                provider.registerObject(file.name as NSString, visibility: .all)
            }
            
            return provider
        }
        
    }
}

// MARK: - Private Functions

extension SMBFileRowView {
    
}
