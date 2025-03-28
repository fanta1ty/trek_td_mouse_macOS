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
    
    var sampleBasedAverageSpeed: Double {
        guard !speedSamples.isEmpty else { return averageSpeed }
        return speedSamples.reduce(0, +) / Double(speedSamples.count)
    }
    
    var prettyFileSize: String {
        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }
    
    var prettySpeed: String {
        let speed = sampleBasedAverageSpeed > 0 ? sampleBasedAverageSpeed : averageSpeed
        return ByteCountFormatter.string(fromByteCount: Int64(speed), countStyle: .memory) + "/s"
    }
    
    var prettyDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        
        return formatter.string(from: duration) ?? "\(Int(duration))s"
    }
    
    var maxSpeed: Double {
        speedSamples.max() ?? averageSpeed
    }
}
