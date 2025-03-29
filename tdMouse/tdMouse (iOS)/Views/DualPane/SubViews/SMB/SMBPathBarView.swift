//
//  SMBPathBarView.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI

struct SMBPathBarView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    
    var body: some View {
        if viewModel.connectionState == .connected {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Text(viewModel.shareName + (viewModel.currentDirectory.isEmpty ? "" : "/" + viewModel.currentDirectory))
                        .lineLimit(1)
                        .font(.caption)
                        .padding(.horizontal)
                }
                .frame(height: 30)
            }
            .background(Color(UIColor.secondarySystemBackground))
        }
    }
}
