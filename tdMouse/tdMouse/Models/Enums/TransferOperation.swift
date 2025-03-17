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
}
