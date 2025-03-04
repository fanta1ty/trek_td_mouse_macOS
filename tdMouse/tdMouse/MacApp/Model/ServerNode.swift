//
//  ServerNode.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 4/3/25.
//

struct ServerNode: Node, Hashable {
    let id: ID
    let name: String
    let parent: ID?
    var path: String { id.rawValue }
    
    init(id: ID, name: String, parent: ID? = nil) {
        self.id = id
        self.name = name
        self.parent = parent
    }
    
    func detach() -> Self {
        ServerNode(id: id, name: name)
    }
}
