//
//  UnsupportedFileView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 17/3/25.
//

import SwiftUI

struct UnsupportedFileView: View {
    let fileExtension: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("File Preview Unavailable")
                .font(.title2)
            
            Text(".\(fileExtension) files cannot be previewed directly.")
                .foregroundColor(.secondary)
            
            Text("Try downloading the file to view it in a compatible application.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
