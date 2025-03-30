//
//  FilePreviewView.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI
import QuickLook
import AVKit
import PDFKit

struct FilePreviewView: View {
    let url: URL
    let title: String
    let fileType: FileType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                switch fileType {
                case .image:
                    ImagePreview(url: url)
                case .video:
                    VideoPreview(url: url)
                case .audio:
                    AudioPreview(url: url)
                case .pdf:
                    PDFPreview(url: url)
                default:
                    QuickLookPreview(url: url)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Specialized Preview Components

struct ImagePreview: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemBackground
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        if let image = UIImage(contentsOfFile: url.path) {
            uiView.image = image
        } else {
            uiView.image = UIImage(systemName: "questionmark.square")
        }
    }
}

struct VideoPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        player.play()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No updates needed
    }
}

struct AudioPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        
        // Add audio waveform visualization background
        let imageView = UIImageView(image: UIImage(systemName: "waveform"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondarySystemBackground
        imageView.alpha = 0.4
        controller.contentOverlayView?.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        if let overlay = controller.contentOverlayView {
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
                imageView.widthAnchor.constraint(equalTo: overlay.widthAnchor, multiplier: 0.7),
                imageView.heightAnchor.constraint(equalTo: overlay.heightAnchor, multiplier: 0.5)
            ])
        }
        
        player.play()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No updates needed
    }
}

struct PDFPreview: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // No updates needed
    }
}

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = QLPreviewController()
        let previewItem = FilePreviewItem(url: url, title: url.lastPathComponent)
        controller.dataSource = previewItem
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}
