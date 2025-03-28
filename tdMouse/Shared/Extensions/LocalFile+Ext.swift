//
//  LocalFile+Ext.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI
import UniformTypeIdentifiers

extension LocalFile {
    static var contentTypeIdentifier: String {
        "com.thinh.nguyen.local.file"
    }
    
    static func makeDraggable(_ file: LocalFile) -> some View {
        return Text(file.name)
            .onDrag {
                let itemProvider = NSItemProvider()
                
                if !file.isDirectory {
                    itemProvider.registerFileRepresentation(
                        forTypeIdentifier: UTType.item.identifier,
                        fileOptions: [],
                        visibility: .all) { completion in
                            completion(file.url, true, nil)
                            return nil
                        }
                } else {
                    // For directories, provide the name as plain text
                    itemProvider.registerObject(file.name as NSString, visibility: .all)
                }
                
                return itemProvider
            }
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "isDirectory": isDirectory,
            "size": size,
            "urlString": url.absoluteString
        ]
    }
}
