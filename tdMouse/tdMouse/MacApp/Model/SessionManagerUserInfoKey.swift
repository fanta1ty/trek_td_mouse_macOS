//
//  SessionManagerUserInfoKey.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 3/3/25.
//

import Cocoa

struct SessionManagerUserInfoKey: Hashable, Equatable, RawRepresentable {
  let rawValue: String

  init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension SessionManagerUserInfoKey {
  static let error = SessionManagerUserInfoKey(rawValue: "error")
}
