//
//  FileItem.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 12/3/25.
//

import Foundation

struct FileItem: Identifiable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
