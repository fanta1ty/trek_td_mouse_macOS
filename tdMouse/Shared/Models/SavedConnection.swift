//
//  SavedConnection.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import Foundation

struct SavedConnection: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var host: String
    var port: UInt16
    var username: String
    var domain: String
    
    var displayName: String {
        return name.isEmpty ? host : name
    }
    
    static func == (lhs: SavedConnection, rhs: SavedConnection) -> Bool {
        return lhs.id == rhs.id
    }
}
