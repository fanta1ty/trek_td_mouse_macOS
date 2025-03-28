//
//  PlaceholderView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI

struct DisconnectedPlaceholderView: View {
    // MARK: - Properties
    
    let connectAction: () -> Void
    var title: String = "Select a server to connect"
    var subtitle: String? = nil
    var iconName: String = "network.slash"
    var buttonText: String = "Connect to Server"
    var showAnimation: Bool = true
    
    // MARK: - State
    
    @State private var isAnimating = false
    @State private var iconOpacity = 0.8
    @State private var iconScale: CGFloat = 1.0
    @State private var buttonScale: CGFloat = 1.0
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 30) {
            // Icon with animation
            Image(systemName: iconName)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.secondary)
                .opacity(iconOpacity)
                .scaleEffect(iconScale)
                .animation(
                    showAnimation ?
                        .easeInOut(duration: 2).repeatForever(autoreverses: true) :
                        .default,
                    value: iconOpacity
                )
                .onAppear {
                    if showAnimation {
                        iconOpacity = 0.6
                        iconScale = 0.95
                    }
                }
            
            // Title and subtitle
            VStack(spacing: 10) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Connect button with hover effect
            Button(action: {
                // Trigger button press animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale = 0.95
                }
                
                // Restore original scale
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        buttonScale = 1.0
                    }
                }
                
                // Delay the action slightly for the animation to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    connectAction()
                }
            }) {
                HStack {
                    Image(systemName: "link")
                    Text(buttonText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .scaleEffect(buttonScale)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundPattern) // Add subtle background pattern
    }
    
    // MARK: - Background Pattern
    
    @ViewBuilder
    private var backgroundPattern: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<10) { index in
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(
                            width: CGFloat.random(in: 20...60),
                            height: CGFloat.random(in: 20...60)
                        )
                        .rotationEffect(.degrees(Double.random(in: 0...360)))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(0.3)
                }
            }
            .clipped()
            .opacity(0.3)
        }
    }
}

// MARK: - Convenience Initializers

extension DisconnectedPlaceholderView {
    /// Creates a DisconnectedPlaceholderView with a custom icon and title
    static func custom(
        title: String,
        iconName: String,
        buttonText: String = "Connect",
        action: @escaping () -> Void
    ) -> DisconnectedPlaceholderView {
        DisconnectedPlaceholderView(
            connectAction: action,
            title: title,
            iconName: iconName,
            buttonText: buttonText
        )
    }
    
    /// Creates a "No Connection" styled placeholder
    static func noConnection(action: @escaping () -> Void) -> DisconnectedPlaceholderView {
        DisconnectedPlaceholderView(
            connectAction: action,
            title: "No Connection Available",
            subtitle: "Please connect to an SMB server to access files",
            iconName: "network.slash",
            buttonText: "Connect Now"
        )
    }
    
    /// Creates an "Empty Folder" styled placeholder
    static func emptyFolder(action: @escaping () -> Void) -> DisconnectedPlaceholderView {
        DisconnectedPlaceholderView(
            connectAction: action,
            title: "No Files Found",
            subtitle: "This folder is empty",
            iconName: "folder",
            buttonText: "Upload Files",
            showAnimation: false
        )
    }
}

// MARK: - Preview

struct DisconnectedPlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default style
            DisconnectedPlaceholderView {
                print("Connect button tapped")
            }
            .previewDisplayName("Default")
            
            // No connection style
            DisconnectedPlaceholderView.noConnection {
                print("Connect button tapped")
            }
            .previewDisplayName("No Connection")
            
            // Empty folder style
            DisconnectedPlaceholderView.emptyFolder {
                print("Upload button tapped")
            }
            .previewDisplayName("Empty Folder")
            
            // Custom style
            DisconnectedPlaceholderView.custom(
                title: "Connect to SMB Server",
                iconName: "server.rack",
                buttonText: "Set Up Connection"
            ) {
                print("Custom button tapped")
            }
            .previewDisplayName("Custom Server")
            
            // With subtitle
            DisconnectedPlaceholderView(
                connectAction: { print("Connect tapped") },
                title: "Server Disconnected",
                subtitle: "Your connection to the server was lost. Please reconnect to continue accessing your files.",
                iconName: "wifi.exclamationmark",
                buttonText: "Reconnect"
            )
            .previewDisplayName("With Subtitle")
        }
        .previewLayout(.fixed(width: 400, height: 300))
    }
}
