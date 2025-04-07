//
//  TransferSummary.swift
//  tdMouse
//
//  Created by mobile on 7/4/25.
//

import Foundation

struct TransferSummary {
    enum TransferType: String {
        case upload
        case download
    }
    
    let type: TransferType
    let fileCount: Int
    let directoryCount: Int
    let totalBytes: UInt64
    let startTime: Date
    let endDate: Date
    let isSuccess: Bool
    let errorMessage: String?
    let speedSamples: [Double]
    
    var duration: TimeInterval {
        endDate.timeIntervalSince(startTime)
    }
    
    var avgSpeed: Double {
        if duration > 0 {
            return Double(totalBytes) / duration
        }
        return 0
    }
    
    var peakSpeed: Double {
        speedSamples.max() ?? 0
    }
    
    var minSpeed: Double {
        speedSamples.filter { $0 > 0 }.min() ?? 0
    }
}
