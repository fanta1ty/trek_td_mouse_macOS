//
//  PDFPreviewView.swift
//  tdMouse
//
//  Created by mobile on 16/3/25.
//

import SwiftUI
import Foundation
import Quartz
import AppKit

struct PDFPreviewView: NSViewRepresentable {
    // MARK: - Properties
    
    let url: URL
    var showToolbar: Bool = true
    var displayMode: PDFDisplayMode = .singlePage
    var autoScales: Bool = true
    var initialPage: Int? = nil
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: PDFPreviewView
        
        init(_ parent: PDFPreviewView) {
            self.parent = parent
        }
    }
    
    // MARK: - NSViewRepresentable
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Basic configuration
        pdfView.autoresizingMask = [.width, .height]
        pdfView.autoScales = autoScales
        pdfView.displayMode = displayMode
        
        // UI configuration
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        pdfView.displayBox = .cropBox
        pdfView.displaysAsBook = false
        pdfView.displayMode = displayMode
        
        // Toolbar visibility
        pdfView.displaysAsBook = false
        
        // Interaction settings
        pdfView.enableDataDetectors = true
        
        // Set scale factor for better readability
        pdfView.scaleFactor = 1.25
        
        // Load the document
        loadDocument(in: pdfView)
        
        // Configure toolbar after document is loaded
        configureToolbar(pdfView)
        
        return pdfView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        // Update if document is nil or URL has changed
        if pdfView.document == nil || pdfView.document?.documentURL != url {
            loadDocument(in: pdfView)
        }
        
        // Update view properties if they've changed
        pdfView.autoScales = autoScales
        pdfView.displayMode = displayMode
        
        // Update toolbar visibility
        configureToolbar(pdfView)
    }
    
    // MARK: - Helper Methods
    
    private func loadDocument(in pdfView: PDFView) {
        // Try to load document
        if let pdfDocument = PDFDocument(url: url) {
            pdfView.document = pdfDocument
            
            // Jump to initial page if specified
            if let initialPage = initialPage, initialPage > 0,
               let document = pdfView.document,
               initialPage <= document.pageCount,
               let page = document.page(at: initialPage - 1) {
                pdfView.go(to: page)
            }
            
        } else {
            // Handle document load failure
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Error Opening PDF"
                alert.informativeText = "The PDF document could not be opened. It might be corrupted or in an unsupported format."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
    
    private func configureToolbar(_ pdfView: PDFView) {
        if let documentView = pdfView.documentView {
            // Find the PDFView's toolbar if it exists
            if let scrollView = documentView.enclosingScrollView,
               let superView = scrollView.superview {
                
                // Look for the toolbar within the view hierarchy
                for subview in superView.subviews {
                    if let toolbar = subview as? NSView, toolbar != scrollView {
                        toolbar.isHidden = !showToolbar
                    }
                }
            }
        }
    }
}

// MARK: - Convenience Extensions

extension PDFPreviewView {
    /// Creates a PDFPreviewView with toolbar hidden
    static func documentOnly(url: URL) -> PDFPreviewView {
        PDFPreviewView(url: url, showToolbar: false)
    }
    
    /// Creates a PDFPreviewView for continuous scrolling
    static func continuous(url: URL) -> PDFPreviewView {
        PDFPreviewView(url: url, displayMode: .singlePageContinuous)
    }
    
    /// Creates a PDFPreviewView for two-page display
    static func twoUp(url: URL) -> PDFPreviewView {
        PDFPreviewView(url: url, displayMode: .twoUp)
    }
}

// MARK: - PDF Document Preview Provider

struct PDFDocumentPreview: View {
    let url: URL
    let title: String
    
    @State private var zoomLevel: CGFloat = 1.0
    @State private var currentPage: Int = 1
    @State private var totalPages: Int = 1
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and close button
            HStack {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                Text("\(currentPage) of \(totalPages)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
            .padding([.horizontal, .top])
            
            // PDF View
            PDFPreviewView(url: url)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Control bar
            HStack(spacing: 16) {
                // Zoom controls
                HStack {
                    Button(action: { zoomLevel = max(0.5, zoomLevel - 0.25) }) {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .disabled(zoomLevel <= 0.5)
                    .buttonStyle(.borderless)
                    
                    Text("\(Int(zoomLevel * 100))%")
                        .frame(width: 50)
                        .monospacedDigit()
                    
                    Button(action: { zoomLevel = min(3.0, zoomLevel + 0.25) }) {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .disabled(zoomLevel >= 3.0)
                    .buttonStyle(.borderless)
                }
                
                Spacer()
                
                // Page navigation
                HStack {
                    Button(action: { currentPage = max(1, currentPage - 1) }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentPage <= 1)
                    .buttonStyle(.borderless)
                    
                    Button(action: { currentPage = min(totalPages, currentPage + 1) }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(currentPage >= totalPages)
                    .buttonStyle(.borderless)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onAppear {
            // Get total page count when view appears
            if let document = PDFDocument(url: url) {
                totalPages = document.pageCount
            }
        }
    }
}

// MARK: - Preview

struct PDFPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview requires a valid PDF URL
            PDFPreviewView(url: URL(fileURLWithPath: "/tmp/example.pdf"))
                .previewDisplayName("Default")
            
            PDFPreviewView.continuous(url: URL(fileURLWithPath: "/tmp/example.pdf"))
                .previewDisplayName("Continuous")
            
            PDFDocumentPreview(
                url: URL(fileURLWithPath: "/tmp/example.pdf"),
                title: "Sample Document.pdf"
            )
            .frame(width: 800, height: 600)
            .previewDisplayName("Document with Controls")
        }
    }
}
