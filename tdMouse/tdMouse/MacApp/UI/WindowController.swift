//
//  WindowController.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 28/2/25.
//

import Cocoa
import UniformTypeIdentifiers

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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didStartActivities(_:)),
            name: FilesViewController.didStartActivities,
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
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            .navigationToolbarItemIdentifier,
            .newFolderToolbarItemIdentifier,
            .connectToServerToolbarItemIdentifier,
            .activitiesToolbarItemIdentifier,
            .searchToolbarItemIdentifier
        ]
    }
    
    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier {
        case .navigationToolbarItemIdentifier:
            let group = NSToolbarItemGroup(itemIdentifier: itemIdentifier)
            return group

        default: return nil
        }
    }
}

// MARK: - NSToolbarItemValidation
extension WindowController: NSToolbarItemValidation {
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        guard let navigationController = navigationController() else {
            return false
        }
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

    @objc private func didStartActivities(_ notification: Notification) {
        guard let toolbarItems = window?.toolbar?.items else {
            return
        }
    }
}
