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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if let activeTransfer = transferManager.activeTransfer, transferManager.totalTransferItems > 0 {
            multiFileTransferStatus(activeTransfer)
                .transition(.opacity)
        } else if let activeTransfer = transferManager.activeTransfer {
            singleFileTransferStatus(activeTransfer)
                .transition(.opacity)
        } else {
            connectionStatus
                .transition(.opacity)
        }
    }
    
    // Status for when transferring multiple files (like a folder)
    private func multiFileTransferStatus(
        _ activeTransfer: TransferDirection
    ) -> some View {
        HStack(spacing: 12) {
            // Transfer icon with styled background
            transferIcon(activeTransfer)
            
            // Transfer description with filename
            VStack(alignment: .leading, spacing: 2) {
                // Current operation
                Text(activeTransfer == .toLocal ? "Downloading" : "Uploading")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // Current file with truncation
                Text(transferManager.currentTransferItem)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            // Progress information
            HStack(spacing: 12) {
                // Progress counters
                VStack(alignment: .trailing, spacing: 2) {
                    // Progress percentage
                    let progress = transferManager.processedTransferItems > 0 && transferManager.totalTransferItems > 0 ?
                        Double(transferManager.processedTransferItems) / Double(transferManager.totalTransferItems) : 0
                    
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .monospacedDigit()
                    
                    // Item counts
                    Text("\(transferManager.processedTransferItems) of \(transferManager.totalTransferItems)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                
                // Progress bar with animation
                ProgressView(value: transferManager.processedTransferItems > 0 && transferManager.totalTransferItems > 0 ?
                             Double(transferManager.processedTransferItems) / Double(transferManager.totalTransferItems) : 0)
                .frame(width: 120)
                .scaleEffect(y: 1.2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(statusBarBackground)
        .animation(.easeInOut, value: transferManager.processedTransferItems)
    }
    
    // Status for single file transfers
    private func singleFileTransferStatus(
        _ activeTransfer: TransferDirection
    ) -> some View {
        HStack(spacing: 12) {
            // Transfer icon with styled background
            transferIcon(activeTransfer)
            
            // Transfer description with filename
            VStack(alignment: .leading, spacing: 2) {
                Text(activeTransfer == .toLocal ? "Downloading" : "Uploading")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transferManager.currentTransferItem)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            // Progress information
            HStack(spacing: 12) {
                // Progress percentage
                Text("\(Int(smbViewModel.transferProgress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .frame(width: 40, alignment: .trailing)
                
                // Progress bar with animation
                ProgressView(value: smbViewModel.transferProgress)
                    .frame(width: 120)
                    .scaleEffect(y: 1.2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(statusBarBackground)
        .animation(.easeInOut, value: smbViewModel.transferProgress)
    }
    
    // Default connection status
    private var connectionStatus: some View {
        HStack(spacing: 12) {
            // Connection status
            connectionStatusBadge
            
            Spacer()
            
            // File stats with icons
            HStack(spacing: 16) {
                fileCountBadge(
                    count: smbViewModel.files.count,
                    type: "SMB",
                    icon: "server.rack",
                    color: .blue
                )
                
                fileCountBadge(
                    count: localViewModel.files.count,
                    type: "Local",
                    icon: "folder",
                    color: .green
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(statusBarBackground)
    }
    
    // Helper view for connection status badge
    private var connectionStatusBadge: some View {
        HStack(spacing: 8) {
            // Status indicator
            if smbViewModel.connectionState == .connected {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                
                // Connected host details
                VStack(alignment: .leading, spacing: 1) {
                    Text("Connected to \(smbViewModel.credentials.host)")
                        .font(.subheadline)
                    
                    if !smbViewModel.shareName.isEmpty {
                        Text("Share: \(smbViewModel.shareName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else if case .connecting = smbViewModel.connectionState {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 8, height: 8)
                
                Text("Connecting...")
                    .font(.subheadline)
            } else {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                
                Text("Disconnected")
                    .font(.subheadline)
            }
        }
    }
    
    // Helper view for file count badge
    private func fileCountBadge(count: Int, type: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 24, height: 24)
                
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
                
                Text(type)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // Helper view for transfer icon
    private func transferIcon(_ direction: TransferDirection) -> some View {
        ZStack {
            Circle()
                .fill(direction == .toLocal ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                .frame(width: 30, height: 30)
            
            Image(systemName: direction == .toLocal ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(direction == .toLocal ? .blue : .green)
        }
    }
    
    // Consistent background style
    private var statusBarBackground: some View {
        Group {
            if colorScheme == .dark {
                Color(NSColor.windowBackgroundColor).opacity(0.95)
            } else {
                Color(NSColor.windowBackgroundColor)
                    .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: -1)
            }
        }
    }
}

