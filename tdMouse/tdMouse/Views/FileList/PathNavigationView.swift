//
//  PathNavigationView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI

struct PathNavigationView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                Task {
                    try await viewModel.navigateUp()
                }
            }, label: {
                Image(systemName: "arrow.up")
            })
            .disabled(viewModel.currentDirectory.isEmpty)
            
            Text(viewModel.currentDirectory.isEmpty ? "/" : viewModel.currentDirectory)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.separatorColor).opacity(0.2))
    }
    
}
