//
//  EmptyFolderView.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI  

enum FolderType {
    case smb, local
}

struct EmptyFolderView: View {
    let type: FolderType
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.minus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .opacity(0.6)
            
            Text("This folder is empty")
                .font(.headline)
            
            Text(type == .smb
                ? "Upload files to this SMB folder"
                : "Add files to this local folder")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
