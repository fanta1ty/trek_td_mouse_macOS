//
//  SidebarViewController.swift
//  tdMouse
//
//  Created by Nguyen, Thinh on 1/3/25.
//

import Cocoa

class SidebarViewController: NSViewController {
    @IBOutlet private(set) var sourceList: NSOutlineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sourceList.dataSource = self
        sourceList.delegate = self
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sidebarDidUpdate(_:)),
            name: SidebarManager.sidebarDidUpdate,
            object: nil
        )
    }
}

// MARK: - NSOutlineViewDataSource
extension SidebarViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        SidebarManager.shared.numberOfChildrenOfItem(item)
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        SidebarManager.shared.child(index, ofItem: item)
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        SidebarManager.shared.isItemExpandable(item)
    }
}

// MARK: - NSOutlineViewDelegate
extension SidebarViewController: NSOutlineViewDelegate {
    func outlineView(
        _ outlineView: NSOutlineView,
        viewFor tableColumn: NSTableColumn?,
        item: Any
    ) -> NSView? {
        guard let node = item as? SidebarNode else { return nil }
        
        switch node.content {
        case let headerNode as HeaderNode:
            let cellIdentifier = NSUserInterfaceItemIdentifier("HeaderCell")
            guard let cell = outlineView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView else { return nil }
            cell.textField?.stringValue = headerNode.name
            return cell
            
        case let serverNode as ServerNode:
            let cellIdentifier = NSUserInterfaceItemIdentifier("DataCell")
            guard let cell = outlineView.makeView(withIdentifier: cellIdentifier, owner: nil) as? SidebarCellView else { return nil }
            
            cell.imageView?.image = NSImage(systemSymbolName: "server.rack", accessibilityDescription: nil)
            cell.textField?.stringValue = serverNode.name
            
            cell.ejectButton.isHidden = !SessionManager.shared.sessionExists(for: serverNode.id)
            cell.ejectAction = {
                cell.ejectButton.isEnabled = false
                
                Task { @MainActor in
                    await SidebarManager.shared.logoff(node)
                    cell.ejectButton.isEnabled = true
                }
            }
            
            
            return cell
            
        default: return nil
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        SidebarManager.shared.isItemSelectable(item)
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        
    }
}

// MARK: - Private Functions
extension SidebarViewController {
    @objc private func sidebarDidUpdate(_ notification: Notification) {
      sourceList.reloadData()
    }
}
