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
        destination: URL,
        smbViewModel: FileTransferViewModel,
        onComplete: @escaping () -> Void
    ) {
        Task {
            await MainActor.run {
                self.activeTransfer = .toLocal
                self.currentTransferItem = file.name
                self.transferProgress = 0.0
                self.errorMessage = ""
            }
            
            do {
                // Get file data
                let data = try await smbViewModel.downloadFile(
                    fileName: file.name
                )
                
                // Write to destination
                try data.write(to: destination)
                
                await MainActor.run {
                    self.transferProgress = 1.0
                }
                
                // Wait a moment to show completion before clearing
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    self.activeTransfer = nil
                    self.currentTransferItem = ""
                    onComplete()
                }
            } catch {
                print("Download failed: \(error)")
                await MainActor.run {
                    self.activeTransfer = nil
                    self.currentTransferItem = ""
                    self.errorMessage = "Download failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func startSingleFileUpload(
        file: LocalFile,
        smbViewModel: FileTransferViewModel,
        onComplete: @escaping () -> Void
    ) {
        Task {
            await MainActor.run {
                self.activeTransfer = .toRemote
                self.currentTransferItem = file.name
                self.transferProgress = 0.0
                self.errorMessage = ""
            }
            
            do {
                // Upload the file
                try await smbViewModel.uploadLocalFile(url: file.url)
                
                await MainActor.run {
                    self.transferProgress = 1.0
                }
                
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    self.activeTransfer = nil
                    self.currentTransferItem = ""
                    onComplete()
                }
            } catch {
                print("Upload error: \(error)")
                await MainActor.run {
                    self.activeTransfer = nil
                    self.currentTransferItem = ""
                    self.errorMessage = "Upload failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
