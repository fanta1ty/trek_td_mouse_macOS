//
//  SavedConnectionsSection.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI

struct SavedConnectionsSection: View {
    let savedConnectionsData: Data
    let savedConnections: [SavedConnection]
    let onLoadConnection: (SavedConnection) -> Void
    let onDeleteConnection: (IndexSet) -> Void
    
    var body: some View {
        if !savedConnections.isEmpty {
            Section(header: Text("Saved Connections")) {
                ForEach(savedConnections, id: \.id) { connection in
                    Button(action: {
                        onLoadConnection(connection)
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(connection.name)
                                    .fontWeight(.medium)
                                Text("\(connection.username)@\(connection.host)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.forward.circle")
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .onDelete(perform: onDeleteConnection)
            }
        }
    }
}

struct SavedConnectionsSection_Previews: PreviewProvider {
    static var previews: some View {
        SavedConnectionsSection(
            savedConnectionsData: Data(),
            savedConnections: [],
            onLoadConnection: { _ in },
            onDeleteConnection: { _ in }
        )
    }
}
