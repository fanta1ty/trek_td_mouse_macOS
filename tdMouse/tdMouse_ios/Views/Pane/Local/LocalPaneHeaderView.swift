//
//  LocalPaneHeaderView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import SwiftUI

struct LocalPaneHeaderView: View {
    @EnvironmentObject private var viewModel: LocalViewModel
    
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
            }
        }
    }
}

struct LocalPaneHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        LocalPaneHeaderView()
            .environmentObject(FileTransferViewModel())
            .environmentObject(LocalViewModel())
    }
}
