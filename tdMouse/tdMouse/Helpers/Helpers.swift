//
//  Utils.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import Foundation

struct Helpers {
    static func iconForFile(_ fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        
        switch ext {
        case "pdf":
            return "doc.text"
        case "jpg", "jpeg", "png", "gif", "tiff", "bmp":
            return "photo"
        case "mp3", "wav", "aac", "m4a":
            return "music.note"
        case "mp4", "mov", "avi", "mkv":
            return "film"
        case "doc", "docx":
            return "doc.text"
        case "xls", "xlsx":
            return "chart.bar.doc.horizontal"
        case "ppt", "pptx":
            return "chart.bar.doc.horizontal"
        case "zip", "rar", "7z", "tar", "gz":
            return "archivebox"
        case "txt", "rtf":
            return "doc.text"
        default:
            return "doc"
        }
    }
    
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    static func formatFileSize(_ size: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    static func determineFileType(fileExtension: String) -> FileType {
        switch fileExtension {
        case "pdf":
            return .pdf
        case "jpg", "jpeg", "png", "gif", "tiff", "bmp", "heic":
            return .image
        case "txt", "rtf", "md", "csv", "json", "xml", "log", "swift", "js", "css", "py":
            return .text
        case "mp4", "mov", "avi", "mkv", "m4v":
            return .video
        case "mp3", "wav", "m4a", "aac":
            return .audio
        case "htm", "html", "xhtml":
            return .web
        default:
            return .other
        }
    }
    
    static func isPreviewableFileType(_ fileName: String) -> Bool {
        let fileExtension = fileName.components(separatedBy: ".").last?.lowercased() ?? ""
        
        let previewableExtensions = [
            // Images
            "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic",
            
            // Documents
            "pdf", "txt", "rtf", "md", "csv", "json", "xml",
            
            // Media
            "mp3", "wav", "m4a", "mp4", "mov", "avi", "m4v",
            
            // Web
            "html", "htm", "xhtml",
            
            // Code
            "swift", "js", "py", "css", "java", "c", "cpp", "h"
        ]
        
        return previewableExtensions.contains(fileExtension)
    }
}

