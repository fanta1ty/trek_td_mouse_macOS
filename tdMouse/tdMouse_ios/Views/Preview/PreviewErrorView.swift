//
//  PreviewErrorView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import SwiftUI

struct PreviewErrorView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
            
            Text("File Preview Unavailable")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Close")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 10)

        }
        .padding()
    }
}

struct PreviewErrorView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewErrorView(message: "Message")
            .environmentObject(FileTransferViewModel())
            .environmentObject(LocalViewModel())
    }
}
