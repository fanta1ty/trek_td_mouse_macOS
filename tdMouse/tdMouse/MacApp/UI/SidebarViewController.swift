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
    }
}

// MARK: - NSOutlineViewDataSource
extension SidebarViewController: NSOutlineViewDataSource {
    
}

// MARK: - NSOutlineViewDelegate
extension SidebarViewController: NSOutlineViewDelegate {
    
}
