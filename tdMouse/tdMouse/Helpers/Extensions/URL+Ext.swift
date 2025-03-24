//
//  URL+Ext.swift
//  tdMouse
//
//  Created by mobile on 24/3/25.
//

import Foundation

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }
    
    func safeAttributes() -> [FileAttributeKey: Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: self.path)
        } catch {
            return nil
        }
    }
}
