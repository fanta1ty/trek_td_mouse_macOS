//
//  FileListContainerView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI
import SMBClient

struct FileListContainerView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    @State private var selectedFile: File?
    @State private var isFileActionSheetPresented = false
    
    var body: some View {
        VStack {
            PathNavigationView(viewModel: viewModel)
            
            FileListView(
                viewModel: viewModel,
                selectedFile: $selectedFile,
                showFileActions: $isFileActionSheetPresented
            )
            
            if viewModel.transferState != .none {
                TransferProgressView(
                    transferState: viewModel.transferState,
                    progress: viewModel.transferProgress
                )
            }
        }
        .sheet(isPresented: $isFileActionSheetPresented) {
            if let file = selectedFile {
                FileActionSheet(
                    viewModel: viewModel,
                    isPresented: $isFileActionSheetPresented,
                    file: file
                )
            }
        }
    }
}

struct FileListContainerView_Previews: PreviewProvider {
    static var previews: some View {
        FileListContainerView(viewModel: FileTransferViewModel())
    }
}
