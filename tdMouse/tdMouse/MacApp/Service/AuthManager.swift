//
//  AuthManager.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 3/3/25.
//

protocol AuthManager {
    func authenticate() -> Session?
}
