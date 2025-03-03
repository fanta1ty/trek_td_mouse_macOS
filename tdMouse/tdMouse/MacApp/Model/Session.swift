//
//  Session.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 3/3/25.
//

import SMBClient
import Cocoa

struct Session {
    let id: ID
    let displayName: String?
    let server: String
    let port: Int?
    let client: SMBClient
}
