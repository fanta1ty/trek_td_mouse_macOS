//
//  UniversalFilePreviewView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import SwiftUI
import Foundation

struct UniversalFilePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isShowingPreview: Bool
    
    @State private var previewURL: URL?
    @State private var isLoading = true
    @State private var error: String?
    
    let title: String
    let fileProvider: () async throws -> Data
    let fileExtension: String
    
    private var fileType: FileType {
        Helpers.determineFileType(fileExtension: fileExtension.lowercased())
    }
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                })
                .buttonStyle(.plain)
            }
            .padding()
            
            if isLoading {
                ProgressView("Loading file...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
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
                .edgesIgnoringSafeArea(.all)
            }
        }
        .frame(width: 800, height: 600)
        .onAppear {
            loadFile()
        }
        .onDisappear {
            if let url = previewURL {
                try? FileManager.default.removeItem(at: url)
            }
            
            isShowingPreview = false
        }
    }
    
    private func loadFile() {
        Task {
            do {
                isLoading = true
                
                let data = try await fileProvider()
                
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(fileExtension)
                
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

struct UniversalFilePreviewView_Preview: PreviewProvider {
    static var previews: some View {
        UniversalFilePreviewView(
            isShowingPreview: .constant(true),
            title: "Preview",
            fileProvider: { .init() },
            fileExtension: "jpg"
        )
    }
}
