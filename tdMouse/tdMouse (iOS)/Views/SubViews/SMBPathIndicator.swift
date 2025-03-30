//
//  SMBPathIndicator.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI

struct SMBPathIndicator: View {
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
                        Image(systemName: "folder.fill")
                            .font(.system(size: 10))
                        Text(viewModel.shareName)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
                
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
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
}

struct LocalPathIndicator: View {
    @ObservedObject var viewModel: LocalFileViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                let pathComponents = viewModel.currentDirectoryURL.pathComponents
                
                ForEach(0..<pathComponents.count, id: \.self) { index in
                    let component = pathComponents[index]
                    
                    // Skip empty components
                    if !component.isEmpty {
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        // Create a path URL up to this component
                        let subPath = pathComponents[0...index].joined(separator: "/")
                        let subPathURL = URL(fileURLWithPath: subPath)
                        
                        Button(action: {
                            viewModel.navigateToURL(subPathURL)
                        }) {
                            HStack(spacing: 4) {
                                // Choose appropriate icon
                                if component == "/" {
                                    Image(systemName: "iphone")
                                        .font(.system(size: 10))
                                } else if index == 0 {
                                    Image(systemName: "externaldrive.fill")
                                        .font(.system(size: 10))
                                } else {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 10))
                                }
                                
                                Text(component == "/" ? "Root" : component)
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                index == pathComponents.count - 1 ?
                                    Color.green.opacity(0.15) :
                                    Color.secondary.opacity(0.1)
                            )
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
}
