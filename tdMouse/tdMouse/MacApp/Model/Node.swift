//
//  Node.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 4/3/25.
//

import Foundation
import SMBClient

protocol Node {
    var id: ID { get }
    var name: String { get }
    var parent: ID? { get }
    
    var isRoot: Bool { get }
    
    func detach() -> Self
}

extension Node {
  var isRoot: Bool { parent == nil }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
