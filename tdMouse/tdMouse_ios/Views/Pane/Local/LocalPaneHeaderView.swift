//
//  LocalPaneHeaderView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import SwiftUI

struct LocalPaneHeaderView: View {
    @EnvironmentObject private var viewModel: LocalViewModel
    
    @Binding var isCreateFolderSheetPresented: Bool
    
    var body: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    viewModel.navigateUp()
                } label: {
                    Image(systemName: "arrow.up")
                        .foregroundColor(viewModel.canNavigateUp ? .blue : .gray)
                }
                .disabled(!viewModel.canNavigateUp)
                
                Button {
                    viewModel.refreshLocalFiles()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                
                Button {
                    isCreateFolderSheetPresented = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
    }
}

struct LocalPaneHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        LocalPaneHeaderView(
            isCreateFolderSheetPresented: .constant(false)
        )
        .environmentObject(FileTransferViewModel())
        .environmentObject(LocalViewModel())
    }
}
