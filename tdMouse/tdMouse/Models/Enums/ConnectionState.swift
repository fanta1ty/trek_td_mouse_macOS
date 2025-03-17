//
//  ConnectionState.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 12/3/25.
//

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}
