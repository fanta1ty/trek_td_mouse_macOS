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
        
        return UINavigationController(rootViewController: controller)
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
