//
//  LocalFileViewModel.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import Combine
import Foundation

class LocalFileViewModel: ObservableObject {
    @Published var files: [LocalFile] = []
    @Published var currentDirectoryURL: URL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    var canNavigateUp: Bool {
        currentDirectoryURL != FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    }
    
    func initialize() {
        // Start at user's home directory
        refreshFiles()
    }
    
    func refreshFiles() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileManager = FileManager.default
                let contents = try fileManager.contentsOfDirectory(
                    at: self.currentDirectoryURL,
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
                    
                    if url.lastPathComponent.lowercased() == "downloads" {
                        files.append(
                            LocalFile(
                                name: url.lastPathComponent,
                                url: url,
                                isDirectory: true,
                                size: Int64(fileSize),
                                modificationDate: modificationDate
                            )
                        )
                    } else {
                        files.append(
                            LocalFile(
                                name: url.lastPathComponent,
                                url: url,
                                isDirectory: isDirectory,
                                size: Int64(fileSize),
                                modificationDate: modificationDate
                            )
                        )
                    }
                }
                
                // Sort directories first, then by name
                files.sort { lhs, rhs in
                    if lhs.isDirectory && !rhs.isDirectory { return true }
                    else if !lhs.isDirectory && rhs.isDirectory { return false }
                    else { return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending }
                }
                
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
    
    func navigateUp() {
        guard canNavigateUp else { return }
        currentDirectoryURL = currentDirectoryURL.deletingLastPathComponent()
        refreshFiles()
    }
    
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
    
    func deleteFile(_ file: LocalFile) {
        do {
            try FileManager.default.removeItem(at: file.url)
            refreshFiles()
        } catch {
            errorMessage = "Error deleting file: \(error.localizedDescription)"
        }
    }
    
    func getFileFromURL(_ url: URL) -> LocalFile? {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
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
    
    func navigateToURL(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            currentDirectoryURL = url
            refreshFiles()
        }
    }
}
