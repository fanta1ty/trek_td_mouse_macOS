//
//  URL+Ext.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 4/3/25.
//

import Foundation

extension URL {
    var pathname: String {
        if #available(macOS 13.0, *) {
            return path(percentEncoded: false)
        } else {
            return path
        }
    }
}
