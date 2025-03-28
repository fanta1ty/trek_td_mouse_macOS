//
//  VideoPreviewView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import SwiftUI
import Foundation
import AVKit

struct VideoPreviewView: NSViewRepresentable {
    let url: URL
    var isPlaying: Bool = true
    
    // Additional optional configuration properties
    var autoPlay: Bool = true
    var showsControls: Bool = true
    var looping: Bool = false
    
    // Action callback for playback state changes
    var onPlaybackStateChanged: ((Bool) -> Void)? = nil
    
    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        
        // Configure the player view
        playerView.controlsStyle = showsControls ? .inline : .none
        playerView.showsFullScreenToggleButton = true
        
        // Create and configure the player
        let player = AVPlayer(url: url)
        playerView.player = player
        
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
        
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        // Update player if URL changes
        if nsView.player?.currentItem?.asset != AVAsset(url: url) {
            let player = AVPlayer(url: url)
            nsView.player = player
            
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
        
        // Update player state based on isPlaying
        if context.coordinator.isPlaying != isPlaying {
            if isPlaying {
                nsView.player?.play()
            } else {
                nsView.player?.pause()
            }
            context.coordinator.isPlaying = isPlaying
        }
        
        // Update controls visibility
        nsView.controlsStyle = showsControls ? .inline : .none
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator class to handle player callbacks
    class Coordinator: NSObject {
        private var parent: VideoPreviewView
        var isPlaying: Bool = false
        
        init(_ parent: VideoPreviewView) {
            self.parent = parent
            super.init()
        }
        
        @objc func playerItemDidReachEnd(notification: Notification) {
            if parent.looping {
                // If looping is enabled, seek back to beginning and play again
                if let playerItem = notification.object as? AVPlayerItem,
                   let player = notification.object as? AVPlayer {
                    playerItem.seek(to: .zero, completionHandler: { _ in
                        if self.isPlaying {
                            player.play()
                        }
                    })
                }
            } else {
                // Update isPlaying state
                isPlaying = false
                parent.onPlaybackStateChanged?(false)
            }
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// Example usage:
struct VideoPreviewWrapper: View {
    let videoURL: URL
    @State private var isPlaying = true
    
    var body: some View {
        VStack {
            VideoPreviewView(
                url: videoURL,
                isPlaying: isPlaying,
                autoPlay: true,
                showsControls: true,
                looping: false,
                onPlaybackStateChanged: { newState in
                    isPlaying = newState
                }
            )
            .frame(height: 360)
            
            Button(action: {
                isPlaying.toggle()
            }) {
                HStack {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                    Text(isPlaying ? "Pause" : "Play")
                }
            }
            .buttonStyle(.borderless)
            .padding()
        }
    }
}

// Preview provider
struct VideoPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        // You would provide an actual video URL for real usage
        let sampleURL = URL(string: "https://example.com/sample.mp4")!
        
        return VideoPreviewWrapper(videoURL: sampleURL)
    }
}
