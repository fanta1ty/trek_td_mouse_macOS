import Foundation
import CoreBluetooth

extension BLEManager {
    func startFileTransfer() async throws {
        guard let peripheral = connectedPeripheral else {
            throw BLEError.notConnected
        }
        
        // Reset transfer state
        fileTransferInfo = FileTransferInfo(
            fileName: "",
            fileSize: 0,
            totalChunks: 0,
            currentChunk: 0,
            fileData: Data()
        )
        transferProgress = 0.0
        transferCompleted = false
        transferError = nil
        isTransferring = true
        
        // Send start transfer command
        let startCommand = Data([FileCommand.startTransfer.rawValue, 0])
        try await writeCharacteristic(uuid: FileTransferUUIDs.fileControl, data: startCommand)
        
        // Read file info
        let fileInfo = try await readCharacteristic(uuid: FileTransferUUIDs.fileInfo)
        parseFileInfo(fileInfo)
        
        print("Starting file transfer: \(fileTransferInfo.fileName), \(fileTransferInfo.fileSize) bytes")
        
        // Start requesting chunks
        await requestNextChunk()
    }
    
    private func parseFileInfo(_ data: Data) {
        guard data.count >= 5 else { return }
        
        let nameLength = Int(data[0])
        guard data.count >= nameLength + 5 else { return }
        
        let nameData = data.subdata(in: 1..<(nameLength + 1))
        fileTransferInfo.fileName = String(data: nameData, encoding: .utf8) ?? "unknown_file"
        
        let sizeBytes = data.subdata(in: (nameLength + 1)..<(nameLength + 5))
        fileTransferInfo.fileSize = Int(sizeBytes.withUnsafeBytes { $0.load(as: UInt32.self) })
        fileTransferInfo.totalChunks = (fileTransferInfo.fileSize + 19) / 20 // Chunk size is 20 bytes
        
        print("File info parsed: \(fileTransferInfo.fileName), \(fileTransferInfo.fileSize) bytes, \(fileTransferInfo.totalChunks) chunks")
    }
    
    func requestNextChunk() async {
        guard isTransferring else { return }
        
        guard fileTransferInfo.currentChunk < fileTransferInfo.totalChunks else {
            // Transfer complete
            await completeTransfer()
            return
        }
        
        do {
            let requestCommand = Data([FileCommand.requestChunk.rawValue, UInt8(fileTransferInfo.currentChunk)])
            try await writeCharacteristic(uuid: FileTransferUUIDs.fileControl, data: requestCommand)
            
            // Small delay to allow device to prepare data
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Read chunk data
            let chunkData = try await readCharacteristic(uuid: FileTransferUUIDs.fileData)
            processChunk(chunkData)
            
            // Send acknowledgment
            let ackData = Data([0x00, UInt8(fileTransferInfo.currentChunk)])
            try await writeCharacteristic(uuid: FileTransferUUIDs.fileAck, data: ackData)
            
            // Increment chunk counter
            fileTransferInfo.currentChunk += 1
            
            // Update progress
            let progress = Float(fileTransferInfo.currentChunk) / Float(fileTransferInfo.totalChunks)
            updateTransferProgress(progress)
            
            // Small delay before requesting next chunk
            try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
            
            // Request next chunk
            await requestNextChunk()
        } catch {
            print("Error requesting chunk \(fileTransferInfo.currentChunk): \(error)")
            transferError = error
            isTransferring = false
        }
    }
    
    private func processChunk(_ data: Data) {
        // Calculate chunk offset
        let chunkSize = 20 // Standard chunk size
        let expectedOffset = fileTransferInfo.currentChunk * chunkSize
        
        // Extend fileData if needed
        if fileTransferInfo.fileData.count < expectedOffset + data.count {
            let paddingNeeded = expectedOffset + data.count - fileTransferInfo.fileData.count
            fileTransferInfo.fileData.append(Data(repeating: 0, count: paddingNeeded))
        }
        
        // Insert data at correct position
        data.enumerated().forEach { (i, byte) in
            let pos = expectedOffset + i
            if pos < fileTransferInfo.fileData.count {
                fileTransferInfo.fileData[pos] = byte
            }
        }
        
        print("Processed chunk \(fileTransferInfo.currentChunk), Total data: \(fileTransferInfo.fileData.count) bytes")
    }
    
    private func completeTransfer() async {
        print("File transfer completed")
        
        // Trim data to exact file size if needed
        let trimmedData: Data
        if fileTransferInfo.fileData.count > fileTransferInfo.fileSize {
            trimmedData = fileTransferInfo.fileData.prefix(fileTransferInfo.fileSize)
        } else {
            trimmedData = fileTransferInfo.fileData
        }
        
        // Save file to local storage
        do {
            let savedURL = try saveFileToLocalStorage(trimmedData, fileName: fileTransferInfo.fileName)
            
            DispatchQueue.main.async {
                self.isTransferring = false
                self.transferCompleted = true
                self.savedFileURL = savedURL
                self.transferProgress = 1.0
                
                // Notify completion
                NotificationCenter.default.post(
                    name: NSNotification.Name("FileTransferCompleted"),
                    object: nil,
                    userInfo: ["fileURL": savedURL, "fileName": self.fileTransferInfo.fileName]
                )
            }
        } catch {
            print("Error saving file: \(error)")
            DispatchQueue.main.async {
                self.isTransferring = false
                self.transferError = error
            }
        }
    }
    
    private func saveFileToLocalStorage(_ data: Data, fileName: String) throws -> URL {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "FileManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot access documents directory"])
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Create directory if needed
        let directory = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Write file
        try data.write(to: fileURL)
        print("File saved to: \(fileURL.path)")
        
        return fileURL
    }
    
    private func updateTransferProgress(_ progress: Float) {
        DispatchQueue.main.async {
            self.transferProgress = progress
        }
    }
}
