//
//  FilePreviewItem.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import Quartz

class FilePreviewItem: NSObject, QLPreviewItem {
    let url: URL
    let title: String
    
    init(url: URL, title: String) {
        self.url = url
        self.title = title
        super.init()
    }
    
    var previewItemURL: URL? {
        return url
    }
    
    var previewItemTitle: String? {
        return title
    }
}
