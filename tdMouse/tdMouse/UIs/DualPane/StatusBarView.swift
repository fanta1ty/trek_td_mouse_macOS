//
//  StatusBarView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI

struct StatusBarView: View {
    @ObservedObject var smbViewModel: FileTransferViewModel
    @ObservedObject var localViewModel: LocalFileViewModel
    @ObservedObject var transferManager: TransferManager
    
    var body: some View {
        if let activeTransfer = transferManager.activeTransfer, transferManager.totalTransferItems > 0 {
            multiFileTransferStatus(activeTransfer)
        } else if let activeTransfer = transferManager.activeTransfer {
            singleFileTransferStatus(activeTransfer)
        } else {
            connectionStatus
        }
    }
    
    // Status for when transferring multiple files (like a folder)
    private func multiFileTransferStatus(
        _ activeTransfer: TransferDirection
    ) -> some View {
        HStack {
            // Transfer icon and description
            switch activeTransfer {
            case .toLocal:
                Image(systemName: "arrow.down")
                    .foregroundColor(.blue)
                Text("Downloading \(transferManager.currentTransferItem)")
            case .toRemote:
                Image(systemName: "arrow.up")
                    .foregroundColor(.blue)
                Text("Uploading \(transferManager.currentTransferItem)")
            }
            
            Spacer()
            
            // Progress information
            Text("\(transferManager.processedTransferItems)/\(transferManager.totalTransferItems) items")
                .font(.caption)
            
            let progress = transferManager.processedTransferItems > 0 && transferManager.totalTransferItems > 0 ?
            Double(transferManager.processedTransferItems) / Double(transferManager.totalTransferItems) : 0
            
            ProgressView(value: progress)
                .frame(width: 100)
            
            Text("\(Int(progress * 100))%")
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
        }
        .padding(8)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // Status for single file transfers
    private func singleFileTransferStatus(
        _ activeTransfer: TransferDirection
    ) -> some View {
        HStack {
            // Transfer icon and description
            switch activeTransfer {
            case .toLocal:
                Image(systemName: "arrow.down")
                    .foregroundColor(.blue)
                Text("Downloading \(transferManager.currentTransferItem)")
            case .toRemote:
                Image(systemName: "arrow.up")
                    .foregroundColor(.blue)
                Text("Uploading \(transferManager.currentTransferItem)")
            }
            
            Spacer()
            
            // Progress bar - use the SMB view model's progress
            ProgressView(value: smbViewModel.transferProgress)
                .frame(width: 100)
            
            Text("\(Int(smbViewModel.transferProgress * 100))%")
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
        }
        .padding(8)
        .background(Color(NSColor.windowBackgroundColor))
        
    }
    
    // Default connection status
    private var connectionStatus: some View {
        HStack {
            if smbViewModel.connectionState == .connected {
                Image(systemName: "circle.fill")
                    .foregroundColor(.green)
                    .frame(width: 10, height: 10)
                Text("Connected to \(smbViewModel.credentials.host)")
            } else {
                Image(systemName: "circle.fill")
                    .foregroundColor(.red)
                    .frame(width: 10, height: 10)
                Text("Disconnected")
            }
            
            Spacer()
            
            let smbItemCount = smbViewModel.files.count
            let localItemCount = localViewModel.files.count
            
            Text("\(smbItemCount) items on server • \(localItemCount) local items")
                .font(.caption)
        }
        .padding(8)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct StatusBarView_Preview: PreviewProvider {
    static var previews: some View {
        StatusBarView(
            smbViewModel: FileTransferViewModel(),
            localViewModel: LocalFileViewModel(),
            transferManager: TransferManager()
        )
    }
}
