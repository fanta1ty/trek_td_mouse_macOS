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
    @State private var showPreview: Bool = false
    
    let file: File
    
    var body: some View {
        Button("View File") {
            showPreview = true
        }
        .disabled(viewModel.isDirectory(file) || !Helpers.isPreviewableFileType(file.name))
        .sheet(isPresented: $showPreview) {
            UniversalFilePreviewView(
                title: file.name,
                fileProvider: {
                    return try await viewModel.downloadFile(fileName: file.name)
                },
                fileExtension: file.name.components(separatedBy: ".").last ?? ""
            )
        }
    }
}
