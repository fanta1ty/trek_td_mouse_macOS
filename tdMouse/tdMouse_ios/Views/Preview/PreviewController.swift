//
//  PreviewController.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import SwiftUI
import UIKit
import Foundation
import QuickLook

struct PreviewController: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        
        controller.navigationItem.leftBarButtonItem = nil
        controller.navigationItem.rightBarButtonItem = nil
        
        let navController = UINavigationController(rootViewController: controller)
        navController.navigationBar.isHidden = true
        
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        if let controller = uiViewController.topViewController as? QLPreviewController {
            controller.reloadData()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}
