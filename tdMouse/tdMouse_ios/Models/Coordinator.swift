//
//  Coordinator.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import Foundation
import QuickLook

class Coordinator: NSObject, QLPreviewControllerDataSource {
    let parent: PreviewController
    
    init(parent: PreviewController) {
        self.parent = parent
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        PreviewItem(previewItemURL: parent.url, previewItemTitle: parent.url.lastPathComponent)
    }
}
