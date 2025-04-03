//
//  ShareSelectionView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 31/3/25.
//

import SwiftUI
import SMBClient

struct ShareSelectionView: View {
    @EnvironmentObject var viewModel: FileTransferViewModel
    @Binding var selectedShare: String
    
    let onConnectToSelectedShare: () -> Void
    
    var body: some View {
        VStack {
            if viewModel.availableShares.isEmpty {
                // Loading or no shares available
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Loading available shares...")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                // Display list of shares
                List(viewModel.availableShares, id: \.self) { share in
                    Button {
                        selectedShare = share
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                                .imageScale(.large)
                            
                            Text(share)
                                .font(.system(size: 16))
                            
                            Spacer()
                            
                            if selectedShare == share {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Quick action to connect to selected share
                if !selectedShare.isEmpty {
                    Button(action: {
                        onConnectToSelectedShare()
                    }) {
                        Text("Connect to \(selectedShare)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                }
            }
        }
    }
}



struct ShareSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ShareSelectionView(
            selectedShare: .constant(""),
            onConnectToSelectedShare: {}
        )
        .environmentObject(FileTransferViewModel())
        .environmentObject(LocalViewModel())
    }
}
