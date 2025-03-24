//
//  File+Ext.swift
//  tdMouse
//
//  Created by mobile on 22/3/25.
//

import SMBClient
import Foundation

extension File {
    var systemIconName: String {
        if self.isDirectory {
            return "folder"
        }
        
        let ext = self.name.components(separatedBy: ".").last?.lowercased() ?? ""
        
        switch ext {
        case "pdf":
            return "doc.text"
        case "jpg", "jpeg", "png", "gif", "heic", "tiff":
            return "photo"
        case "mp4", "mov", "avi", "mkv":
            return "film"
        case "mp3", "wav", "aac", "m4a":
            return "music.note"
        case "doc", "docx":
            return "doc.text"
        case "xls", "xlsx":
            return "chart.bar.doc.horizontal"
        case "ppt", "pptx":
            return "chart.bar.doc.horizontal"
        case "zip", "rar", "7z", "tar", "gz":
            return "doc.zipper"
        case "txt", "rtf", "md":
            return "doc.text"
        case "html", "htm", "xhtml":
            return "globe"
        case "swift", "java", "c", "cpp", "py", "js", "php":
            return "chevron.left.forwardslash.chevron.right"
        default:
            return "doc"
        }
    }
    
    var formattedSize: String {
        guard !self.isDirectory else { return "--" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(self.size))
    }
    
    var formattedModificationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        return formatter.string(from: self.creationTime)
    }
    
    var isPreviewable: Bool {
        return Helpers.isPreviewableFileType(self.name)
    }
}
