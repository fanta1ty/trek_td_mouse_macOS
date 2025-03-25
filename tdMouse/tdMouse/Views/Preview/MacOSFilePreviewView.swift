//
//  MacOSFilePreviewView.swift
//  tdMouse
//
//  Created by mobile on 16/3/25.
//

import SwiftUI
import Foundation

struct MacOSFilePreviewView: View {
    @Environment(\.dismiss) private var dismiss;
    
    @State private var previewURL: URL?
    @State private var isLoading: Bool = true
    @State private var error: String?
    @State private var previewItemIndex = 0
    
    let title: String
    let fileProvider: () async throws -> Data
    let fileExtension: String
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
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
                        .foregroundStyle(.orange)
                    
                    Text("Error loading file")
                        .font(.headline)
                        .padding(.top)
                    
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let previewURL {
                PDFPreviewView(url: previewURL)
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

struct MacOSFilePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        MacOSFilePreviewView(
            title: "Preview",
            fileProvider: {
                "Test".data(using: .utf8)!
            },
            fileExtension: ".png"
        )
    }
}
