//
//  LocalFilePreviewButton.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import SwiftUI

struct LocalFilePreviewButton: View {
    @State private var showPreview: Bool = false
    let file: LocalFile
    
    var body: some View {
        Button("View File") {
            showPreview = true
        }
        .disabled(file.isDirectory || !Helpers.isPreviewableFileType(file.name))
        .sheet(isPresented: $showPreview) {
            UniversalFilePreviewView(
                title: file.name,
                fileProvider: {
                    return try Data(contentsOf: file.url)
                },
                fileExtension: file.name.components(separatedBy: ".").last ?? ""
            )
        }
    }
}
