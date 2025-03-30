//
//  FilePreviewController.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI
import AVFoundation
import AVKit
import QuickLook

struct FilePreviewController: UIViewControllerRepresentable {
    let url: URL
    let fileType: FileType
    
    func makeUIViewController(context: Context) -> UIViewController {
        switch fileType {
        case .image:
            return createImagePreviewController(url: url)
        case .video:
            return createVideoPreviewController(url: url)
        case .pdf:
            return createPDFPreviewController(url: url)
        default:
            return createDocumentPreviewController(url: url)
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update if needed
    }
    
    private func createImagePreviewController(url: URL) -> UIViewController {
        let controller = UIViewController()
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        if let image = UIImage(contentsOfFile: url.path) {
            imageView.image = image
        }
        
        controller.view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: controller.view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
        ])
        
        return controller
    }
    
    private func createVideoPreviewController(url: URL) -> UIViewController {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.entersFullScreenWhenPlaybackBegins = true
        controller.showsPlaybackControls = true
        player.play()
        return controller
    }
    
    private func createPDFPreviewController(url: URL) -> UIViewController {
        // Use PDFKit for PDF files
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        
        let controller = UIViewController()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(pdfView)
        
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: controller.view.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
        ])
        
        return controller
    }
    
    private func createDocumentPreviewController(url: URL) -> UIViewController {
        // Use QuickLook for other document types
        let controller = QLPreviewController()
        let previewItem = FilePreviewItem(url: url, title: url.lastPathComponent)
        controller.dataSource = previewItem
        return controller
    }
}
