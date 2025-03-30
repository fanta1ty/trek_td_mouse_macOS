//
//  TransferControlDivider.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI

struct TransferControlDivider: View {
    @EnvironmentObject var transferManager: TransferManager
    
    var body: some View {
        VStack(spacing: 4) {
            Divider()
            
            if let activeTransfer = transferManager.activeTransfer {
                // Transfer status with progress
                HStack {
                    Image(systemName: activeTransfer == .toLocal ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        .foregroundColor(activeTransfer == .toLocal ? .blue : .green)
                    
                    Text(transferManager.currentTransferItem)
                        .font(.caption)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if transferManager.totalTransferItems > 0 {
                        Text("\(transferManager.processedTransferItems)/\(transferManager.totalTransferItems)")
                            .font(.caption)
                            .monospacedDigit()
                    }
                    
                    ProgressView(value: Double(transferManager.processedTransferItems) / Double(max(1, transferManager.totalTransferItems)))
                        .frame(width: 80)
                    
                    Button(action: {
                        transferManager.cancelAllTransfers()
                    }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            } else {
                // Drag hint when no active transfer
                Text("Drag files between panels to transfer")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
            
            Divider()
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
}
