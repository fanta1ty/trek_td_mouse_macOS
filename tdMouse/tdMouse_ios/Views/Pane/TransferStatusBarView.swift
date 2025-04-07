//
//  TransferStatusBarView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 3/4/25.
//

import SwiftUI

struct TransferStatusBarView: View {
    @EnvironmentObject private var transferManager: TransferManager
    @EnvironmentObject private var smbViewModel: FileTransferViewModel
    @EnvironmentObject private var localViewModel: LocalViewModel
    
    var body: some View {
        Group {
            if let activeTransfer = transferManager.activeTransfer {
                HStack {
                    if activeTransfer == .toLocal {
                        Label("Downloading", systemImage: "arrow.down.circle")
                            .font(.subheadline)
                    } else {
                        Label("Uploading", systemImage: "arrow.up.circle")
                            .font(.subheadline)
                    }
                    
                    Text(transferManager.currentTransferItem)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    if transferManager.totalTransferItems > 0 {
                        Text("\(transferManager.processedTransferItems)/\(transferManager.totalTransferItems)")
                            .font(.caption.monospacedDigit())
                    }
                    
                    ProgressView(
                        value: Double(transferManager.processedTransferItems),
                        total: Double(max(1, transferManager.totalTransferItems))
                    )
                    .frame(width: 80)
                }
            } else {
                HStack {
                    Text("\(smbViewModel.files.count) TD Mouse files")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(localViewModel.localFiles.count) local files")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct TransferStatusBarView_Previews: PreviewProvider {
    static var previews: some View {
        TransferStatusBarView()
            .environmentObject(FileTransferViewModel())
            .environmentObject(LocalViewModel())
            .environmentObject(TransferManager())
    }
}
