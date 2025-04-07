//
//  LocalViewModel.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import SwiftUI
import Combine
import Photos

class LocalViewModel: ObservableObject {
    @Published var localFiles: [LocalFile] = []
    @Published var isLoading: Bool = false
    @Published var canNavigateUp: Bool = false
    @Published var showPhotoAssets: Bool = true
    @Published var errorMessage: String? = nil
    @Published var currentTransferName: String? = nil
    @Published var searchText: String = ""
    @Published var transferProgress: Double = 0
    @Published var photoAssets: [PHAsset] = []
    @Published var selectedPhotoAssets: [PHAsset] = []
    @Published var photoAuthorizationStatus: PHAuthorizationStatus = .notDetermined
    
    
    private let fileManager = FileManager.default
    var currentDirectory: URL?
    var localDirectory: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            .first
    }
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                guard let self else { return }
                
                self.refreshLocalFiles()
            }
            .store(in: &cancellables)
        
        currentDirectory = localDirectory
        
        checkPhotoLibraryPermission()
        
        refreshLocalFiles()
    }
}

extension LocalViewModel {
    func refreshLocalFiles() {
        guard let directory = currentDirectory ?? localDirectory else {
            errorMessage = "Could not access local document directory"
            return
        }
        
        isLoading = true
        
        if let localDirectory {
            canNavigateUp = directory.path != localDirectory.path && directory.path.count > localDirectory.path.count
        } else {
            canNavigateUp = false
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            
            var localFiles: [LocalFile] = []
            let isAtRootDirectory = (self.localDirectory?.path == directory.path)
            let shouldIncludePhotoAssets = isAtRootDirectory && self.showPhotoAssets
            
            do {
                let fileURLs = try self.fileManager.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey, .fileSizeKey],
                    options: []
                )
                
                for fileURL in fileURLs {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey, .fileSizeKey])
                    let fileName = fileURL.lastPathComponent
                    
                    if !self.searchText.isEmpty && !fileName.localizedStandardContains(self.searchText) {
                        continue
                    }
                    
                    let isDirectory = resourceValues.isDirectory ?? false
                    let modificationDate = resourceValues.contentModificationDate ?? Date()
                    let fileSize = resourceValues.fileSize ?? 0
                    
                    let localFile = LocalFile(
                        name: fileName,
                        url: fileURL,
                        isDirectory: isDirectory,
                        size: Int64(fileSize),
                        modificationDate: modificationDate
                    )
                    
                    localFiles.append(localFile)
                }
                
                // Add photo assets if we're at the root directory and showPhotoAssets is enabled
                if shouldIncludePhotoAssets && (self.photoAuthorizationStatus == .authorized || self.photoAuthorizationStatus == .limited) {
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                    
                    if !self.searchText.isEmpty {
                        fetchOptions.predicate = NSPredicate(format: "creationDate >= %@", NSDate.distantPast as CVarArg)
                    }
                    
                    let allAssetsResult = PHAsset.fetchAssets(with: fetchOptions)
                    
                    allAssetsResult.enumerateObjects { (asset, index, stop) in
                        if self.searchText.isEmpty ||
                            (asset.creationDate?.description.localizedCaseInsensitiveContains(self.searchText) ?? false) {
                            localFiles.append(LocalFile(fromPhotoAsset: asset))
                        }
                    }
                }
                
                // Sort files by name
                localFiles.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                
                DispatchQueue.main.async {
                    self.localFiles = localFiles
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error loading local files: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func navigateUp() {
        guard canNavigateUp, let currentDir = currentDirectory else { return }
        
        currentDirectory = currentDir.deletingLastPathComponent()
        
        refreshLocalFiles()
    }
    
    func navigateToDirectory(localFile: LocalFile) {
        guard localFile.isDirectory else {
            errorMessage = "Selected item is not a directory"
            return
        }
        
        currentDirectory = localFile.url
        refreshLocalFiles()
    }
    
    func createDirectory(directoryName: String) throws {
        guard let localDirectory else {
            throw NSError(
                domain: "LocalViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not access Documents directory"]
            )
        }
        
        let directoryURL = localDirectory.appendingPathComponent(directoryName)
        
        // Check if directory already exists
        if fileManager.fileExists(atPath: directoryURL.path) {
            throw NSError(
                domain: "LocalViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Directory already exists at \(directoryURL.path)"]
            )
        }
        
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        refreshLocalFiles()
    }
}

