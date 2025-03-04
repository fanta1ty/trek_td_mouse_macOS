//
//  SidebarNode.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 4/3/25.
//

import Foundation

struct SidebarNode: Node, Hashable {
    let id: ID
    let name: String
    let parent: ID?
    
    let content: Node
    
    init(_ content: Node, parent: ID? = nil) {
        id = content.id
        name = content.name
        self.parent = parent
        
        self.content = content
    }
    
    func detach() -> Self {
        SidebarNode(content)
    }
}
