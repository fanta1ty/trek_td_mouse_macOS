//
//  ShareNode.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 4/3/25.
//

struct ShareNode: Node, Hashable {
    let id: ID
    let name: String
    let parent: ID?
    
    let device: String
    
    init(id: ID, device: String, name: String, parent: ID? = nil) {
        self.id = id
        self.name = name
        self.parent = parent
        
        self.device = device
    }
    
    func detach() -> Self {
        ShareNode(id: id, device: device, name: name)
    }
}
