//
//  TransferStats.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 14/3/25.
//

import SwiftUI

struct TransferStats {
    enum TransferType {
        case upload
        case download
    }
    
    let fileSize: UInt64
    let fileName: String
    let startTime: Date
    let endTime: Date
    let transferType: TransferType
    let speedSamples: [Double]
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    var averageSpeed: Double {
        guard duration > 0 else { return 0 }
        return Double(fileSize) / duration
    }
    
    var maxSpeed: Double {
        speedSamples.max() ?? averageSpeed
    }
}
