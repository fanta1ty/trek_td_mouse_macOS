//
//  SMBServerCredentials.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 12/3/25.
//

import Foundation

struct SMBServerCredentials: Codable, Equatable {
    var host: String
    var port: Int
    var username: String
    var password: String
    var domain: String
    
    init(
        host: String,
        port: Int = 445,
        username: String,
        password: String,
        domain: String = ""
    ) {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.domain = domain
    }
    
    static func == (lhs: SMBServerCredentials, rhs: SMBServerCredentials) -> Bool {
        return lhs.host == rhs.host &&
        lhs.port == rhs.port &&
        lhs.username == rhs.username &&
        lhs.password == rhs.password &&
        lhs.domain == rhs.domain
    }
    
    // Sample credentials for testing
    static let sample = SMBServerCredentials(
        host: "10.211.55.4",
        port: 445,
        username: "sambauser",
        password: "123456"
    )
    
    static let sample2 = SMBServerCredentials(
        host: "192.168.1.200",
        port: 445,
        username: "admin",
        password: "password"
    )
}
