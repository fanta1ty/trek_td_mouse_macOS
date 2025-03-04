//
//  HeaderNode.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 4/3/25.
//

import Foundation

struct HeaderNode: Node, Hashable {
    let id: ID
    let name: String
    let parent: ID?
    
    init(_ title: String) {
        self.init(id: ID(title), name: NSLocalizedString(title, comment: ""))
    }
    
    private init(id: ID, name: String, parent: ID? = nil) {
        self.id = id
        self.name = name
        self.parent = parent
    }
    
    func detach() -> Self {
        self
    }
}
