//
//  ContentTypeDetector.swift
//  tdMouse
//
//  Created by mobile on 7/4/25.
//

import Foundation
import UniformTypeIdentifiers

struct ContentTypeDetector {
    static func detectMediaType(from data: Data) -> MediaType {
        guard data.count >= 16 else { return .unknown }
        
        let bytes = [UInt8](data.prefix(16))
        
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            return .image(format: "jpg")
        }
        
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
            return .image(format: "png")
        }
        
        if bytes.starts(with: [0x47, 0x49, 0x46, 0x38, 0x37, 0x61]) ||
            bytes.starts(with: [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]) {
            return .image(format: "gif")
        }
        
        if bytes.starts(with: [0x42, 0x4D]) {
            return .image(format: "bmp")
        }
        
        if bytes.starts(with: [0x49, 0x49, 0x2A, 0x00]) ||
            bytes.starts(with: [0x4D, 0x4D, 0x00, 0x2A]) {
            return .image(format: "tiff")
        }
        
        if bytes.count >= 12 && data.subdata(in: 0..<4) == Data([0x52, 0x49, 0x46, 0x46]) &&
            data.subdata(in: 8..<12) == Data([0x57, 0x45, 0x42, 0x50]) {
            return .image(format: "webp")
        }
        
        if bytes.starts(with: [0x25, 0x50, 0x44, 0x46]) {
            return .pdf
        }
        
        if bytes.count >= 8 && data.subdata(in: 4..<8) == Data([0x66, 0x74, 0x79, 0x70]) {
            // Check for specific MP4 types
            if data.count >= 12 {
                let typeSignature = data.subdata(in: 8..<12)
                if typeSignature == Data([0x6D, 0x70, 0x34, 0x32]) || // mp42
                    typeSignature == Data([0x69, 0x73, 0x6F, 0x6D]) || // isom
                    typeSignature == Data([0x6D, 0x70, 0x34, 0x31]) {  // mp41
                    return .video(format: "mp4")
                }
            }
            return .video(format: "mov") // Default to MOV for other QuickTime formats
        }
        
        if bytes.starts(with: [0x52, 0x49, 0x46, 0x46]) &&
            data.count >= 12 && data.subdata(in: 8..<12) == Data([0x41, 0x56, 0x49, 0x20]) {
            return .video(format: "avi")
        }
        
        if bytes.starts(with: [0x49, 0x44, 0x33]) || // ID3 tag
            (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) { // MPEG frame
            return .audio(format: "mp3")
        }
        
        if bytes.starts(with: [0x52, 0x49, 0x46, 0x46]) &&
            data.count >= 12 && data.subdata(in: 8..<12) == Data([0x57, 0x41, 0x56, 0x45]) {
            return .audio(format: "wav")
        }
        
        if bytes.starts(with: [0xFF, 0xF1]) || bytes.starts(with: [0xFF, 0xF9]) {
            return .audio(format: "aac")
        }
        
        var isPlainText = true
        for byte in bytes.prefix(min(bytes.count, 512)) {
            if byte < 0x09 || (byte > 0x0D && byte < 0x20 && byte != 0x1B) {
                // If non-ASCII and not a common control character, it's likely not plain text
                isPlainText = false
                break
            }
        }
        
        if isPlainText {
            return .text(format: "txt")
        }
        
        if let contentType = UTType(filenameExtension: "dat"),
           let preferredType = contentType.preferredMIMEType {
            if preferredType.contains("image/") {
                let format = preferredType.components(separatedBy: "/").last ?? "jpg"
                return .image(format: format)
            } else if preferredType.contains("video/") {
                let format = preferredType.components(separatedBy: "/").last ?? "mp4"
                return .video(format: format)
            } else if preferredType.contains("audio/") {
                let format = preferredType.components(separatedBy: "/").last ?? "mp3"
                return .audio(format: format)
            } else if preferredType.contains("text/") {
                let format = preferredType.components(separatedBy: "/").last ?? "txt"
                return .text(format: format)
            }
        }
        
        return .unknown
    }
    
    static func detectMediaType(from url: URL) -> MediaType {
        do {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            
            if let data = try handle.read(upToCount: 1024) {
                return detectMediaType(from: data)
            }
        } catch {
            print("Error reading file for type detection: \(error)")
        }
        
        return .unknown
    }
}
