//
//  ConnectServerWindowController.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 3/3/25.
//

import Cocoa

class ConnectServerWindowController: NSWindowController {
    static func instantiate() -> Self {
      let storyboard = NSStoryboard(name: "ConnectServer", bundle: nil)
      let windowController = storyboard.instantiateInitialController() as! Self
      return windowController
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.animationBehavior = .none
    }
}

// MARK: - Public Functions
extension ConnectServerWindowController {
    func runModal() -> NSApplication.ModalResponse {
        return NSApp.runModal(for: window!)
    }
}
