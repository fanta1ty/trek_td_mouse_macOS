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

        if let fieldEditor = window?.fieldEditor(true, for: nil) as? NSTextView {
            _ = fieldEditor.layoutManager
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(navigationDidFinished(_:)),
            name: NavigationController.navigationDidFinished,
            object: nil
        )
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

// MARK: - Private Functions
extension WindowController {
    private func navigationController() -> NavigationController? {
        guard let splitViewController = contentViewController as? SplitViewController else {
            return nil
        }

        let splitViewItem = splitViewController.splitViewItems[1]

        guard let navigationController = splitViewItem.viewController as? NavigationController else {
            return nil
        }

        return navigationController
    }

    @objc private func navigationDidFinished(_ notification: Notification) {
        guard let navigationController = navigationController() else { return }

    }
}
