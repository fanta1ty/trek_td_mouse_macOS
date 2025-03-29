//
//  PreviewFileInfo.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import Foundation

struct PreviewFileInfo {
    let name: String
    let fileProvider: () async throws -> Data
    let fileExtension: String
}
