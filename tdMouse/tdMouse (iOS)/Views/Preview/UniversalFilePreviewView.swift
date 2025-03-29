//
//  UniversalFilePreviewView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import SwiftUI
import UIKit
import PDFKit
import AVKit
import WebKit

struct UniversalFilePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var previewURL: URL?
    @State private var isLoading = true
    @State private var error: String?
    
    let title: String
    let fileProvider: () async throws -> Data
    let fileExtension: String
    
    private var fileType: FileType {
        return Helpers.determineFileType(fileExtension: fileExtension.lowercased())
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading file...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = error {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Error loading file")
                            .font(.headline)
                            .padding(.top)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let url = previewURL {
                    Group {
                        switch fileType {
                        case .pdf:
                            PDFPreviewView(url: url)
                        case .image:
                            ImagePreviewView(url: url)
                        case .text:
                            TextPreviewView(url: url)
                        case .video:
                            VideoPreviewView(url: url)
                        case .audio:
                            AudioPreviewView(url: url)
                        case .web:
                            WebPreviewView(url: url)
                        case .other:
                            UnsupportedFileView(fileExtension: fileExtension)
                        }
                    }
                    .ignoresSafeArea(edges: [.bottom])
                }
            }
            .navigationBarTitle(title, displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 22))
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadFile()
        }
        .onDisappear {
            // Clean up temp file when view disappears
            if let url = previewURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
    
    private func loadFile() {
        Task {
            do {
                isLoading = true
                
                // Get the file data from the provider
                let data = try await fileProvider()
                
                // Create a temporary file for the preview
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(fileExtension)
                
                // Write the data to the temporary file
                try data.write(to: tempURL)
                
                await MainActor.run {
                    self.previewURL = tempURL
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
