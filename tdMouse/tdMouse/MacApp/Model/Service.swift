//
//  Service.swift
//  tdMouse
//
//  Created by mobile on 2/3/25.
//

import Foundation

struct Service {
    let id: ID
    let name: String
    let type: String
    let domain: String

    init(
        name: String,
        type: String,
        domain: String
    ) {
        id = ID("smb://\(name).\(type).\(domain)")
        self.name = name
        self.type = type
        self.domain = domain
    }
}

extension Service: Hashable {
    static func == (lhs: Service, rhs: Service) -> Bool {
        lhs.name == rhs.name &&
        lhs.type == rhs.type &&
        lhs.domain == rhs.domain
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(domain)
    }
}
