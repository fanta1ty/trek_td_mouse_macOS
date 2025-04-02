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
                    .overlay(alignment: .topTrailing) {
                        if !isLoading && error == nil {
                            Button {
                                showShareSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 22))
                                    .padding(12)
                                    .background(Color(UIColor.systemBackground).opacity(0.8))
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                            .padding([.top, .trailing], 16)
                        }
                    }
                    .sheet(isPresented: $showShareSheet) {
                        ShareLink(item: previewURL)
                    }
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
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
                let tempDir = FileManager.default.temporaryDirectory
                let tempURL = tempDir.appendingPathComponent(UUID().uuidString)
                    .appendingPathComponent(fileExtension)
                
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
            title: "Test",
            fileProvider: {
                Data()
            },
            fileExtension: "txt"
        )
        .environmentObject(FileTransferViewModel())
    }
}
