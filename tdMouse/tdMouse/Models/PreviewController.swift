//
//  PreviewController.swift
//  tdMouse
//
//  Created by mobile on 16/3/25.
//

import Foundation
import AppKit

class PreviewController: NSObject {
    static func previewFile(at url: URL) {
        let workspace = NSWorkspace.shared
        workspace.open(url)
    }
}
