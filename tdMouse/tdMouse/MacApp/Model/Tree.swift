//
//  Tree.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 4/3/25.
//

import Foundation

struct Tree<Item: Node & Hashable> {
    var nodes = [Item]()
    
    func rootNodes() -> [Item] {
        nodes.filter { $0.isRoot }
    }
    
    func children(of node: Item) -> [Item] {
        nodes.filter { $0.parent == node.id }
    }
    
    func hasChildren(_ node: Item) -> Bool {
        nodes.contains { $0.parent == node.id }
    }
    
    func parent(of node: Item) -> Item? {
        nodes.first { $0.id == node.parent }
    }
}
