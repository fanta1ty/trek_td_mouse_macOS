//
//  Utils.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import Foundation

struct Helpers {
    // MARK: - File Icons
    
    private static let fileTypeIcons: [String: String] = [
        // Document types
        "pdf": "doc.text",
        "doc": "doc.text",
        "docx": "doc.text",
        "txt": "doc.text",
        "rtf": "doc.text",
        
        // Image types
        "jpg": "photo",
        "jpeg": "photo",
        "png": "photo",
        "gif": "photo",
        "tiff": "photo",
        "bmp": "photo",
        
        // Audio types
        "mp3": "music.note",
        "wav": "music.note",
        "aac": "music.note",
        "m4a": "music.note",
        
        // Video types
        "mp4": "film",
        "mov": "film",
        "avi": "film",
        "mkv": "film",
        
        // Spreadsheets
        "xls": "chart.bar.doc.horizontal",
        "xlsx": "chart.bar.doc.horizontal",
        
        // Presentations
        "ppt": "chart.bar.doc.horizontal",
        "pptx": "chart.bar.doc.horizontal",
        
        // Archives
        "zip": "archivebox",
        "rar": "archivebox",
        "7z": "archivebox",
        "tar": "archivebox",
        "gz": "archivebox"
    ]
    
    // MARK: - File Type Categories
    
    private static let pdfExtensions: Set<String> = ["pdf"]
    
    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "gif", "tiff", "bmp", "heic"
    ]
    
    private static let textExtensions: Set<String> = [
        "txt", "rtf", "md", "csv", "json", "xml", "log",
        "swift", "js", "css", "py"
    ]
    
    private static let videoExtensions: Set<String> = [
        "mp4", "mov", "avi", "mkv", "m4v"
    ]
    
    private static let audioExtensions: Set<String> = [
        "mp3", "wav", "m4a", "aac"
    ]
    
    private static let webExtensions: Set<String> = [
        "htm", "html", "xhtml"
    ]
    
    // MARK: - Previewable File Types
    
    private static let previewableExtensions: Set<String> = [
        // Images
        "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp", "svg",
        
        // Documents
        "pdf", "txt", "rtf", "md", "csv", "json", "xml",
        
        // Microsoft Office
        "doc", "docx", "xls", "xlsx", "ppt", "pptx",
        
        // Media - Video
        "mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv", "webm", "3gp",
        
        // Media - Audio
        "mp3", "wav", "m4a", "aac", "ogg", "flac", "wma",
        
        // Web
        "html", "htm", "xhtml",
        
        // Code
        "swift", "js", "py", "css", "java", "c", "cpp", "h", "ts", "rb", "php", "go"
    ]
    
    // MARK: - Formatters
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    private static let sizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter
    }()
    
    // MARK: - Public Methods
    
    static func iconForFile(_ fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        return fileTypeIcons[ext] ?? "doc"
    }
    
    static func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    static func formatFileSize(_ size: UInt64) -> String {
        return sizeFormatter.string(fromByteCount: Int64(size))
    }
    
    static func determineFileType(fileExtension: String) -> FileType {
        let ext = fileExtension.lowercased()
        
        if pdfExtensions.contains(ext) {
            return .pdf
        } else if imageExtensions.contains(ext) {
            return .image
        } else if textExtensions.contains(ext) {
            return .text
        } else if videoExtensions.contains(ext) {
            return .video
        } else if audioExtensions.contains(ext) {
            return .audio
        } else if webExtensions.contains(ext) {
            return .web
        } else {
            return .other
        }
    }
    
    static func isPreviewableFileType(_ fileName: String) -> Bool {
        let fileExtension = fileName.components(separatedBy: ".").last?.lowercased() ?? ""
        return previewableExtensions.contains(fileExtension)
    }
}
