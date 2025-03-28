//
//  ConnectionPlaceholder.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 28/3/25.
//

import SwiftUI

struct ConnectionPlaceholder: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "network.slash")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            Text("Not Connected to SMB Server")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Connect to a server to browse and transfer files")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                NotificationCenter.default.post(name: Notification.Name("OpenSMBConnect"), object: nil)
            }) {
                Label("Connect to Server", systemImage: "link")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
