//
//  TextPreviewView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import SwiftUI
import Foundation

struct TextPreviewView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        
        textView.isEditable = false
        textView.isSelectable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        
        return scrollView
    }
    
    typealias NSViewType = NSScrollView
    
    let url: URL
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        do {
            let text = try String(contentsOf: url)
            textView.string = text
        } catch {
            textView.string = "Error loading text: \(error.localizedDescription)"
        }
    }
}
