//
//  StatusBarView.swift
//  tdMouse
//
//  Created by mobile on 15/3/25.
//

import SwiftUI

struct StatusBarView: View {
    @ObservedObject var smbViewModel: FileTransferViewModel
    @ObservedObject var localViewModel: LocalFileViewModel
    let activeTransfer: TransferDirection?
    
    var body: some View {
        HStack {
            if let activeTransfer = activeTransfer {
                transferStatusView(activeTransfer)
            } else {
                connectionStatusView()
            }
            
            Spacer()
            
            let smbItemCount = smbViewModel.files.count
            let localItemCount = localViewModel.files.count
            
            Text("\(smbItemCount) items on server • \(localItemCount) local items")
                .font(.caption)
        }
        .padding(8)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private func transferStatusView(_ transferDirection: TransferDirection) -> some View {
        HStack {
            switch transferDirection {
            case .toLocal:
                Image(systemName: "arrow.down")
                    .foregroundColor(.blue)
                Text("Downloading to local")
            case .toRemote:
                Image(systemName: "arrow.up")
                    .foregroundColor(.blue)
                Text("Uploading to SMB")
            }
            
            if smbViewModel.transferState != .none {
                Spacer()
                ProgressView(value: smbViewModel.transferProgress)
                    .frame(width: 100)
                Text("\(Int(smbViewModel.transferProgress * 100))%")
                    .monospacedDigit()
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }
    
    @ViewBuilder
    private func connectionStatusView() -> some View {
        HStack {
            if smbViewModel.connectionState == .connected {
                Image(systemName: "circle.fill")
                    .foregroundColor(.green)
                    .frame(width: 10, height: 10)
                Text("Connected to \(smbViewModel.credentials.host)")
            } else {
                Image(systemName: "circle.fill")
                    .foregroundColor(.red)
                    .frame(width: 10, height: 10)
                Text("Disconnected")
            }
        }
    }
}

struct StatusBarView_Preview: PreviewProvider {
    static var previews: some View {
        StatusBarView(
            smbViewModel: FileTransferViewModel(),
            localViewModel: LocalFileViewModel(),
            activeTransfer: .toLocal
        )
    }
}
