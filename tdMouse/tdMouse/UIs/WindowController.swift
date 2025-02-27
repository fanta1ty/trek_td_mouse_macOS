//
//  WindowController.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 28/2/25.
//

import Cocoa
import UniformTypeIdentifiers

private extension NSToolbarItem.Identifier {
    static let navigationToolbarItemIdentifier = NSToolbarItem.Identifier("NavigationToolbarItem")
    static let backToolbarItemIdentifier = NSToolbarItem.Identifier("BackToolbarItem")
    static let forwardItemIdentifier = NSToolbarItem.Identifier("ForwardToolbarItem")
    
    static let newFolderToolbarItemIdentifier = NSToolbarItem.Identifier("NewFolderToolbarItem")
    static let connectToServerToolbarItemIdentifier = NSToolbarItem.Identifier("ConnectToServerToolbarItem")
    static let activitiesToolbarItemIdentifier = NSToolbarItem.Identifier("ActivitiesToolbbarItem")
    static let searchToolbarItemIdentifier = NSToolbarItem.Identifier("SearchToolbarItem")
}

class WindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
    }
}

// MARK: - NSWindowDelegate
extension WindowController: NSWindowDelegate {
    func window(_ window: NSWindow, shouldPopUpDocumentPathMenu menu: NSMenu) -> Bool {
        return true
    }
}

// MARK: - NSMenuItemValidation
extension WindowController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return false
    }
}

// MARK: - NSToolbarDelegate
extension WindowController: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(
        _ toolbar: NSToolbar
    ) -> [NSToolbarItem.Identifier] {
        [
            .navigationToolbarItemIdentifier,
        ]
    }
    
    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier {
        default: return nil
        }
    }
}

// MARK: - NSToolbarItemValidation
extension WindowController: NSToolbarItemValidation {
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        return true
    }
}

// MARK: - NSSearchFieldDelegate
extension WindowController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        
    }
}
