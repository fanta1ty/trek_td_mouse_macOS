//
//  FileNode.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 4/3/25.
//

import Foundation
import SMBClient

struct FileNode: Node, Hashable {
    let id: ID
    let name: String
    let parent: ID?
    
    let path: String
    let file: File
    
    var size: UInt64 { file.size }
    var isDirectory: Bool { file.isDirectory }
    var isHidden: Bool { file.isHidden }
    var isReadOnly: Bool { file.isReadOnly }
    var isSystem: Bool { file.isSystem }
    var isArchive: Bool { file.isArchive }
    var creationTime: Date { file.creationTime }
    var lastAccessTime: Date { file.lastAccessTime }
    var lastWriteTime: Date { file.lastWriteTime }
    
    var isExpandable: Bool { isDirectory }
    
    init(path: String, file: File, parent: ID? = nil) {
        id = ID(path)
        name = file.name
        self.parent = parent
        
        self.path = path
        self.file = file
    }
    
    func detach() -> Self {
        FileNode(path: path, file: file)
    }
}

extension FileNode: CustomStringConvertible {
    var description: String {
        "{\(id.rawValue), \(name), \(file)}"
    }
}
