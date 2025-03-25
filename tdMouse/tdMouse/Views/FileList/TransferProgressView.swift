//
//  TransferProgressView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 13/3/25.
//

import SwiftUI

struct TransferProgressView: View {
    let transferState: TransferOperation
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                switch transferState {
                case .none:
                    EmptyView()
                    
                case .downloading(let fileName):
                    Image(systemName: "arrow.down")
                    Text("Downloading \(fileName)")
                    
                case .uploading(let fileName):
                    Image(systemName: "arrow.up")
                    Text("Uploading \(fileName)")
                    
                case .listing(let path):
                    Image(systemName: "list.bullet")
                    Text("Listing \(path)")
                }
                
                Spacer()
                
                if case .downloading = transferState, progress > 0 {
                    Text("\(Int(progress * 100))%")
                        .monospacedDigit()
                }
            }
            
            ProgressView(value: progress)
        }
        .padding()
        .background(Color(NSColor.separatorColor).opacity(0.1))
    }
}

struct TransferProgressView_Previews: PreviewProvider {
    static var previews: some View {
        TransferProgressView(
            transferState: .downloading("A.txt"),
            progress: 0.3
        )
    }
}
