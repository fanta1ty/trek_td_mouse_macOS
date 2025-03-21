//
//  TransferError.swift
//  tdMouse
//
//  Created by mobile on 21/3/25.
//

enum TransferError: Error {
    case folderDownloadFailed(folderName: String, underlyingError: Error)
    case folderUploadFailed(folderName: String, underlyingError: Error)
    case fileDownloadFailed(fileName: String, underlyingError: Error)
    case fileUploadFailed(fileName: String, underlyingError: Error)
    case navigationFailed(path: String, underlyingError: Error)
    case transferInProgress
    case invalidPath
    
}
