//
//  LocalFile.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import Foundation
import Combine
import CoreTransferable

struct LocalFile: Identifiable {
    var id: String { url.absoluteString }
    var name: String
    var url: URL
    var isDirectory: Bool
    var size: Int64
    var modificationDate: Date?
    var icon: String {
        if isDirectory {
            return "folder"
        }
        return Helpers.iconForFile(name)
    }
}
