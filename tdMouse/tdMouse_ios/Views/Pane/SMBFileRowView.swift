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
    @State private var showActionSheet: Bool = false
    
    private var fileIcon: String {
        if viewModel.isDirectory(file) { return "folder.fill" }
        else { return Helpers.iconForFile(file.name) }
    }
    
    let file: File
    let onTap: (File) -> Void
    
    var body: some View {
        Button {
            onTap(file)
        } label: {
            HStack(spacing: 12) {
                // File icon with background
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(fileColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Private Functions

extension SMBFileRowView {
    private var fileColor: Color {
        if viewModel.isDirectory(file) {
            return .blue
        } else {
            let ext = file.name.components(separatedBy: ".").last?.lowercased() ?? ""
            switch ext {
            case "pdf":
                return .red
            case "jpg", "jpeg", "png", "gif", "heic":
                return .green
            case "mp3", "wav", "m4a":
                return .pink
            case "mp4", "mov", "avi":
                return .purple
            case "doc", "docx":
                return .blue
            case "xls", "xlsx":
                return .green
            case "ppt", "pptx":
                return .orange
            case "zip", "rar", "7z":
                return .gray
            default:
                return .secondary
            }
        }
    }
}
