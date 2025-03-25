//
//  PlaceholderView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI

struct DisconnectedPlaceholderView: View {
    let connectAction: () -> Void
    
    var body: some View {
        VStack {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Select a server to connect")
                .font(.title2)
                .padding()
            Button("Connect to Server") {
                connectAction()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DisconnectedPlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        DisconnectedPlaceholderView {
            print("Connect button tapped")
        }
    }
}
