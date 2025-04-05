//
//  SMBPaneHeaderView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import SwiftUI

struct SMBPaneHeaderView: View {
    @EnvironmentObject private var viewModel: FileTransferViewModel
    
    var body: some View {
        HStack {
            Spacer()
            
            if viewModel.connectionState == .connected {
                // Navigation controls
                HStack(spacing: 12) {
                    Button {
                        Task {
                            try await viewModel.navigateUp()
                        }
                    } label: {
                        Image(systemName: "arrow.up")
                            .foregroundStyle(viewModel.currentDirectory.isEmpty ? .gray : .blue)
                    }
                    .disabled(viewModel.currentDirectory.isEmpty)
                    
                    Button {
                        Task {
                            try await viewModel.listFiles(viewModel.currentDirectory)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct SMBPaneHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SMBPaneHeaderView()
            .environmentObject(FileTransferViewModel())
            .environmentObject(LocalViewModel())
    }
}
