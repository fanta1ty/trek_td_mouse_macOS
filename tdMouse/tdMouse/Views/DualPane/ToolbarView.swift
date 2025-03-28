//
//  ToolbarView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI

struct ToolbarView: View {
    @ObservedObject var smbViewModel: FileTransferViewModel
    @State private var isHovering: String?
    @Environment(\.colorScheme) private var colorScheme
    
    let onConnect: () -> Void
    let onRefresh: () -> Void
    let onNewFolder: () -> Void
    
    var body: some View {
        ZStack {
            // Background with subtle gradient and shadow
            backgroundLayer
            
            // Content
            VStack(spacing: 0) {
                // Main toolbar content
                HStack(spacing: 16) {
                    // App title and logo
                    appTitleSection
                    
                    Spacer()
                    
                    // Action buttons
                    actionButtonsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .frame(height: 60)
    }
    
    // MARK: - UI Components
    
    private var backgroundLayer: some View {
        Group {
            if colorScheme == .dark {
                // Dark mode background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(NSColor.windowBackgroundColor),
                        Color(NSColor.windowBackgroundColor).opacity(0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            } else {
                // Light mode background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(NSColor.windowBackgroundColor),
                        Color(NSColor.windowBackgroundColor).opacity(0.9)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
        }
    }
    
    private var appTitleSection: some View {
        HStack(spacing: 12) {
            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "network.badge.shield.half.filled")
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
            }
            
            // App title with subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text("SMB File Transfer")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                // Connection status subtitle
                connectionStatusText
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var connectionStatusText: some View {
        Group {
            switch smbViewModel.connectionState {
            case .connected:
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Connected to \(smbViewModel.credentials.host)")
                }
            case .connecting:
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                    Text("Connecting...")
                }
            case .error:
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("Connection error")
                }
            case .disconnected:
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 6, height: 6)
                    Text("Disconnected")
                }
            }
        }
        .animation(.easeInOut, value: smbViewModel.connectionState)
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Connect/Disconnect button
            ToolbarButton(
                title: smbViewModel.connectionState == .connected ? "Disconnect" : "Connect",
                icon: smbViewModel.connectionState == .connected ? "link.badge.minus" : "link",
                isHovering: isHovering == "connect",
                iconColor: smbViewModel.connectionState == .connected ? .red : .blue,
                prominent: smbViewModel.connectionState != .connected
            ) {
                onConnect()
            }
            .onHover { hovering in
                isHovering = hovering ? "connect" : nil
            }
            
            if smbViewModel.connectionState == .connected {
                Divider()
                    .frame(height: 24)
                
                // Refresh button
                ToolbarButton(
                    title: "Refresh",
                    icon: "arrow.clockwise",
                    isHovering: isHovering == "refresh",
                    iconColor: .blue
                ) {
                    onRefresh()
                }
                .onHover { hovering in
                    isHovering = hovering ? "refresh" : nil
                }
                
                // New folder button
                ToolbarButton(
                    title: "New Folder",
                    icon: "folder.badge.plus",
                    isHovering: isHovering == "newfolder",
                    iconColor: .green
                ) {
                    onNewFolder()
                }
                .onHover { hovering in
                    isHovering = hovering ? "newfolder" : nil
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct ToolbarButton: View {
    let title: String
    let icon: String
    let isHovering: Bool
    let iconColor: Color
    var prominent: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(prominent ? .white : (isHovering ? iconColor : .primary))
                
                // Text
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(prominent ? .white : .primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        prominent ? iconColor :
                            (isHovering ? iconColor.opacity(0.1) : Color.clear)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isHovering && !prominent ? iconColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
    }
}
