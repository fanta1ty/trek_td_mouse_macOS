//
//  SharesSection.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI

struct SharesSection: View {
    let shares: [String]
    @Binding var selectedShare: String
    
    var body: some View {
        Section(header: Text("Available Shares")) {
            if shares.isEmpty {
                Text("No shares available")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Picker("Share", selection: $selectedShare) {
                    ForEach(shares, id: \.self) { share in
                        Text(share).tag(share)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
}

struct SharesSection_Previews: PreviewProvider {
    static var previews: some View {
        SharesSection(
            shares: [],
            selectedShare: .constant("")
        )
    }
}
