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
    @Published var errorMessage: String? = nil
    @Published var transferProgress: Double = 0
    @Published var currentTransferName: String? = nil
    @Published var searchText: String = ""
    @Published var photoAssets: [PHAsset] = []
    @Published var selectedPhotoAssets: [PHAsset] = []
    @Published var photoAuthorizationStatus: PHAuthorizationStatus = .notDetermined
    
    private let fileManager = FileManager.default
    
    private var localDirectoryURL: URL? {
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
        
        checkPhotoLibraryPermission()
    }
}

extension LocalViewModel {
    private func refreshLocalFiles() {
        guard let localDirectoryURL else {
            errorMessage = "Could not access local document directory"
            return
        }
        
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            
            do {
                let fileURLs = try self.fileManager.contentsOfDirectory(
                    at: localDirectoryURL,
                    includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey, .fileSizeKey],
                    options: []
                )
                
                var localFiles: [LocalFile] = []
                
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
        isLoading = true
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let allAssetsResult = PHAsset.fetchAssets(with: fetchOptions)
        
        var assets: [PHAsset] = []
        allAssetsResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.photoAssets = assets
            self.isLoading = false
        }
    }
}
