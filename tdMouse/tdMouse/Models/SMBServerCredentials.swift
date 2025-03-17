//
//  SMBServerCredentials.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 12/3/25.
//

import Foundation

struct SMBServerCredentials: Identifiable, Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case id,
             host,
             port,
             username,
             password,
             domain,
             displayName
    }
    
    let id: UUID
    var host: String
    var port: Int
    var username: String
    var password: String
    var domain: String
    var displayName: String
    
    init(
        id: UUID = UUID(),
        host: String,
        port: Int = 445,
        username: String,
        password: String,
        domain: String = "WORKGROUP",
        displayName: String? = nil
    ) {
        self.id = id
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.domain = domain
        self.displayName = displayName ?? "\(username)@\(host)"
    }
    
    func withUpdatedPassword(_ newPassword: String) -> SMBServerCredentials {
        SMBServerCredentials(
            id: self.id,
            host: self.host,
            port: self.port,
            username: self.username,
            password: newPassword,
            domain: self.domain,
            displayName: self.displayName
        )
    }
    
    var connectionString: String {
        "\(username)@\(host):\(port)"
    }
    
    var serverAddress: String {
        "\(host):\(port)"
    }
    
    static func == (lhs: SMBServerCredentials, rhs: SMBServerCredentials) -> Bool {
        lhs.id == rhs.id &&
        lhs.host == rhs.host &&
        lhs.port == rhs.port &&
        lhs.username == rhs.username &&
        lhs.domain == rhs.domain
    }
}

extension SMBServerCredentials {
    /// Creates credentials with only the essential information
    static func createWithBasicInfo(
        host: String,
        username: String,
        password: String
    ) -> SMBServerCredentials {
        SMBServerCredentials(
            host: host,
            username: username,
            password: password
        )
    }
    
    static var sample: SMBServerCredentials {
        SMBServerCredentials(
            host: "192.168.50.24",
            username: "sambauser",
            password: "123456",
            domain: "share"
        )
    }
    
    static var sample2: SMBServerCredentials {
        SMBServerCredentials(
            host: "10.211.55.5",
            username: "sambauser",
            password: "123456",
            domain: "share"
        )
    }
    
    static var empty: SMBServerCredentials {
        SMBServerCredentials(
            host: "",
            username: "",
            password: "",
            domain: "WORKGROUP"
        )
    }
}
