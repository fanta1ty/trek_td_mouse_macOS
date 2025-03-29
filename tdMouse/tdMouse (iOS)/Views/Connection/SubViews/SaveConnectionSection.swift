//
//  SaveConnectionSection.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI

struct SaveConnectionSection: View {
    @Binding var connectionName: String
    @Binding var shouldSave: Bool
    
    var body: some View {
        Section(header: Text("Save Connection")) {
            Toggle("Save connection for future use", isOn: $shouldSave)
            
            if shouldSave {
                TextField("Connection Name", text: $connectionName)
                    .autocapitalization(.words)
                
                Text("Note: Password will not be saved")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SaveConnectionSection_Previews: PreviewProvider {
    static var previews: some View {
        SaveConnectionSection(
            connectionName: .constant("111.111.111.111"),
            shouldSave: .constant(true)
        )
    }
}
