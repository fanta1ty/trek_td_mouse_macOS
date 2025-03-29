//
//  LocalPathBarView.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI

struct LocalPathBarView: View {
    @ObservedObject var viewModel: LocalFileViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Text(viewModel.currentDirectoryURL.path)
                    .lineLimit(1)
                    .font(.caption)
                    .padding(.horizontal)
            }
            .frame(height: 30)
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
}

struct LocalPathBarView_Previews: PreviewProvider {
    static var previews: some View {
        LocalPathBarView(viewModel: LocalFileViewModel())
    }
}
