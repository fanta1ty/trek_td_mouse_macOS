//
//  LocalPathIndicatorView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import SwiftUI

struct LocalPathIndicatorView: View {
    @EnvironmentObject private var viewModel: LocalViewModel
    
    var body: some View {
        HStack {
            Text(viewModel.currentDirectory?.lastPathComponent ?? "")
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(4)
            
            Spacer()
        }
    }
}

struct LocalPathIndicatorView_Previews: PreviewProvider {
    static var previews: some View  {
        LocalPathIndicatorView()
            .environmentObject(FileTransferViewModel())
            .environmentObject(LocalViewModel())
    }
}
