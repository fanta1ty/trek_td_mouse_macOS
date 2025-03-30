//
//  TransferTask.swift
//  tdMouse
//
//  Created by mobile on 22/3/25.
//
import Foundation

class TransferTask {
    let id: UUID
    let startTime: Date
    let transferDirection: TransferDirection
    let remotePath: String
    let localPath: URL
    private(set) var isCompleted: Bool = false
    private(set) var isCancelled: Bool = false
    private(set) var error: Error?
    private var task: Task<Void, Error>?
    
    init(
        id: UUID = UUID(),
        direction: TransferDirection,
        remotePath: String,
        localPath: URL
    ) {
        self.id = id
        self.startTime = Date()
        self.transferDirection = direction
        self.remotePath = remotePath
        self.localPath = localPath
    }
    
    func start(_ operation: @escaping () async throws -> Void) {
        task = Task { [weak self] in
            guard let self else { return }
            do {
                try await operation()
                await MainActor.run {
                    self.isCompleted = true
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isCompleted = true
                }
            }
        }
    }
    
    func cancel() {
        task?.cancel()
        isCancelled = true
    }
}
