
// BLEError.swift
enum BLEError: Error {
    case notConnected
    case characteristicNotFound
    case serviceNotFound
    case readFailed
    case writeFailed
    case notificationFailed
    case fileTransferFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .notConnected:
            return "BLE device not connected"
        case .characteristicNotFound:
            return "BLE characteristic not found"
        case .serviceNotFound:
            return "BLE service not found"
        case .readFailed:
            return "Failed to read from characteristic"
        case .writeFailed:
            return "Failed to write to characteristic"
        case .notificationFailed:
            return "Failed to setup notifications"
        case .fileTransferFailed(let reason):
            return "File transfer failed: \(reason)"
        }
    }
}
