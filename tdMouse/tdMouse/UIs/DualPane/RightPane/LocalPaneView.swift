//
//  LocalPaneView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI
import UniformTypeIdentifiers
import SMBClient

struct LocalPaneView: View {
    @ObservedObject var viewModel: LocalFileViewModel
    let onFileTap: (LocalFile) -> Void
    let onFileDrop: ([File]) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Local Files")
                    .font(.headline)
                    .padding(.leading)
                
                Spacer()
                
                Button(action: {
                    viewModel.navigateUp()
                }) {
                    Image(systemName: "arrow.up")
                }
                .disabled(!viewModel.canNavigateUp)
                .padding(.trailing)
            }
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Path bar
            HStack {
                Text(viewModel.currentDirectoryURL.path)
                    .truncationMode(.middle)
                    .lineLimit(1)
                    .font(.caption)
                    .padding(.horizontal)
            }
            .frame(height: 24)
            .background(Color(NSColor.textBackgroundColor))
            
            // File list
            List {
                ForEach(viewModel.files, id: \.name) { file in
                    LocalFileRow(file: file, viewModel: viewModel, onFileTap: onFileTap)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .onDrop(of: [.plainText], isTargeted: nil) { providers -> Bool in
            handleDrop(providers)
            return true
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Void {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { secureData, error in
                guard error == nil else { return }
                
                DispatchQueue.main.async {
                    if let string = secureData as? String {
                        NotificationCenter.default.post(
                            name: Notification.Name("ProcessSMBFileDrop"),
                            object: string
                        )
                    } else if let nsString = secureData as? NSString {
                        NotificationCenter.default.post(
                            name: Notification.Name("ProcessSMBFileDrop"),
                            object: nsString as String
                        )
                    } else if let data = secureData as? Data,
                              let string = String(data: data, encoding: .utf8) {
                        NotificationCenter.default.post(
                            name: Notification.Name("ProcessSMBFileDrop"),
                            object: string
                        )
                    }
                }
            }
        }
    }
}

struct LocalPaneView_Previews: PreviewProvider {
    static var previews: some View {
        LocalPaneView(
            viewModel: LocalFileViewModel(),
            onFileTap: { _ in},
            onFileDrop: { _ in }
        )
    }
}
