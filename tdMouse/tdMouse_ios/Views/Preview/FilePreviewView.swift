//
//  FilePreviewView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import SwiftUI
import Foundation

struct FilePreviewView: View {
    @State private var previewURL: URL?
    @State private var isLoading: Bool = true
    @State private var error: String?
    @State private var showShareSheet: Bool = false
    
    @Binding var showPreviewSheet: Bool
    
    let title: String
    let fileProvider: () async throws -> Data
    let fileExtension: String
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading file...")
            } else if let error {
                PreviewErrorView(message: error)
            } else if let previewURL {
                PreviewController(url: previewURL)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showPreviewSheet = false
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.primary)
                }
            }
        }
        .onAppear {
            loadFile()
        }
        .onDisappear {
            if let previewURL {
                try? FileManager.default.removeItem(at: previewURL)
            }
        }
    }
}

// MARK: - Private Functions
extension FilePreviewView {
    private func loadFile() {
        Task {
            do {
                isLoading = true
                let data = try await fileProvider()
                
                let extensionToUse: String
                
                if !fileExtension.isEmpty {
                    extensionToUse = fileExtension
                } else {
                    let mediaType = ContentTypeDetector.detectMediaType(from: data)
                    extensionToUse = mediaType.fileExtension
                }
                
                let tempDir = FileManager.default.temporaryDirectory
                let tempURL = tempDir.appendingPathComponent(UUID().uuidString + ".\(extensionToUse)")
                
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

struct FilePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        FilePreviewView(
            showPreviewSheet: .constant(true),
            title: "Test",
            fileProvider: {
                Data()
            },
            fileExtension: "txt"
        )
        .environmentObject(FileTransferViewModel())
        .environmentObject(LocalViewModel())
    }
}
