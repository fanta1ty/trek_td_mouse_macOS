//
//  FileListView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI
import SMBClient

struct FileListView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @Binding var selectedFile: File?
    @Binding var showFileActions: Bool
    
    var body: some View {
        List {
            ForEach(viewModel.files, id: \.name) { file in
                FileRowView(viewModel: viewModel, file: file)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        
                    }
                    .contextMenu {
                        
                    }
            }
        }
        .listStyle(InsetListStyle())
    }
}

struct FileListView_PReview: PreviewProvider {
    static var previews: some View {
        FileListView(
            viewModel: FileTransferViewModel(),
            selectedFile: .constant(nil),
            showFileActions: .constant(true)
        )
    }
}
