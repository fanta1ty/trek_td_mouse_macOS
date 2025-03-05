import Foundation
import SMBClient
import AppKit

protocol FileTransfer {
    var id: UUID { get }
    var displayName: String { get }
    var state: TransferState { get }
    var progressHandler: (_ state: TransferState) -> Void { get set }
    var startTime: Date? { get set }
    var endTime: Date? { get set }
    var maxSpeed: Double { get set }
    
    func start() async
    func calculateSummary(fileSize: Int64) -> TransferSummary
}

extension FileTransfer {
    func calculateSummary(fileSize: Int64) -> TransferSummary {
        guard let startTime, let endTime else {
            return TransferSummary(fileSize: fileSize, timeTaken: 0, averageSpeed: 0, maxSpeed: maxSpeed)
        }
        let timeTaken = endTime.timeIntervalSince(startTime)
        let avgSpeed = timeTaken > 0 ? Double(fileSize) / timeTaken : 0
        return TransferSummary(fileSize: fileSize, timeTaken: timeTaken, averageSpeed: avgSpeed, maxSpeed: maxSpeed)
    }
}

enum TransferState {
    case queued
    case started(TransferProgress)
    case completed(TransferProgress)
    case failed(Error)
}

enum TransferProgress {
    case file(progress: Double, numberOfBytes: Int64, speed: Double)
    case directory(completedFiles: Int, fileBeingTransferred: URL?,  bytesSent: Int64)
}

class FileUpload: FileTransfer {
    static let didFinish = Notification.Name("FileUploadDidFinish")
    
    let displayName: String
    var state: TransferState
    var progressHandler: (_ state: TransferState) -> Void
    var startTime: Date?
    var endTime: Date?
    var maxSpeed: Double = 0
    
    let id: UUID
    private let source: URL
    private let destination: String
    private let treeAccessor: TreeAccessor
    
    init(source: URL, destination: String, accessor: TreeAccessor) {
        id = UUID()
        self.source = source
        self.destination = destination
        treeAccessor = accessor
        
        displayName = source.lastPathComponent
        state = .queued
        progressHandler = { _ in }
    }
    
    func start() async {
        let fileManager = FileManager()
        var isDirectory: ObjCBool = false
        
        do {
            guard fileManager.fileExists(atPath: source.path, isDirectory: &isDirectory) else {
                throw URLError(.fileDoesNotExist)
            }
            
            startTime = Date()
            var transferProgress: TransferProgress
            if isDirectory.boolValue {
                transferProgress = .directory(completedFiles: 0, fileBeingTransferred: nil, bytesSent: 0)
                state = .started(transferProgress)
                progressHandler(state)
                
                try await treeAccessor.upload(localPath: source, remotePath: destination) { (completedFiles, fileBeingTransferred, bytesSent) in
                    transferProgress = .directory(completedFiles: completedFiles, fileBeingTransferred: fileBeingTransferred, bytesSent: bytesSent)
                    state = .started(transferProgress)
                    progressHandler(state)
                }
            } else {
                let fileManager = FileManager()
                let attributes = try fileManager.attributesOfItem(atPath: source.pathname)
                
                guard let fileSize = attributes[.size] as? Int64 else { throw URLError(.zeroByteResource) }
                let numberOfBytes = fileSize
                
                let fileHandle = try FileHandle(forReadingFrom: source)
                
                transferProgress = .file(progress: 0, numberOfBytes: numberOfBytes, speed: 0)
                state = .started(transferProgress)
                progressHandler(state)
                
                try await treeAccessor.upload(fileHandle: fileHandle, path: destination) { (progress) in
                    let elapsed = Date().timeIntervalSince(startTime!)
                    let currentSpeed = elapsed > 0 ? Double(fileSize) * progress / elapsed : 0
                    maxSpeed = max(maxSpeed, currentSpeed)
                    
                    transferProgress = .file(progress: progress, numberOfBytes: numberOfBytes, speed: currentSpeed)
                    state = .started(transferProgress)
                    progressHandler(state)
                }
            }
            
            endTime = Date()
            let summary = calculateSummary(fileSize: isDirectory.boolValue ? 0 : try fileManager.attributesOfItem(atPath: source.path)[.size] as! Int64)
            showSummaryDialog(summary)
            
            switch transferProgress {
            case .file(progress: _, numberOfBytes: let numberOfBytes, speed: _):
                state = .completed(.file(progress: 1, numberOfBytes: numberOfBytes, speed: maxSpeed))
            case .directory(completedFiles: let completedFiles, fileBeingTransferred: _, bytesSent: let bytesSent):
                state = .completed(.directory(completedFiles: completedFiles, fileBeingTransferred: nil, bytesSent: bytesSent))
            }
            progressHandler(state)
            
            await MainActor.run {
                NotificationCenter.default.post(
                    name: Self.didFinish,
                    object: self,
                    userInfo: [
                        FileUploadUserInfoKey.share: treeAccessor.share,
                        FileUploadUserInfoKey.path: destination,
                    ]
                )
            }
        } catch {
            state = .failed(error)
            progressHandler(state)
        }
    }
    
