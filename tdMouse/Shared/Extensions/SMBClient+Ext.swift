//
//  SMBClient+Ext.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SMBClient
import SwiftUI

extension SMBClient {
    static var contentTypeIdentifier: String {
        "com.thinh.nguyen.smb.file"
    }
    
    static func makeDraggable(_ file: File) -> some View {
        return Text(file.name)
            .onDrag {
                let itemProvider = NSItemProvider()
                itemProvider.registerDataRepresentation(
                    forTypeIdentifier: contentTypeIdentifier,
                    visibility: .all) { completion in
                        let dictionary: [String: Any] = [
                            "name": file.name,
                            "isDirectory": file.isDirectory ? "true" : "false"
                        ]
                        
                        let data = try? JSONSerialization.data(withJSONObject: dictionary)
                        completion(data, nil)
                        return nil
                    }
                return itemProvider
            }
    }
}
