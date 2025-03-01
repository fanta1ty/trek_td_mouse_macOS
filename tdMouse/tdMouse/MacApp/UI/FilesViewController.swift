//
//  FilesViewController.swift
//  tdMouse
//
//  Created by Nguyen, Thinh on 1/3/25.
//

import Cocoa
import UniformTypeIdentifiers
import SMBClient

class FilesViewController: NSViewController {
    static let didStartActivities = Notification.Name("FilesViewControllerDidStartActivities")

    @IBOutlet private var outlineView: NSOutlineView!
    @IBOutlet private var pathBarView: PathBarView!
    @IBOutlet private var statusBarView: StatusBarView!

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
    }
}
