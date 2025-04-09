//
//  TransferSummaryDetailView.swift
//  tdMouse
//
//  Created by mobile on 7/4/25.
//

import SwiftUI

struct TransferSummaryDetailView: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundStyle(.blue)
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
                
                //.fontWeight(.medium)
        }
    }
}

struct TransferSummaryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TransferSummaryDetailView(
            icon: "doc.fill",
            label: "Folders",
            value: "Value"
        )
    }
}
