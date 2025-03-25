//
//  ImagePreviewView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import SwiftUI
import Foundation

struct ImagePreviewView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.animates = true
        return imageView
    }
    
    typealias NSViewType = NSImageView
    
    let url: URL
    
    func updateNSView(_ nsView: NSImageView, context: Context) {
        if let image = NSImage(contentsOf: url) {
            nsView.image = image
        }
    }
}
