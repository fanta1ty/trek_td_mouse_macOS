//
//  TransferError.swift
//  tdMouse
//
//  Created by mobile on 21/3/25.
//

import Foundation

enum TransferError: Error, LocalizedError {
    case connectionFailed(host: String, underlyingError: Error?)
    case authenticationFailed(host: String, underlyingError: Error?)
    case fileDownloadFailed(fileName: String, underlyingError: Error?)
    case fileUploadFailed(fileName: String, underlyingError: Error?)
    case folderDownloadFailed(folderName: String, underlyingError: Error?)
    case folderUploadFailed(folderName: String, underlyingError: Error?)
    case navigationFailed(path: String, underlyingError: Error?)
    case fileNotFound(path: String)
    case directoryNotFound(path: String)
    case directoryCreationFailed(path: String, underlyingError: Error?)
    case fileDeletionFailed(path: String, underlyingError: Error?)
    case directoryDeletionFailed(path: String, underlyingError: Error?)
    case transferInProgress
    case invalidPath(path: String)
    case securityScopedResourceFailed(url: URL)
    case localFileReadFailed(url: URL, underlyingError: Error?)
    case localFileWriteFailed(url: URL, underlyingError: Error?)
    case unknownError(underlyingError: Error?)
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let host, let error):
            return "Failed to connect to \(host): \(error?.localizedDescription ?? "Unknown error")"
        case .authenticationFailed(let host, let error):
            return "Authentication failed for \(host): \(error?.localizedDescription ?? "Invalid credentials")"
        case .fileDownloadFailed(let fileName, let error):
            return "Failed to download file '\(fileName)': \(error?.localizedDescription ?? "Unknown error")"
        case .fileUploadFailed(let fileName, let error):
            return "Failed to upload file '\(fileName)': \(error?.localizedDescription ?? "Unknown error")"
        case .folderDownloadFailed(let folderName, let error):
            return "Failed to download folder '\(folderName)': \(error?.localizedDescription ?? "Unknown error")"
        case .folderUploadFailed(let folderName, let error):
            return "Failed to upload folder '\(folderName)': \(error?.localizedDescription ?? "Unknown error")"
        case .navigationFailed(let path, let error):
            return "Failed to navigate to '\(path)': \(error?.localizedDescription ?? "Unknown error")"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .directoryNotFound(let path):
            return "Directory not found: \(path)"
        case .directoryCreationFailed(let path, let error):
            return "Failed to create directory '\(path)': \(error?.localizedDescription ?? "Unknown error")"
        case .fileDeletionFailed(let path, let error):
            return "Failed to delete file '\(path)': \(error?.localizedDescription ?? "Unknown error")"
        case .directoryDeletionFailed(let path, let error):
            return "Failed to delete directory '\(path)': \(error?.localizedDescription ?? "Unknown error")"
        case .transferInProgress:
            return "A transfer is already in progress"
        case .invalidPath(let path):
            return "Invalid path: \(path)"
        case .securityScopedResourceFailed(let url):
            return "Failed to access security scoped resource: \(url.path)"
        case .localFileReadFailed(let url, let error):
            return "Failed to read local file '\(url.lastPathComponent)': \(error?.localizedDescription ?? "Unknown error")"
        case .localFileWriteFailed(let url, let error):
            return "Failed to write to local file '\(url.lastPathComponent)': \(error?.localizedDescription ?? "Unknown error")"
        case .unknownError(let error):
            return "An unknown error occurred: \(error?.localizedDescription ?? "No details available")"
        }
    }
}
