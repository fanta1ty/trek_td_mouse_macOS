//
//  File+Ext2.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 1/4/25.
//

import SMBClient
import Foundation
import SwiftUI

extension File {
    func fileColor() -> Color {
        if isDirectory {
            return .blue
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
}
