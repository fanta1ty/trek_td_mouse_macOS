//
//  SessionManager.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 3/3/25.
//

import Cocoa
import SMBClient

class SessionManager {
    static let shared = SessionManager()
    static let sessionDidDisconnected = Notification.Name("SessionManagerSessionDidDisconnected")
    
    private var sessions = [ID: Session]()
    
    private init() {}
}

// MARK: - Public Functions
extension SessionManager {
    func session(for id: ID) -> Session? {
        sessions[id]
    }
    
    func sessionExists(for id: ID) -> Bool {
        session(for: id) != nil
    }
    
    func login(
        id: ID,
        displayName: String?,
        server: String,
        port: Int? = nil,
        username: String,
        password: String,
        savePassword: Bool
    ) async throws -> Session {
        let client = ClientRegistry.shared.client(id: id, displayName: displayName, server: server, port: port) { [weak self] error in
            guard let self else { return }
            
            ClientRegistry.shared.removeClient(id: id)
            self.sessions[id] = nil
            
            Task {
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: Self.sessionDidDisconnected,
                        object: self,
                        userInfo: [SessionManagerUserInfoKey.error: error]
                    )
                }
            }
        }
        
        try await client.login(username: username, password: password)
        
        if savePassword {
            let store = CredentialStore.shared
            store.save(
                server: server,
                securityDomain: id.rawValue,
                username: username,
                password: password
            )
        }
        
        let session = Session(
            id: id,
            displayName: displayName,
            server: server,
            port: port,
            client: client
        )
        
        sessions[id] = session

        return session
    }
    
    func logoff(id: ID) async {
        do {
            let client = ClientRegistry.shared.client(id: id)
            try await client?.logoff()
            
            sessions[id] = nil
            ClientRegistry.shared.removeClient(id: id)
        } catch {
            _ = await MainActor.run {
                NSAlert(error: error).runModal()
            }
        }
    }
}
