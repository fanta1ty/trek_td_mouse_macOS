//
//  LocalHeaderView.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI

struct LocalHeaderView: View {
    @ObservedObject var viewModel: LocalFileViewModel
    
    var body: some View {
        HStack {
            Text("Local Files")
                .font(.headline)
                .padding(.leading)
            
            Spacer()
            
            Button {
                viewModel.selectDirectory()
            } label: {
                Image(systemName: "folder.badge.plus")
            }
            .padding(.horizontal, 4)
            
            Button(action: {
                viewModel.navigateUp()
            }) {
                Image(systemName: "arrow.up")
            }
            .disabled(!viewModel.canNavigateUp)
            .padding(.horizontal, 4)
            
            Button(action: {
                viewModel.refreshFiles()
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.tertiarySystemBackground))
    }
}

struct LocalHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        LocalHeaderView(
            viewModel: LocalFileViewModel()
        )
    }
}
