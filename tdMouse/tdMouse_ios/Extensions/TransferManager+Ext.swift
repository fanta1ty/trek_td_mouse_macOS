//
//  TransferManager+Ext.swift
//  tdMouse
//
//  Created by mobile on 6/4/25.
//

import Photos

extension TransferManager {
    func startPhotoAssetUpload(
        photoAsset: PHAsset,
        fileName: String,
        destinationPath: String,
        smbViewModel: FileTransferViewModel,
        completion: @escaping () -> Void
    ) async {
        if isTransferInProgress {
            await MainActor.run {
                self.errorMessage = TransferError.transferInProgress.localizedDescription
            }
            return
        }
        
        await MainActor.run {
            self.activeTransfer = .toRemote
            self.currentTransferItem = fileName
            self.transferProgress = 0.0
            self.errorMessage = ""
        }
        
        do {
            let smbDestPath = destinationPath.hasSuffix("/") ? "\(destinationPath)\(fileName)" : "\(destinationPath)/\(fileName)"
            
            if photoAsset.mediaType == .image {
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .highQualityFormat
                options.resizeMode = .none
                options.progressHandler = { [weak self] progress, _, _, _ in
                    DispatchQueue.main.async {
                        self?.transferProgress = progress * 0.5
                    }
                }
                
                let imageData = try await withCheckedThrowingContinuation { continuation in
                    PHImageManager.default().requestImageDataAndOrientation(
                        for: photoAsset,
                        options: options) { data, _, _, info in
                            if let data {
                                continuation.resume(returning: data)
                            } else {
                                let error = NSError(domain: "PHAsset", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get image data"])
                                continuation.resume(throwing: error)
                            }
                        }
                }
                
                await MainActor.run {
                    self.transferProgress = 0.6
                }
                
                try await smbViewModel.uploadFile(data: imageData, fileName: fileName)
                
                await MainActor.run {
                    self.transferProgress = 1.0
                }
                
                // Give time for UI to show completion before removing status
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                await MainActor.run {
                    self.activeTransfer = nil
                    self.currentTransferItem = ""
                    self.transferProgress = 0.0
                    completion()
                }
                
            } else if photoAsset.mediaType == .video {
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .highQualityFormat
                options.progressHandler = { [weak self] progress, _, _, _ in
                    DispatchQueue.main.async {
                        self?.transferProgress = progress * 0.5
                    }
                }
                
                let urlAsset = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AVURLAsset, Error>) in
                    PHImageManager.default().requestAVAsset(forVideo: photoAsset, options: options) { asset, _, _ in
                        if let urlAsset = asset as? AVURLAsset {
                            continuation.resume(returning: urlAsset)
                        } else {
                            let error = NSError(domain: "PHAsset", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get video data"])
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                await MainActor.run {
                    self.transferProgress = 0.6
                }
                
                let videoData = try Data(contentsOf: urlAsset.url)
                
                try await smbViewModel.uploadFile(data: videoData, fileName: fileName)
                
                await MainActor.run {
                    self.transferProgress = 1.0
                }
                
                // Give time for UI to show completion before removing status
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                await MainActor.run {
                    self.activeTransfer = nil
                    self.currentTransferItem = ""
                    self.transferProgress = 0.0
                    completion()
                }
            }
        } catch {
            await MainActor.run {
                self.activeTransfer = nil
                self.currentTransferItem = ""
                self.totalTransferItems = 0
                self.processedTransferItems = 0
                self.isFolderTransferInProgress = false
                
                if let transferError = error as? TransferError {
                    self.errorMessage = transferError.localizedDescription
                } else {
                    self.errorMessage = "Folder upload failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
