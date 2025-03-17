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
    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        let playerView = AVPlayerView()
        playerView.controlsStyle = .inline
        playerView.frame = container.bounds
        playerView.autoresizingMask = [.width, .height]
        container.addSubview(playerView)
        
        let player = AVPlayer(url: url)
        playerView.player = player
        
        return container
    }
    
    typealias NSViewType = NSView
    
    let url: URL
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let playerView = nsView.subviews.first as? AVPlayerView {
            let player = AVPlayer(url: url)
            playerView.player = player
        }
    }
}
