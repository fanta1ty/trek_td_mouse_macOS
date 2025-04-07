//
//  LocalFile.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import Foundation
import Combine
import CoreTransferable
import SwiftUI
import Photos

struct LocalFile: Identifiable, Equatable {
    let id: UUID = UUID()
    var name: String
    var url: URL
    var isDirectory: Bool
    var size: Int64
    var modificationDate: Date?
    
    // Properties for photo assets
    let isPhotoAsset: Bool
    let photoAsset: PHAsset?
    
    var icon: String {
        if let _ = photoAsset {
            return "photo"
        }
        
        if isDirectory {
            return "folder"
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
    
    var fileColor: Color {
        if let _ = photoAsset {
            return .green
        } else if isDirectory {
            return .green
        } else {
            let ext = name.components(separatedBy: ".").last?.lowercased() ?? ""
            switch ext {
            case "pdf":
                return .red
            case "jpg", "jpeg", "png", "gif", "heic":
                return .green
            case "mp3", "wav", "m4a":
                return .pink
            case "mp4", "mov", "avi":
                return .purple
            case "doc", "docx":
                return .blue
            case "xls", "xlsx":
                return .green
            case "ppt", "pptx":
                return .orange
            case "zip", "rar", "7z":
                return .gray
            default:
                return .secondary
            }
        }
    }
    
    var isPreviewable: Bool {
        return Helpers.isPreviewableFileType(name) && !isDirectory
    }
    
    init(
        name: String,
        url: URL,
        isDirectory: Bool,
        size: Int64,
        modificationDate: Date?
    ) {
        self.name = name
        self.url = url
        self.isDirectory = isDirectory
        self.size = size
        self.modificationDate = modificationDate
        self.isPhotoAsset = false
        self.photoAsset = nil
    }
    
    init(fromPhotoAsset asset: PHAsset) {
        let assetName: String
        
        // Generate a name based on asset type and date
        if asset.mediaType == .image {
            assetName = "IMG_\(Int(asset.creationDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970))"
        } else if asset.mediaType == .video {
            assetName = "VID_\(Int(asset.creationDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970))"
        } else {
            assetName = "ASSET_\(Int(asset.creationDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970))"
        }
        
        self.name = assetName
        self.url = URL(string: "photos://\(asset.localIdentifier)")!
        self.isDirectory = false
        self.modificationDate = asset.modificationDate ?? asset.creationDate ?? Date()
        
        // Approximate size based on asset type
        if asset.mediaType == .video {
            // Estimate video size based on duration (rough estimate)
            self.size = Int64(asset.duration * 5_000_000)
        } else {
            // Default estimated size for photos
            self.size = 5_000_000
        }
        
        self.isPhotoAsset = true
        self.photoAsset = asset
    }
    
    static func == (lhs: LocalFile, rhs: LocalFile) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.url == rhs.url
    }
}
