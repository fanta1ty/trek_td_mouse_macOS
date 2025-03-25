//
//  PDFPreviewView.swift
//  tdMouse
//
//  Created by mobile on 16/3/25.
//

import SwiftUI
import Foundation
import Quartz

struct PDFPreviewView: NSViewRepresentable {
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoresizingMask = [.width, .height]
        pdfView.displayMode = .singlePage
        pdfView.autoScales = true
        
        if let pdfDocument = PDFDocument(url: url) {
            pdfView.document = pdfDocument
            return pdfView
        }
        
        return pdfView
    }
    
    typealias NSViewType = PDFView
    
    let url: URL
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document == nil || nsView.document?.documentURL != url {
            nsView.document = PDFDocument(url: url)
        }
    }
}
