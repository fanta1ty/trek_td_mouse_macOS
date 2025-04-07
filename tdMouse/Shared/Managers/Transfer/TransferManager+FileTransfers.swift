//
//  TransferManager+FileTransfers.swift
//  tdMouse
//
//  Created by mobile on 21/3/25.
//

import Foundation
import SMBClient

// MARK: - Single File Transfer Methods
extension TransferManager {
    func startSingleFileDownload(
        file: File,
        destinationURL: URL,
        smbViewModel: FileTransferViewModel,
        onComplete: @escaping () -> Void
    ) async {
        // Check if a transfer is already in progress
        if isTransferInProgress {
            await MainActor.run {
                self.errorMessage = TransferError.transferInProgress.localizedDescription
            }
            return
        }
        
        await MainActor.run {
            self.activeTransfer = .toLocal
            self.currentTransferItem = file.name
            self.transferProgress = 0.0
            self.errorMessage = ""
        }
        
        do {
            let data = try await smbViewModel.downloadFile(fileName: file.name)
            
            try data.write(to: destinationURL)
            
            await MainActor.run {
                self.transferProgress = 1.0
            }
            
            // Give time for UI to show completion before removing status
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                self.activeTransfer = nil
                self.currentTransferItem = ""
                self.transferProgress = 0.0
                onComplete()
            }
        } catch {
            await MainActor.run {
                self.activeTransfer = nil
                self.currentTransferItem = ""
                self.transferProgress = 0.0
                
                if let transferError = error as? TransferError {
                    self.errorMessage = transferError.localizedDescription
                } else {
                    self.errorMessage = "Download failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func startSingleFileUpload(
        file: LocalFile,
        smbViewModel: FileTransferViewModel,
        onComplete: @escaping () -> Void
    ) async {
        // Check if a transfer is already in progress
        if isTransferInProgress {
            await MainActor.run {
                self.errorMessage = TransferError.transferInProgress.localizedDescription
            }
            return
        }
        
        await MainActor.run {
            self.activeTransfer = .toRemote
            self.currentTransferItem = file.name
            self.transferProgress = 0.0
            self.errorMessage = ""
        }
        
        do {
            try await smbViewModel.uploadLocalFile(url: file.url)
            
            await MainActor.run {
                self.transferProgress = 1.0
            }
            
            // Give time for UI to show completion before removing status
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                self.activeTransfer = nil
                self.currentTransferItem = ""
                self.transferProgress = 0.0
                onComplete()
            }
        } catch {
            await MainActor.run {
                self.activeTransfer = nil
                self.currentTransferItem = ""
                self.transferProgress = 0.0
                
                if let transferError = error as? TransferError {
                    self.errorMessage = transferError.localizedDescription
                } else {
                    self.errorMessage = "Upload failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
