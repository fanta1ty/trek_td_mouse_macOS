//
//  PreviewItem.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import Foundation
import QuickLook

class PreviewItem: NSObject, QLPreviewItem {
    let previewItemURL: URL?
    let previewItemTitle: String?
    
    init(
        previewItemURL: URL?,
        previewItemTitle: String?
    ) {
        self.previewItemURL = previewItemURL
        self.previewItemTitle = previewItemTitle
        
        super.init()
    }
}
