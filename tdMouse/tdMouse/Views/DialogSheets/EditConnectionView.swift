//
//  EditConnectionView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI

struct EditConnectionView: View {
    @State private var editedConnection: SavedConnection
    @Binding var isPresented: Bool
    let onSave: (SavedConnection) -> Void
    
    init(
        connection: SavedConnection,
        isPresented: Binding<Bool>,
        onSave: @escaping (SavedConnection) -> Void
    ) {
        _editedConnection = State(initialValue: connection)
        _isPresented = isPresented
        self.onSave = onSave
    }
    
    var body: some View {
        VStack {
            Text("Edit Connection")
                .font(.headline)
                .padding()
            
            Form {
                TextField("Connection Name", text: $editedConnection.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Host", text: $editedConnection.host)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                HStack {
                    Text("Port:")
                    TextField("Port", value: $editedConnection.port, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                
                TextField("Username", text: $editedConnection.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Domain (optional)", text: $editedConnection.domain)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    onSave(editedConnection)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 400)
    }
}
