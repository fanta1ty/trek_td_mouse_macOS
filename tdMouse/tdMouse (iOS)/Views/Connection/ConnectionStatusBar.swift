//
//  ConnectionStatusBar.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI
import SMBClient

struct ConnectionStatusBar: View {
    @ObservedObject var viewModel: FileTransferViewModel
    
    var body: some View {
        HStack {
            // Connection indicator
            Circle()
                .fill(viewModel.connectionState == .connected ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            
            // Connection info
            if viewModel.connectionState == .connected {
                Text("Connected to \(viewModel.credentials.host)")
                    .font(.subheadline)
            } else {
                Text("Not connected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Share info if connected
            if !viewModel.shareName.isEmpty {
                Text("Share: \(viewModel.shareName)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }
}

//struct SMBFileList: View {
//    @EnvironmentObject var smbViewModel: FileTransferViewModel
//    @EnvironmentObject var transferManager: TransferManager
//    
//    var body: some View {
//        List {
//            ForEach(smbViewModel.files.filter { $0.name != "." && $0.name != ".." }, id: \.name) { file in
//                SMBFileRow(file: file)
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        handleFileTap(file)
//                    }
//                    .onDrag {
//                        // Enable drag with file data
//                        let fileInfo = [
//                            "name": file.name,
//                            "isDirectory": file.isDirectory ? "true" : "false",
//                            "type": "smbFile"
//                        ]
//                        
//                        if let data = try? JSONSerialization.data(withJSONObject: fileInfo),
//                           let string = String(data: data, encoding: .utf8) {
//                            return NSItemProvider(object: string as NSString)
//                        }
//                        
//                        return NSItemProvider(object: file.name as NSString)
//                    }
//            }
//        }
//        .listStyle(.plain)
//    }
//    
//    private func handleFileTap(_ file: File) {
//        if smbViewModel.isDirectory(file) {
//            Task {
//                try await smbViewModel.navigateToDirectory(file.name)
//            }
//        } else {
//            // Preview or download file
//            // Will be implemented in Step 6
//        }
//    }
//}