    private func showSummaryDialog(_ summary: TransferSummary) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Upload Complete"
            alert.informativeText = "File Size: \(ByteCountFormatter.string(fromByteCount: summary.fileSize, countStyle: .file))\n" +
            "Time Taken: \(String(format: "%.2f", summary.timeTaken)) sec\n" +
            "Average Speed: \(ByteCountFormatter.string(fromByteCount: Int64(summary.averageSpeed), countStyle: .file))/s\n" +
            "Max Speed: \(ByteCountFormatter.string(fromByteCount: Int64(summary.maxSpeed), countStyle: .file))/s"
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

struct FileUploadUserInfoKey: Hashable, Equatable, RawRepresentable {
    let rawValue: String
    
    init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension FileUploadUserInfoKey {
    static let share = FileUploadUserInfoKey(rawValue: "share")
    static let path = FileUploadUserInfoKey(rawValue: "path")
}

class FileDownload: FileTransfer {
    static let didFinish = Notification.Name("FileDownloadDidFinish")
    
    let displayName: String
    var state: TransferState
    var progressHandler: (_ state: TransferState) -> Void
    var startTime: Date?
    var endTime: Date?
    var maxSpeed: Double = 0
    
    let id: UUID
    private let source: String  // Remote file path
    private let destination: URL // Local destination path
    private let treeAccessor: TreeAccessor
    
    init(source: String, destination: URL, accessor: TreeAccessor) {
        id = UUID()
        self.source = source
        self.destination = destination
        self.treeAccessor = accessor
        self.displayName = (source as NSString).lastPathComponent
        self.state = .queued
        self.progressHandler = { _ in }
    }
    
    func start() async {
        startTime = Date()
        state = .started(.file(progress: 0.0, numberOfBytes: 0, speed: 0))
        progressHandler(state)
        
        do {
            let data = try await treeAccessor.download(path: source)
            let fileSize = Int64(data.count)
            let timeTaken = Date().timeIntervalSince(startTime!)
            let avgSpeed = fileSize > 0 ? Double(fileSize) / timeTaken : 0
            maxSpeed = max(maxSpeed, avgSpeed)
            
            try data.write(to: destination)
            endTime = Date()
            
            let summary = calculateSummary(fileSize: fileSize)
            showSummaryDialog(summary)
            
            state = .completed(.file(progress: 1.0, numberOfBytes: fileSize, speed: avgSpeed))
            NotificationCenter.default.post(name: FileDownload.didFinish, object: self)
        } catch {
            state = .failed(error)
        }
        
        progressHandler(state)
    }
    
    private func showSummaryDialog(_ summary: TransferSummary) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Download Complete"
            alert.informativeText = "File Size: \(ByteCountFormatter.string(fromByteCount: summary.fileSize, countStyle: .file))\n" +
            "Time Taken: \(String(format: "%.2f", summary.timeTaken)) sec\n" +
            "Average Speed: \(ByteCountFormatter.string(fromByteCount: Int64(summary.averageSpeed), countStyle: .file))/s\n" +
            "Max Speed: \(ByteCountFormatter.string(fromByteCount: Int64(summary.maxSpeed), countStyle: .file))/s"
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

struct TransferSummary {
    let fileSize: Int64
    let timeTaken: TimeInterval
    let averageSpeed: Double
    let maxSpeed: Double
}
