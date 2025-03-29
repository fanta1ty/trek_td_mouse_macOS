//
//  AudioPreviewView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import SwiftUI
import AVKit

struct AudioPreviewView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        controller.player = player
        
        // Set a custom content overlay for audio files
        let imageView = UIImageView(image: UIImage(systemName: "waveform"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.systemBlue.withAlphaComponent(0.6)
        controller.contentOverlayView?.addSubview(imageView)
        
        // Position the image in the center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        if let overlay = controller.contentOverlayView {
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 120),
                imageView.heightAnchor.constraint(equalToConstant: 120)
            ])
        }
        
        // Start playing audio automatically
        player.play()
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Player is already configured
    }
}
