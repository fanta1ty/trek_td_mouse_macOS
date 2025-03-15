//
//  LocalFileRowView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI
import Combine

struct LocalFileRowView: View {
    @ObservedObject var viewModel: LocalFileViewModel
    
    let file: LocalFile
    
    var body: some View {
        HStack {
            // Icon
            Image(systemName: file.icon)
                .foregroundStyle(file.isDirectory ? Color.accentColor : .secondary)
            
            // Filename and details
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .fontWeight(file.isDirectory ? .medium : .regular)
                
                HStack(spacing: 8) {
                    if let date = file.modificationDate {
                        Text(Helpers.formatDate(date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if !file.isDirectory {
                        Text(Helpers.formatFileSize(UInt64(file.size)))
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

struct LocalFileRowView_Previews: PreviewProvider {
    static var previews: some View {
        LocalFileRowView(
            viewModel: LocalFileViewModel(),
            file: .init(
                name: "Name",
                url: .homeDirectory,
                isDirectory: false,
                size: 100)
        )
    }
}
