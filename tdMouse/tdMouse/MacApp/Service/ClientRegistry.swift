//
//  ClientRegistry.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 3/3/25.
//

import Cocoa
import SMBClient

class ClientRegistry {
    static let shared = ClientRegistry()
    
    private var clients = [ID: SMBClient]()
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate(_:)),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }
}

// MARK: - Action Functions
extension ClientRegistry {
    @objc private func applicationWillTerminate(_ notification: Notification) {
        for client in clients.values {
            Task {
                try await client.logoff()
            }
        }
    }
}

// MARK: - Public Functions
extension ClientRegistry {
    func client(
        id: ID,
        displayName: String?,
        server: String,
        port: Int?,
        onDisconnected: @escaping (Error) -> Void
    ) -> SMBClient {
        if let client = clients[id] {
            return client
        }
        
        let client: SMBClient
        if let port {
            client = SMBClient(host: server, port: port)
        } else {
            client = SMBClient(host: server)
        }
        client.onDisconnected = onDisconnected
        
        clients[id] = client
        return client
    }
    
    func client(id: ID) -> SMBClient? {
        clients[id]
    }
    
    func removeClient(id: ID) {
        clients[id] = nil
    }
}
