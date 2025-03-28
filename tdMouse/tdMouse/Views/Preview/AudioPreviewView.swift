//
//  AudioPreviewView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import SwiftUI
import Foundation
import AVKit

struct AudioPreviewView: NSViewRepresentable {
    let url: URL
    var isPlaying: Bool = true
    var autoPlay: Bool = true
    var showsControls: Bool = true
    var looping: Bool = false
    var showWaveform: Bool = true
    
    // Action callback for playback state changes
    var onPlaybackStateChanged: ((Bool) -> Void)? = nil
    
    func makeNSView(context: Context) -> NSView {
        // Create main container
        let container = NSView()
        
        // Create player view
        let playerView = AVPlayerView()
        playerView.controlsStyle = showsControls ? .inline : .none
        playerView.frame = container.bounds
        playerView.autoresizingMask = [.width, .height]
        
        // Create a player
        let player = AVPlayer(url: url)
        playerView.player = player
        context.coordinator.setPlayer(player)
        
        // Add the player view to the container
        container.addSubview(playerView)
        
        // Set up notification for when playback ends
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        
        // Start playback if autoPlay is enabled
        if autoPlay {
            player.play()
            context.coordinator.isPlaying = true
        }
        
        // Store a reference to the player view in the coordinator
        context.coordinator.playerView = playerView
        
        return container
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let playerView = nsView.subviews.first as? AVPlayerView else { return }
        
        // If the URL changed, update the player
        if playerView.player?.currentItem?.asset != AVAsset(url: url) {
            let player = AVPlayer(url: url)
            playerView.player = player
            context.coordinator.setPlayer(player)
            
            // Set up notification for when playback ends
            NotificationCenter.default.addObserver(
                context.coordinator,
                selector: #selector(Coordinator.playerItemDidReachEnd),
                name: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem
            )
            
            // Start playback if autoPlay is enabled
            if autoPlay {
                player.play()
                context.coordinator.isPlaying = true
            }
        }
        
        // Update controls style
        playerView.controlsStyle = showsControls ? .inline : .none
        
        // Update playback state if needed
        if context.coordinator.isPlaying != isPlaying {
            if isPlaying {
                playerView.player?.play()
            } else {
                playerView.player?.pause()
            }
            context.coordinator.isPlaying = isPlaying
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator class to handle player callbacks
    class Coordinator: NSObject {
        private var parent: AudioPreviewView
        var isPlaying: Bool = false
        weak var playerView: AVPlayerView?
        private weak var currentPlayer: AVPlayer?
        
        init(_ parent: AudioPreviewView) {
            self.parent = parent
            super.init()
        }
        
        func setPlayer(_ player: AVPlayer) {
            currentPlayer = player
        }
        
        @objc func playerItemDidReachEnd(notification: Notification) {
            if parent.looping {
                // If looping is enabled, seek back to beginning and play again
                if let playerItem = notification.object as? AVPlayerItem {
                    playerItem.seek(to: .zero, completionHandler: { _ in
                        if self.isPlaying {
                            self.currentPlayer?.play()
                        }
                    })
                }
            } else {
                // Update isPlaying state
                isPlaying = false
                DispatchQueue.main.async {
                    self.parent.onPlaybackStateChanged?(false)
                }
            }
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// Modern audio player with improved UI
struct ModernAudioPlayer: View {
    let audioURL: URL
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var duration: Double = 0
    @State private var showingOptions = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Audio player component
            AudioPreviewView(
                url: audioURL,
                isPlaying: isPlaying,
                autoPlay: false,
                showsControls: false,
                looping: false,
                onPlaybackStateChanged: { newState in
                    isPlaying = newState
                }
            )
            .frame(height: 0)
            .opacity(0)
            
            // Custom controls
            VStack(spacing: 20) {
                // Waveform visualization (placeholder)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(height: 100)
                    .overlay(
                        VStack {
                            HStack(spacing: 2) {
                                ForEach(0..<30, id: \.self) { i in
                                    let height = CGFloat.random(in: 5...50)
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.blue)
                                        .frame(width: 8, height: height)
                                }
                            }
                            .opacity(0.7)
                        }
                    )
                    .padding(.vertical, 8)
                
                // Playback controls
                HStack(spacing: 20) {
                    // Time indicator
                    Text(formatTime(progress))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                    
                    // Seek back button
                    Button(action: {
                        // Implementation for seeking back
                    }) {
                        Image(systemName: "gobackward.10")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    
                    // Play/pause button
                    Button(action: {
                        isPlaying.toggle()
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    
                    // Seek forward button
                    Button(action: {
                        // Implementation for seeking forward
                    }) {
                        Image(systemName: "goforward.10")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    
                    // Remaining time
                    Text(formatTime(duration - progress))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Audio info
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Audio Track")
                            .font(.headline)
                        
                        Text(audioURL.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Options menu
                    Button(action: {
                        showingOptions.toggle()
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingOptions) {
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                // Download action
                            }) {
                                Label("Download Audio", systemImage: "arrow.down.circle")
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                            
                            Button(action: {
                                // Share action
                            }) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .frame(width: 200)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .onAppear {
            // Placeholder for demo - in real implementation you would get actual duration
            duration = 180.0 // 3 minutes
            
            // Simulate progress updates for demo
            Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    if isPlaying {
                        progress = min(progress + 1, duration)
                    }
                }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// Preview
struct AudioPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Standard Audio Preview")
                .font(.headline)
                .padding()
            
            AudioPreviewView(
                url: URL(string: "file:///path/to/sample.mp3")!,
                autoPlay: false
            )
            .frame(height: 100)
            .padding()
            
            Divider()
                .padding()
            
            Text("Modern Audio Player")
                .font(.headline)
                .padding()
            
            ModernAudioPlayer(audioURL: URL(string: "file:///path/to/sample.mp3")!)
                .frame(width: 400)
                .padding()
        }
        .frame(height: 600)
    }
}
