//
//  TransferOperation.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

enum TransferOperation: Equatable {
    case none
    case downloading(String)
    case uploading(String)
    case listing(String)
    
    static func == (lhs: TransferOperation, rhs: TransferOperation) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.listing(let lhsPath), .listing(let rhsPath)):
            return lhsPath == rhsPath
        case (.downloading(let lhsFile), .downloading(let rhsFile)):
            return lhsFile == rhsFile
        case (.uploading(let lhsFile), .uploading(let rhsFile)):
            return lhsFile == rhsFile
        default:
            return false
        }
    }
}
