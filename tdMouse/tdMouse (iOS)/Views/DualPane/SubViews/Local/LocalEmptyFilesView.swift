//
//  LocalEmptyFilesView.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI

struct LocalEmptyFilesView: View {
    let message: String
    let description: String
    
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "doc.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(message)
                .font(.headline)
            Text(description)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct LocalFileEmptyFilesView_Previews: PreviewProvider {
    static var previews: some View {
        LocalEmptyFilesView(
            message: "message",
            description: "description"
        )
    }
}
