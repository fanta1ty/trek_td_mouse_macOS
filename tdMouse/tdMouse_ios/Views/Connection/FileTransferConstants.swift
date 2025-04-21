// FileTransferConstants.swift
import Foundation

// File Transfer Command Codes
enum FileCommand: UInt8 {
    case startTransfer = 0x01
    case abortTransfer = 0x02
    case continueTransfer = 0x03
    case requestChunk = 0x06
    case chunkReceived = 0x07
    case complete = 0x08
}

// UUIDs for File Transfer Characteristics
struct FileTransferUUIDs {
    static let fileControl = "0000ffe6-0000-1000-8000-00805f9b34fb"
    static let fileInfo = "0000ffe7-0000-1000-8000-00805f9b34fb"
    static let fileData = "0000ffe8-0000-1000-8000-00805f9b34fb"
    static let fileAck = "0000ffe9-0000-1000-8000-00805f9b34fb"
    static let fileError = "0000ffea-0000-1000-8000-00805f9b34fb"
}

struct FileTransferInfo {
    var fileName: String
    var fileSize: Int
    var totalChunks: Int
    var currentChunk: Int
    var fileData: Data
}
