//
//  FilePreviewItem.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import QuickLook
import SwiftUI

class FilePreviewItem: NSObject, QLPreviewControllerDataSource {
    let url: URL
    let title: String
    
    init(url: URL, title: String) {
        self.url = url
        self.title = title
        super.init()
    }
    
    // MARK: - QLPreviewControllerDataSource
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self as QLPreviewItem
    }
}

// Conform to QLPreviewItem
extension FilePreviewItem: QLPreviewItem {
    var previewItemURL: URL? {
        return url
    }
    
    var previewItemTitle: String? {
        return title
    }
}
