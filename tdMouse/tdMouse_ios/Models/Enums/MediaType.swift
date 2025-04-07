//
//  MediaType.swift
//  tdMouse
//
//  Created by mobile on 7/4/25.
//

import Foundation

enum MediaType {
    case image(format: String)
    case video(format: String)
    case audio(format: String)
    case pdf
    case text(format: String)
    case unknown
    
    var fileExtension: String {
        switch self {
        case .image(let format):
            return format.lowercased()
        case .video(let format):
            return format.lowercased()
        case .audio(let format):
            return format.lowercased()
        case .pdf:
            return "pdf"
        case .text(let format):
            return format.lowercased()
        case .unknown:
            return "bin"
        }
    }
}
