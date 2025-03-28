//
//  PreferencesManager.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import Foundation
import SwiftUI

class PreferencesManager: ObservableObject {
    static let shared = PreferencesManager()
    
    @AppStorage("isFirstLaunch") var isFirstLaunch = true
    @AppStorage("recentConnections") var recentConnectionsData: Data?
    
    var recentConnections: [SMBServerCredentials] {
        get {
            guard let data = recentConnectionsData else { return [] }
            return (try? JSONDecoder().decode([SMBServerCredentials].self, from: data)) ?? []
        }
        set {
            recentConnectionsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    func addRecentConnection(_ credentials: SMBServerCredentials) {
        var connections = recentConnections
      
        connections.removeAll(where: { $0.host == credentials.host && $0.domain == credentials.domain })

        connections.insert(credentials, at: 0)
      
        if connections.count > 10 {
            connections = Array(connections.prefix(10))
        }
        recentConnections = connections
    }
}
