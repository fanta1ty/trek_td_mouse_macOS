//
//  FilePreparingPreviewView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 2/4/25.
//

import SwiftUI

struct FilePreparingPreviewView: View {
    @Binding var showPreviewSheet: Bool
    
    var body: some View {
        VStack(alignment: .trailing) {
            Button {
                showPreviewSheet = false
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.primary)
                    .padding(10)
            }
            .padding([.top, .trailing], 16)
            
            VStack(alignment: .center) {
                ProgressView()
                    .padding(.bottom, 8)
                Text("Preparing preview... Please try again later.")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct FIlePreparingPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        FilePreparingPreviewView(
            showPreviewSheet: .constant(true)
        )
        .environmentObject(FileTransferViewModel())
    }
}
