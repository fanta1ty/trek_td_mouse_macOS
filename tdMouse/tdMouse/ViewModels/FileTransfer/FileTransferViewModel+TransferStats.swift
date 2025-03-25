//
//  FileTransferViewModel+TransferStats.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 25/3/25.
//

import Foundation

// MARK: - Transfer Statistics Methods
extension FileTransferViewModel {
    /// Start tracking a new transfer
    func startTransferTracking(
        fileName: String,
        fileSize: UInt64,
        type: TransferStats.TransferType
    ) {
        transferStartTime = Date()
        speedSamples = []
        lastTransferredBytes = 0
        currentTransferredBytes = 0
        currentFileName = fileName
        currentTransferType = type
        
        // Start the sampling timer
        stopSpeedSamplingTimer()
        speedSamplingTimer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true,
            block: { [weak self] _ in
                guard let self else { return }
                self.updateSpeedSample()
            })
    }
    
    /// Update the speed sample based on current progress
    func updateSpeedSample() {
        guard let startTime = transferStartTime else { return }
        
        let now = Date()
        let elapsed = now.timeIntervalSince(startTime)
        if elapsed > 0 {
            // Calculate current speed in bytes per second
            let bytesTransferred = currentTransferredBytes - lastTransferredBytes
            let instantSpeed = Double(bytesTransferred) / 0.5
            
            if instantSpeed > 0 {
                speedSamples.append(instantSpeed)
            }
            
            lastTransferredBytes = currentTransferredBytes
        }
    }
    
    /// Stop the speed sampling timer
    func stopSpeedSamplingTimer() {
        speedSamplingTimer?.invalidate()
        speedSamplingTimer = nil
    }
    
    /// Update the current transfer progress
    func updateTransferProgress(bytesTransferred: UInt64) {
        currentTransferredBytes = bytesTransferred
    }
    
    /// Finish tracking a transfer and generate stats
    func finishTransferTracking(fileSize: UInt64) {
        stopSpeedSamplingTimer()
        
        guard let startTime = transferStartTime else {
            print("Error: attempted to finish transfer tracking with no start time")
            return
        }
        
        let endTime = Date()
        
        let stats = TransferStats(
            fileSize: fileSize,
            fileName: currentFileName,
            startTime: startTime,
            endTime: endTime,
            transferType: currentTransferType,
            speedSamples: speedSamples
        )
        
        // Make sure this runs on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lastTransferStats = stats
            
            // Add a small delay to ensure UI updates properly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showTransferSummary = true
            }
            
            print("Transfer complete: \(stats.fileName) - \(stats.fileSize)")
        }
        
        // Reset tracking data
        transferStartTime = nil
        speedSamples = []
        currentFileName = ""
    }
}
