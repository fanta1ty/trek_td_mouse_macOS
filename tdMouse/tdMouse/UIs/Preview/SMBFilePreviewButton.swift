//
//  SMBFilePreviewButton.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import SwiftUI
import SMBClient

struct SMBFilePreviewButton: View {
    @ObservedObject var viewModel: FileTransferViewModel
    let file: File
    
    var body: some View {
        Button("View File") {
            Task {
                do {
                    // Download the file data
                    let data = try await viewModel.downloadFile(fileName: file.name)
                    let fileExt = file.name.components(separatedBy: ".").last ?? ""
                    
                    // Display file using preview manager
                    DispatchQueue.main.async {
                        FilePreviewManager.shared.showPreview(
                            title: "Preview: \(file.name)",
                            data: data,
                            fileExtension: fileExt,
                            originalFileName: file.name
                        )
                    }
                } catch {
                    print("Preview error: \(error)")
                }
            }
        }
        .disabled(viewModel.isDirectory(file) || !Helpers.isPreviewableFileType(file.name))
    }
}
