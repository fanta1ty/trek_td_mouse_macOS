//
//  LocalPane.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import SwiftUI

struct LocalPane: View {
    @EnvironmentObject private var viewModel: LocalViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            LocalPaneHeaderView()
            .padding(.vertical, 4)
            
            // Path indicator
            LocalPathIndicatorView()
            .padding(.bottom, 4)
        }
    }
}

struct LocalPane_Previews: PreviewProvider {
    static var previews: some View {
        LocalPane()
            .environmentObject(LocalViewModel())
    }
}
