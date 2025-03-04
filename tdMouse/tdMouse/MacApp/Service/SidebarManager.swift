//
//  SidebarManager.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 4/3/25.
//

import Cocoa
import SMBClient

class SidebarManager {
    static let shared = SidebarManager()
    static let sidebarDidUpdate = Notification.Name("SidebarManagerSidebarDidUpdate")
    
    private var tree = Tree<SidebarNode>()
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(serviceDidDiscover(_:)),
            name: ServiceDiscovery.serviceDidDiscover,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(serversDidUpdate(_:)),
            name: ServerManager.serversDidUpdate,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionDidDisconnected(_:)),
            name: SessionManager.sessionDidDisconnected,
            object: nil
        )
    }
}

// MARK: - Action Functions
extension SidebarManager {
    @objc private func serviceDidDiscover(_ notification: Notification) {
        updateTree()
    }
    
    @objc private func serversDidUpdate(_ notification: Notification) {
        updateTree()
    }
    
    @objc private func sessionDidDisconnected(_ notification: Notification) {
        updateTree()
    }
}

// MARK: - Private Functions
extension SidebarManager {
    private func updateTree() {
        let services = ServiceDiscovery.shared.services
        let serviceNodes = services
            .map {
                SidebarNode(ServerNode(
                    id: $0.id,
                    name: $0.name
                ))
            }
            .sorted {
                $0.name
                    .localizedStandardCompare($1.name) == .orderedAscending
            }
        
        let servers = ServerManager.shared.servers
        let serverNodes = servers
            .map {
                let name: String
                if $0.displayName.isEmpty {
                    name = $0.server
                } else {
                    name = $0.displayName
                }
                return SidebarNode(ServerNode(id: $0.id, name: name))
            }
            .sorted {
                $0.name
                    .localizedStandardCompare(($1 as SidebarNode).name) == .orderedAscending
            }
        
        let children = tree.nodes.reduce(into: [SidebarNode]()) {
            if $1.content is ServerNode {
                $0 += tree.children(of: $1)
            }
        }
        
        tree.nodes = [SidebarNode(HeaderNode("Services"))] + serviceNodes + [SidebarNode(HeaderNode("Servers"))] + serverNodes
        tree.nodes.append(contentsOf: children)
        
        NotificationCenter.default.post(name: Self.sidebarDidUpdate, object: self)
    }
}

// MARK: - Public Functions
extension SidebarManager {
    func numberOfChildrenOfItem(_ item: Any?) -> Int {
        if let node = item as? SidebarNode {
            if tree.hasChildren(node) {
                return tree.children(of: node).count
            } else { return 0 }
        } else {
            return tree.rootNodes().count
        }
    }
    
    func child(_ index: Int, ofItem item: Any?) -> Any {
        if let node = item as? SidebarNode {
            return tree.children(of: node)[index]
        } else {
            return tree.rootNodes()[index]
        }
    }
    
    func isItemExpandable(_ item: Any) -> Bool {
        guard let node = item as? SidebarNode else { return false }
        return node.content is ServerNode
    }
    
    func logoff(_ node: SidebarNode) async {
        await SessionManager.shared.logoff(id: node.id)
        
        let children = tree.children(of: node)
        tree.nodes.removeAll(where: { children.contains($0) })
        
        await MainActor.run {
            NotificationCenter.default.post(name: Self.sidebarDidUpdate, object: self)
        }
    }
    
    func isItemSelectable(_ item: Any) -> Bool {
        guard let node = item as? SidebarNode else { return false }
        return node.content is ServerNode || node.content is ShareNode
    }
}
