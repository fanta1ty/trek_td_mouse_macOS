//
//  TransferCheckpoint.swift
//  tdMouse
//
//  Created by mobile on 21/3/25.
//

import Foundation

struct TransferCheckpoint: Codable {
    let remotePath: String
    let localPath: String
    let completedItems: [String]
    let totalItems: Int
    let bytesTransferred: UInt64
    let timestamp: Date
    let transferDirection: String
    
    var transferDirectionEnum: TransferDirection {
        return transferDirection == "toLocal" ? .toLocal : .toRemote
    }
    
    var localURL: URL {
        return URL(fileURLWithPath: localPath)
    }
    
    var progress: Double {
        return totalItems > 0 ? Double(completedItems.count) / Double(totalItems) : 0
    }
    
    var isValid: Bool {
        // Check if the checkpoint is still valid (e.g., not too old)
        let maxAgeInSeconds: TimeInterval = 60 * 60 * 24 // 24 hours
        return Date().timeIntervalSince(timestamp) < maxAgeInSeconds
    }
    
    init(
        remotePath: String,
        localPath: URL,
        completedItems: [String],
        totalItems: Int,
        bytesTransferred: UInt64,
        direction: TransferDirection
    ) {
        self.remotePath = remotePath
        self.localPath = localPath.path
        self.completedItems = completedItems
        self.totalItems = totalItems
        self.bytesTransferred = bytesTransferred
        self.timestamp = Date()
        self.transferDirection = direction == .toLocal ? "toLocal" : "toRemote"
    }
}
