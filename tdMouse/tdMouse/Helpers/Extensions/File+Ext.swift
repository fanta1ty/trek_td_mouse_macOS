//
//  File+Ext.swift
//  tdMouse
//
//  Created by mobile on 22/3/25.
//

import SMBClient
import Foundation

extension File {
    // MARK: - Computed Properties
    
    var systemIconName: String {
        if isDirectory {
            return "folder"
        }
        
        let ext = name.components(separatedBy: ".").last?.lowercased() ?? ""
        return FileIconMapper.iconName(for: ext)
    }
    
    var formattedSize: String {
        guard !isDirectory else { return "--" }
        
        return ByteCountFormatter.fileSize.string(fromByteCount: Int64(size))
    }
    
    var formattedModificationDate: String {
        return DateFormatter.shortDateTime.string(from: creationTime)
    }
    
    var isPreviewable: Bool {
        return Helpers.isPreviewableFileType(name)
    }
    
    // Removed duplicate fileIcon property as it's redundant with systemIconName
}

// MARK: - File Icon Mapper

private enum FileIconMapper {
    // Store file types in categorized dictionaries for better organization and lookup performance
    private static let documentIcons: [String: String] = [
        "pdf": "doc.text",
        "doc": "doc.text",
        "docx": "doc.text",
        "txt": "doc.text",
        "rtf": "doc.text",
        "md": "doc.text"
    ]
    
    private static let imageIcons: [String: String] = [
        "jpg": "photo",
        "jpeg": "photo",
        "png": "photo",
        "gif": "photo",
        "heic": "photo",
        "tiff": "photo"
    ]
    
    private static let videoIcons: [String: String] = [
        "mp4": "film",
        "mov": "film",
        "avi": "film",
        "mkv": "film"
    ]
    
    private static let audioIcons: [String: String] = [
        "mp3": "music.note",
        "wav": "music.note",
        "aac": "music.note",
        "m4a": "music.note"
    ]
    
    private static let spreadsheetIcons: [String: String] = [
        "xls": "chart.bar.doc.horizontal",
        "xlsx": "chart.bar.doc.horizontal"
    ]
    
    private static let presentationIcons: [String: String] = [
        "ppt": "chart.bar.doc.horizontal",
        "pptx": "chart.bar.doc.horizontal"
    ]
    
    private static let archiveIcons: [String: String] = [
        "zip": "doc.zipper",
        "rar": "doc.zipper",
        "7z": "doc.zipper",
        "tar": "doc.zipper",
        "gz": "doc.zipper"
    ]
    
    private static let webIcons: [String: String] = [
        "html": "globe",
        "htm": "globe",
        "xhtml": "globe"
    ]
    
    private static let codeIcons: [String: String] = [
        "swift": "chevron.left.forwardslash.chevron.right",
        "java": "chevron.left.forwardslash.chevron.right",
        "c": "chevron.left.forwardslash.chevron.right",
        "cpp": "chevron.left.forwardslash.chevron.right",
        "py": "chevron.left.forwardslash.chevron.right",
        "js": "chevron.left.forwardslash.chevron.right",
        "php": "chevron.left.forwardslash.chevron.right"
    ]
    
    static func iconName(for extension: String) -> String {
        // Check each category for the file extension
        if let icon = documentIcons[`extension`] { return icon }
        if let icon = imageIcons[`extension`] { return icon }
        if let icon = videoIcons[`extension`] { return icon }
        if let icon = audioIcons[`extension`] { return icon }
        if let icon = spreadsheetIcons[`extension`] { return icon }
        if let icon = presentationIcons[`extension`] { return icon }
        if let icon = archiveIcons[`extension`] { return icon }
        if let icon = webIcons[`extension`] { return icon }
        if let icon = codeIcons[`extension`] { return icon }
        
        // Default icon
        return "doc"
    }
}

// MARK: - Formatters

extension ByteCountFormatter {
    static let fileSize: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter
    }()
}

extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
