//
//  SMBPathIndicatorView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import SwiftUI

struct SMBPathIndicatorView: View {
    @EnvironmentObject private var viewModel: FileTransferViewModel
    
    var body: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    Image(systemName: "server.rack")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Share name as first component
                    Text(viewModel.shareName)
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    // Show path component if there's a current directory
                    if !viewModel.currentDirectory.isEmpty {
                        ForEach(getPath(), id: \.self) { component in
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            Text(component)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }
            
            Spacer()
        }
    }
}

extension SMBPathIndicatorView {
    private func getPath() -> [String] {
        guard !viewModel.currentDirectory.isEmpty else {
            return []
        }
        
        return viewModel.currentDirectory
            .split(separator: "/")
            .map(String.init)
    }
}

struct SMBPathIndicatorView_Previews: PreviewProvider {
    static var previews: some View  {
        SMBPathIndicatorView()
            .environmentObject(FileTransferViewModel())
            .environmentObject(LocalViewModel())
    }
}
