//
//  LocalFileViewModel.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

/// View model for managing local file system operations
class LocalFileViewModel: ObservableObject {
    static let shared = LocalFileViewModel()
    
    // MARK: - Published Properties
    @Published var files: [LocalFile] = []
    @Published var currentDirectoryURL: URL
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    // MARK: - Computed Properties
    
    /// Determines if navigation up the directory hierarchy is possible
    var canNavigateUp: Bool {
        // Prevent navigating above home directory
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return currentDirectoryURL != documentDirectory
    }
    
    // MARK: - Initialization
    
    init(initialDirectory: URL? = nil) {
        // Start at downloads directory if not specified
        let directory = initialDirectory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.currentDirectoryURL = directory
    }
    
    // MARK: - Public Methods
    
    /// Initialize the view model and load initial files
    func initialize() {
        refreshFiles()
    }
    
    /// Refresh the file listing for the current directory
    func refreshFiles() {
        Task {
            await loadFiles(from: currentDirectoryURL)
        }
    }
    
    /// Navigate to a subdirectory by name
    func navigateToDirectory(_ directoryName: String) {
        let newURL = currentDirectoryURL.appendingPathComponent(directoryName, isDirectory: true)
        
        Task {
            await loadFiles(from: newURL)
        }
    }
    
    /// Navigate up one directory level
    func navigateUp() {
        guard canNavigateUp else { return }
        
        let parentURL = currentDirectoryURL.deletingLastPathComponent()
        
        Task {
            await loadFiles(from: parentURL)
        }
    }
    
    /// Create a new directory in the current location
    func createDirectory(_ directoryName: String) {
        let newDirectoryURL = currentDirectoryURL.appendingPathComponent(directoryName)
        
        do {
            try FileManager.default.createDirectory(
                at: newDirectoryURL,
                withIntermediateDirectories: false,
                attributes: nil
            )
            refreshFiles()
        } catch {
            errorMessage = "Error creating directory: \(error.localizedDescription)"
        }
    }
    
    /// Delete a file or directory
    func deleteFile(_ file: LocalFile) {
        Task {
            do {
                try FileManager.default.removeItem(at: file.url)
                
                await MainActor.run {
                    // Remove the file from the files array
                    self.files.removeAll { $0.id == file.id }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete \(file.name): \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Get LocalFile object from a URL
    func getFileFromURL(_ url: URL) -> LocalFile? {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let resourceValues = try url.resourceValues(forKeys: [
                    .isDirectoryKey,
                    .fileSizeKey,
                    .contentModificationDateKey
                ])
                
                let isDirectory = resourceValues.isDirectory ?? false
                let fileSize = resourceValues.fileSize ?? 0
                let modificationDate = resourceValues.contentModificationDate ?? Date()
                
                return LocalFile(
                    name: url.lastPathComponent,
                    url: url,
                    isDirectory: isDirectory,
                    size: Int64(fileSize),
                    modificationDate: modificationDate
                )
            } catch {
                errorMessage = "Error getting file info: \(error.localizedDescription)"
                return nil
            }
        }
        return nil
    }
    
    /// Navigate to a specific URL (for example from a file picker)
    func navigateToURL(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Couldn't access the selected location"
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            currentDirectoryURL = url
            refreshFiles()
        } else {
            errorMessage = "Selected location is not a directory"
        }
    }
    
    /// Open a directory picker to select a new location
    func selectDirectory() {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        Task {
            await loadFiles(from: documentDirectory)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Format file size to human-readable string
    func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    // MARK: - Private Methods
    
    /// Load files from a directory and create LocalFile objects
    private func loadFiles(from directory: URL) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = ""
        }
        
        do {
            // Make sure the URL is a directory
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                await MainActor.run {
                    self.errorMessage = "Not a directory: \(directory.path)"
                    self.isLoading = false
                }
                return
            }
            
            // List files and get their attributes
            let fileManager = FileManager.default
            let fileURLs = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [
                    .isDirectoryKey,
                    .fileSizeKey,
                    .contentModificationDateKey
                ],
                options: [.skipsHiddenFiles]
            )
            
            // Convert file URLs to LocalFile models
            var localFiles: [LocalFile] = []
            
            for url in fileURLs {
                if let localFile = localFileFromURL(url) {
                    localFiles.append(localFile)
                }
            }
            
            // Sort files: directories first, then alphabetically
            let sortedFiles = localFiles.sorted { (file1, file2) -> Bool in
                if file1.isDirectory && !file2.isDirectory {
                    return true
                } else if !file1.isDirectory && file2.isDirectory {
                    return false
                } else {
                    return file1.name.localizedCaseInsensitiveCompare(file2.name) == .orderedAscending
                }
            }
            
            await MainActor.run {
                self.currentDirectoryURL = directory
                self.files = sortedFiles
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load directory: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func localFileFromURL(_ url: URL) -> LocalFile? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
            let isDirectory = resourceValues.isDirectory ?? false
            
            return LocalFile(
                name: url.lastPathComponent,
                url: url,
                isDirectory: isDirectory,
                size: Int64(resourceValues.fileSize ?? 0),
                modificationDate: resourceValues.contentModificationDate
            )
        } catch {
            print("Error getting file attributes: \(error)")
            return nil
        }
    }
}
