//
//  TransferTask.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 12/3/25.
//

import Foundation

struct TransferTask: Identifiable, Sendable {
    let id = UUID()
    let fileName: String
    let sourcePath: String
    let destinationPath: String
    let size: Int64
    let direction: TransferDirection
    
    var progress: Double = 0.0
    var isCompleted: Bool = false
    var error: String? = nil
}
