//
//  NavigationController.swift
//  tdMouse
//
//  Created by Nguyen, Thinh on 28/2/25.
//

import Cocoa

class NavigationController: NSViewController {
    static let navigationDidFinished = Notification.Name("NavigationControllerNavigationDidFinished")

    private var current = -1 {
        didSet {
            NotificationCenter.default.post(
                name: Self.navigationDidFinished, object: self
            )
        }
    }

    private var history = [NSViewController]()

    override func swipe(with event: NSEvent) {
        
    }
}

// MARK: - Public Functions
extension NavigationController {
    func canGoBack() -> Bool {
        current > 0
    }

    func canGoForward() -> Bool {
        current < history.count - 1
    }

    func back() {
        guard canGoBack() else { return }

        let viewController = history[current - 1]
        replace(viewController)

        current -= 1
    }

    func forward() {
        guard canGoForward() else { return }

        let viewController = history[current + 1]
        replace(viewController)

        current += 1
    }
}

// MARK: - Private Functions
extension NavigationController {
    private func replace(_ viewController: NSViewController) {
        for child in children {
            child.removeFromParent()
            child.view.removeFromSuperview()
        }

        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.width, .height]
        view.addSubview(viewController.view)

        addChild(viewController)
    }
}
