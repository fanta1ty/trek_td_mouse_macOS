//
//  SharesSelectorView.swift
//  tdMouse
//
//  Created by mobile on 30/3/25.
//

import SwiftUI
import SMBClient

struct SharesSelectorView: View {
    @EnvironmentObject var smbViewModel: FileTransferViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedShare: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                if smbViewModel.availableShares.isEmpty {
                    // No shares available
                    VStack(spacing: 20) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No shares available")
                            .font(.headline)
                        
                        Text("The server doesn't have any accessible shares")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // List available shares
                    List {
                        Section(header: Text("Available Shares")) {
                            ForEach(smbViewModel.availableShares, id: \.self) { share in
                                Button(action: {
                                    selectedShare = share
                                    connectToShare(share)
                                }) {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.blue)
                                        
                                        Text(share)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Select Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Disconnect and dismiss
                        Task {
                            try? await smbViewModel.disconnect()
                        }
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func connectToShare(_ share: String) {
        Task {
            do {
                try await smbViewModel.connectToShare(share)
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("ShareSelectedDismissConnection"), object: nil)
                    dismiss()
                }
            } catch {
                print("Error connecting to share: \(error)")
            }
        }
    }
}