// MARK: - Photo Library Methods
extension LocalViewModel {
    func checkPhotoLibraryPermission() {
        photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if photoAuthorizationStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                guard let self else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.photoAuthorizationStatus = status
                    if status == .authorized || status == .limited {
                        self.fetchPhotoAssets()
                    }
                }
            }
        } else if photoAuthorizationStatus == .authorized || photoAuthorizationStatus == .limited {
            self.fetchPhotoAssets()
        }
    }
    
    func fetchPhotoAssets() {
        if showPhotoAssets {
            refreshLocalFiles()
        }
    }
    
    func togglePhotoAssets() {
        showPhotoAssets.toggle()
        refreshLocalFiles()
    }
}

extension LocalViewModel {
    enum AssetFetchingError: Error, LocalizedError {
        case assetNotFound
        case requestFailed
        case dataUnavailable
        
        var errorDescription: String? {
            switch self {
            case .assetNotFound:
                return "The asset could not be found"
            case .requestFailed:
                return "Failed to fetch the asset"
            case .dataUnavailable:
                return "Asset data is unavailable"
            }
        }
    }
    
    func fetchImageAsset(_ asset: PHAsset, quality: CGFloat = 1.0) async throws -> Data {
        // Verify asset is an image
        guard asset.mediaType == .image else {
            throw AssetFetchingError.assetNotFound
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.version = .current
            options.resizeMode = .none
            options.isSynchronous = false
            
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let imageData = data else {
                    continuation.resume(throwing: AssetFetchingError.dataUnavailable)
                    return
                }
                
                // Compress if needed
                if quality < 1.0, let image = UIImage(data: imageData) {
                    // Get file URL if available
                    let fileURL = info?["PHImageFileURLKey"] as? URL
                    let ext = fileURL?.pathExtension.lowercased() ?? ""
                    
                    // Determine if JPEG or HEIC from extension or try to detect from data
                    let isJpeg = ext == "jpg" || ext == "jpeg" ||
                    (imageData.count > 2 && imageData[0] == 0xFF && imageData[1] == 0xD8)
                    let isHeic = ext == "heic" || ext == "heif"
                    
                    if isJpeg {
                        if let compressedData = image.jpegData(compressionQuality: quality) {
                            continuation.resume(returning: compressedData)
                            return
                        }
                    } else if isHeic {
                        // Convert HEIC to JPEG for better compatibility
                        if let jpegData = image.jpegData(compressionQuality: quality) {
                            continuation.resume(returning: jpegData)
                            return
                        }
                    } else {
                        // For other formats, use JPEG compression for consistency
                        if let jpegData = image.jpegData(compressionQuality: quality) {
                            continuation.resume(returning: jpegData)
                            return
                        }
                    }
                }
                
                continuation.resume(returning: imageData)
            }
        }
    }
    
    func fetchImageAssetWithSize(_ asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode = .aspectFit) async throws -> Data {
        guard asset.mediaType == .image else {
            throw AssetFetchingError.assetNotFound
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.version = .current
            options.resizeMode = .exact
            options.isSynchronous = false
            
            PHImageManager.default().requestImage(for: asset,
                                                  targetSize: targetSize,
                                                  contentMode: contentMode,
                                                  options: options) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let image = image else {
                    continuation.resume(throwing: AssetFetchingError.dataUnavailable)
                    return
                }
                
                // Convert UIImage to Data
                if let jpegData = image.jpegData(compressionQuality: 0.9) {
                    continuation.resume(returning: jpegData)
                    return
                }
                
                continuation.resume(throwing: AssetFetchingError.dataUnavailable)
            }
        }
    }
    
    func fetchVideoAsset(_ asset: PHAsset) async throws -> Data {
        guard asset.mediaType == .video else {
            throw AssetFetchingError.assetNotFound
        }
        
        // Get the AVAsset first
        let avAsset = try await fetchAVAsset(for: asset)
        
        // Get the file URL
        guard let urlAsset = avAsset as? AVURLAsset else {
            throw AssetFetchingError.dataUnavailable
        }
        
        // Read the file data
        return try Data(contentsOf: urlAsset.url)
    }
    
    func fetchAVAsset(for asset: PHAsset) async throws -> AVAsset {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.version = .current
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let avAsset = avAsset else {
                    continuation.resume(throwing: AssetFetchingError.dataUnavailable)
                    return
                }
                
                continuation.resume(returning: avAsset)
            }
        }
    }
    
    func fetchVideoThumbnail(for asset: PHAsset, at time: CMTime = CMTime(seconds: 1, preferredTimescale: 60), targetSize: CGSize = CGSize(width: 300, height: 300)) async throws -> Data {
        guard asset.mediaType == .video else {
            throw AssetFetchingError.assetNotFound
        }
        
        // Get the AVAsset
        let avAsset = try await fetchAVAsset(for: asset)
        
        // Create thumbnail
        let imageGenerator = AVAssetImageGenerator(asset: avAsset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = targetSize
        
        let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
        let image = UIImage(cgImage: cgImage)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AssetFetchingError.dataUnavailable
        }
        
        return imageData
    }
    
    func exportVideoAssetToFile(_ asset: PHAsset) async throws -> URL {
        // Get the AVAsset
        let avAsset = try await fetchAVAsset(for: asset)
        
        // If it's already a URL asset, we can copy the file
        if let urlAsset = avAsset as? AVURLAsset {
            let tempDir = FileManager.default.temporaryDirectory
            let fileExt = urlAsset.url.pathExtension
            let tempURL = tempDir.appendingPathComponent(UUID().uuidString + ".\(fileExt)")
            
            try FileManager.default.copyItem(at: urlAsset.url, to: tempURL)
            return tempURL
        }
        
        // Otherwise, we need to export it
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(UUID().uuidString + ".mp4")
        
        return try await withCheckedThrowingContinuation { continuation in
            guard let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetHighestQuality) else {
                continuation.resume(throwing: AssetFetchingError.requestFailed)
                return
            }
            
            exportSession.outputURL = tempURL
            exportSession.outputFileType = .mp4
            
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume(returning: tempURL)
                case .failed, .cancelled:
                    continuation.resume(throwing: exportSession.error ?? AssetFetchingError.requestFailed)
                default:
                    continuation.resume(throwing: AssetFetchingError.requestFailed)
                }
            }
        }
    }
    
    func getAssetExtension(_ asset: PHAsset) -> String? {
        // This is a best-effort approach since PHAsset doesn't directly expose the file extension
        
        // For images, we can try to get the resource info
        let resources = PHAssetResource.assetResources(for: asset)
        
        if let resource = resources.first {
            let uti = resource.uniformTypeIdentifier
            // Try to extract extension from uniform type identifier
            
            if uti.contains("jpeg") || uti.contains("jpg") {
                return "jpg"
            } else if uti.contains("png") {
                return "png"
            } else if uti.contains("heic") {
                return "heic"
            } else if uti.contains("gif") {
                return "gif"
            } else if uti.contains("tiff") {
                return "tiff"
            } else if uti.contains("mp4") {
                return "mp4"
            } else if uti.contains("mov") {
                return "mov"
            } else if uti.contains("avi") {
                return "avi"
            }
            
            
            // Try to get extension from filename
            let filename = resource.originalFilename
            let ext = (filename as NSString).pathExtension.lowercased()
            if !ext.isEmpty {
                return ext
            }
        }
        
        // Fallback to default extensions based on media type
        return asset.mediaType == .image ? "jpg" : "mp4"
    }
}
