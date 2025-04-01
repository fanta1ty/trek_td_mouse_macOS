//
//  PreviewFileInfo.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import Foundation

struct PreviewFileInfo {
    let title: String
    let provider: () async throws -> Data
    let `extension`: String
}
