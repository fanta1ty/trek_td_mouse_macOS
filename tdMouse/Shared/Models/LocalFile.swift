//
//  LocalFile.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import Foundation
import Combine
import CoreTransferable

struct LocalFile: Identifiable, Equatable {
    let id: UUID
    var name: String
    var url: URL
    var isDirectory: Bool
    var size: Int64
    var modificationDate: Date?
    
    var icon: String {
        if isDirectory {
            return "folder.fill"
        }
        
        let ext = name.components(separatedBy: ".").last?.lowercased() ?? ""
        
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
    
    var isPreviewable: Bool {
        return Helpers.isPreviewableFileType(name) && !isDirectory
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        url: URL,
        isDirectory: Bool,
        size: Int64,
        modificationDate: Date?
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.isDirectory = isDirectory
        self.size = size
        self.modificationDate = modificationDate
    }
    
    static func == (lhs: LocalFile, rhs: LocalFile) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.url == rhs.url
    }
}
