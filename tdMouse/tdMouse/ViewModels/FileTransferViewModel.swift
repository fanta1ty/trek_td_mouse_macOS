//
//  FileTransferViewModel.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 12/3/25.
//

import Combine
import SMBClient
import Foundation

class FileTransferViewModel: ObservableObject {
    @Published var credentials = SMBServerCredentials()
    @Published var isConnected: Bool = false
    @Published var isConnecting: Bool = false
    @Published var connectionError: String? = nil
    
    @Published var remoteCurrentPath: String = "/"
    @Published var localCurrentPath: String = FileManager.default.homeDirectoryForCurrentUser.path
    
    @Published var remoteFiles: [FileItem] = []
    @Published var localFiles: [FileItem] = []
    
    @Published var selectedRemoteFiles: Set<FileItem> = []
    @Published var selectedLocalFiles: Set<FileItem> = []
    
    @Published var transferTasks: [TransferTask] = []
    @Published var completedTasks: [TransferTask] = []
    
    private var smbClient: SMBClient?
    private var cancellables: Set<AnyCancellable> = []
    
    func connect() async {
        isConnecting = true
        connectionError = nil
        
        let client = SMBClient(host: credentials.host, port: credentials.port)
        
        do {
            try await client.login(username: credentials.username, password: credentials.password)
            try await client.connectShare(credentials.sharePoint)
            
            smbClient = client
            isConnected = true
            isConnecting = false
            
            await loadRemoteFiles()
            loadLocalFiles()
        } catch {
            connectionError = error.localizedDescription
            isConnecting = false
        }
    }
    
    func disconnect() {
        smbClient = nil
        isConnected = false
        remoteFiles = []
        selectedRemoteFiles = []
    }
    
    func loadRemoteFiles() async {
        guard let client = smbClient else { return }
        
        do {
            let path = remoteCurrentPath == "/" ? "" : remoteCurrentPath
            let items = try await client.listDirectory(path: path)
            
            let files = items.map { item -> FileItem in
                let fullPath = path.isEmpty ? item.name : "\(path)/\(item.name)"
                return FileItem(
                    name: item.name,
                    path: fullPath,
                    isDirectory: item.isDirectory,
                    size: Int64(item.size),
                    modificationDate: item.creationTime
                )
            }
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                
                self.remoteFiles = files
            }
        } catch {
            print("Error loading remote files: \(error)")
        }
    }
    
    func loadLocalFiles() {
        
    }
}
