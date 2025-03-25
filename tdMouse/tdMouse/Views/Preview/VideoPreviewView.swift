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
    func makeNSView(context: Context) -> AVPlayerView {
       let playerView = AVPlayerView()
        playerView.controlsStyle = .inline
        return playerView
    }
    
    typealias NSViewType = AVPlayerView
    
    let url: URL
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        let player = AVPlayer(url: url)
        nsView.player = player
    }
}
