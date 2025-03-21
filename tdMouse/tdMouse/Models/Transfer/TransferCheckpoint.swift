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
    
    init(
        remotePath: String,
        localPath: URL,
        completedItems: [String],
        totalItems: Int,
        bytesTransferred: UInt64
    ) {
        self.remotePath = remotePath
        self.localPath = localPath.path
        self.completedItems = completedItems
        self.totalItems = totalItems
        self.bytesTransferred = bytesTransferred
        self.timestamp = Date()
    }
    
    init(
        remotePath: String,
        localPathString: String,
        completedItems: [String],
        totalItems: Int,
        bytesTransferred: UInt64
    ) {
        self.remotePath = remotePath
        self.localPath = localPathString
        self.completedItems = completedItems
        self.totalItems = totalItems
        self.bytesTransferred = bytesTransferred
        self.timestamp = Date()
    }
}
