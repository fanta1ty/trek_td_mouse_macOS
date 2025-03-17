//
//  LocalFilePreviewButton.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import SwiftUI

struct LocalFilePreviewButton: View {
    let file: LocalFile
    
    var body: some View {
        Button("View File") {
            Task {
                do {
                    // Get file data
                    let data = try Data(contentsOf: file.url)
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
        .disabled(file.isDirectory || !Helpers.isPreviewableFileType(file.name))
    }
}
