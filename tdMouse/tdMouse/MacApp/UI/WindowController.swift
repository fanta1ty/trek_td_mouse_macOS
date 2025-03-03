//
//  WindowController.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 28/2/25.
//

import Cocoa
import UniformTypeIdentifiers

class WindowController: NSWindowController {
    private let segmentedControl = NSSegmentedControl()
    private let backHistoryMenu = NSMenu()
    private let forwardHistoryMenu = NSMenu()

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
            let back = NSToolbarItem(itemIdentifier: .backToolbarItemIdentifier)
            back.label = "Back"

            let forward = NSToolbarItem(itemIdentifier: .forwardItemIdentifier)
            forward.label = "Forward"

            segmentedControl.segmentStyle = .separated
            segmentedControl.trackingMode = .momentary
            segmentedControl.segmentCount = 2

            segmentedControl.setImage(
                .init(
                    systemSymbolName: "chevron.left",
                    accessibilityDescription: nil
                ),
                forSegment: 0
            )
            segmentedControl.setWidth(32, forSegment: 0)

            segmentedControl.setImage(
                .init(
                    systemSymbolName: "chevron.right",
                    accessibilityDescription: nil
                ),
                forSegment: 1
            )
            segmentedControl.setWidth(32, forSegment: 1)

            segmentedControl.setMenu(backHistoryMenu, forSegment: 0)
            segmentedControl.setMenu(forwardHistoryMenu, forSegment: 1)

            segmentedControl.action = #selector(WindowController.navigationAction(_:))

            segmentedControl.setEnabled(false, forSegment: 0)
            segmentedControl.setEnabled(false, forSegment: 1)

            let group = NSToolbarItemGroup(itemIdentifier: itemIdentifier)
            group.label = "Back/Forward"
            group.paletteLabel = "Navigation"
            group.subitems = [back, forward]
            group.isNavigational = true
            group.view = segmentedControl

            return group

        case .connectToServerToolbarItemIdentifier:
            let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)

            toolbarItem.isBordered = true
            toolbarItem.image = NSImage(named: "server.rack.badge.plus")
            toolbarItem.label = NSLocalizedString("Connect", comment: "")
            toolbarItem.action = #selector(connectToServerAction(_:))
            
            return toolbarItem

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
        
        if item.itemIdentifier == .newFolderToolbarItemIdentifier {
            return navigationController.topViewController is FilesViewController
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

    @objc private func navigationAction(_ sender: NSSegmentedControl) {
        guard let navigationController = navigationController() else { return }

        switch sender.selectedSegment {
        case 0: navigationController.back()
        case 1: navigationController.forward()
        default: break
        }
    }

    @objc
    private func connectToServerAction(_ sender: NSToolbarItem) {
        let serverManager = ServerManager.shared
        serverManager.connectToNewServer()
    }
}
