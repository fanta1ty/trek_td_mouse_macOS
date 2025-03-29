//
//  VideoPreviewView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import SwiftUI
import AVKit

struct VideoPreviewView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        
        // Configure player
        controller.player = player
        controller.showsPlaybackControls = true
        
        // Set video gravity (aspect fit)
        controller.videoGravity = .resizeAspect
        
        // Add playback observer
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            // Loop video
            player.seek(to: .zero)
            player.play()
        }
        
        // Start playing
        player.play()
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Player is already configured
    }
    
    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: ()) {
        // Clean up resources
        uiViewController.player?.pause()
        NotificationCenter.default.removeObserver(self)
    }
}
