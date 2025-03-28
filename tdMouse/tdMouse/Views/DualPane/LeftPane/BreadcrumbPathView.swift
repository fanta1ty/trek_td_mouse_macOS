//
//  BreadcrumbPathView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 28/3/25.
//

import SwiftUI

struct BreadcrumbPathView: View {
    @ObservedObject var viewModel: FileTransferViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Root (share) button
                Button(action: {
                    Task {
                        try await viewModel.listFiles("")
                    }
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 10))
                        Text(viewModel.shareName)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                if !viewModel.currentDirectory.isEmpty {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    // Split the path and create clickable segments
                    let pathComponents = viewModel.currentDirectory.components(separatedBy: "/")
                    ForEach(0..<pathComponents.count, id: \.self) { index in
                        let component = pathComponents[index]
                        
                        // Build the path up to this segment
                        let subPath = pathComponents[0...index].joined(separator: "/")
                        
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            Task {
                                try await viewModel.listFiles(subPath)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Text(component)
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                index == pathComponents.count - 1 ?
                                    Color.blue.opacity(0.15) :
                                    Color.secondary.opacity(0.1)
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color(NSColor.textBackgroundColor))
    }
}
