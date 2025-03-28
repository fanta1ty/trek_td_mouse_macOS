//
//  LocalFileViewModel.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import Combine
import Foundation
import AppKit

/// View model for managing local file system operations
class LocalFileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var files: [LocalFile] = []
    @Published var currentDirectoryURL: URL
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    // MARK: - Computed Properties
    
    /// Determines if navigation up the directory hierarchy is possible
    var canNavigateUp: Bool {
        // Prevent navigating above home directory
        let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        return currentDirectoryURL != downloadsDirectory
    }
    
    // MARK: - Initialization
    
    init(initialDirectory: URL? = nil) {
        // Start at downloads directory if not specified
        self.currentDirectoryURL = initialDirectory ??
            FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    }
    
    // MARK: - Public Methods
    
    /// Initialize the view model and load initial files
    func initialize() {
        refreshFiles()
    }
    
    /// Refresh the file listing for the current directory
    func refreshFiles() {
        isLoading = true
        errorMessage = ""
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let files = try self.loadFilesFromDirectory(self.currentDirectoryURL)
                
                DispatchQueue.main.async {
                    self.files = files
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error reading directory: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Navigate to a subdirectory by name
    func navigateToDirectory(_ directoryName: String) {
        let newURL = currentDirectoryURL.appendingPathComponent(directoryName)
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: newURL.path, isDirectory: &isDir), isDir.boolValue {
            currentDirectoryURL = newURL
            refreshFiles()
        } else {
            errorMessage = "\(directoryName) is not a directory"
        }
    }
    
    /// Navigate up one directory level
    func navigateUp() {
        guard canNavigateUp else { return }
        currentDirectoryURL = currentDirectoryURL.deletingLastPathComponent()
        refreshFiles()
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
        do {
            try FileManager.default.removeItem(at: file.url)
            refreshFiles()
        } catch {
            errorMessage = "Error deleting file: \(error.localizedDescription)"
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
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { [weak self] result in
            guard let self = self, result == .OK, let url = openPanel.url else { return }
            
            self.navigateToURL(url)
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
    private func loadFilesFromDirectory(_ directory: URL) throws -> [LocalFile] {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        
        var files: [LocalFile] = []
        
        for url in contents {
            let resourceValues = try url.resourceValues(
                forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
            )
            
            let isDirectory = resourceValues.isDirectory ?? false
            let fileSize = resourceValues.fileSize ?? 0
            let modificationDate = resourceValues.contentModificationDate
            
            let file = LocalFile(
                name: url.lastPathComponent,
                url: url,
                isDirectory: isDirectory,
                size: Int64(fileSize),
                modificationDate: modificationDate
            )
            
            files.append(file)
        }
        
        // Sort directories first, then by name
        return files.sorted { lhs, rhs in
            if lhs.isDirectory && !rhs.isDirectory { return true }
            else if !lhs.isDirectory && rhs.isDirectory { return false }
            else { return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending }
        }
    }
}
