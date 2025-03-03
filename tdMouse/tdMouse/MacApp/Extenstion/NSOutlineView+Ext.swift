//
//  NSOutlineView+Ext.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 4/3/25.
//

import Cocoa

extension NSOutlineView {
    func targetRows() -> IndexSet {
        let targetRows: IndexSet
        
        if clickedRow >= 0 {
            targetRows = selectedRowIndexes.contains(clickedRow) ? selectedRowIndexes : IndexSet([clickedRow])
        } else {
            targetRows = IndexSet()
        }
        
        return targetRows
    }
}

