//
//  TransferSummaryView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 14/3/25.
//

import SwiftUI

/// View to show transfer statistics after completion
struct TransferSummaryView: View {
    let stats: TransferStats
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status icon
                    Image(systemName: stats.transferType == .download ? "arrow.down.circle" : "arrow.up.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text(stats.transferType == .download ? "Download Complete" : "Upload Complete")
                        .font(.headline)
                    
                    // Transfer details
                    VStack(alignment: .leading, spacing: 12) {
                        TransferDetailRow(label: "File", value: stats.fileName)
                        TransferDetailRow(label: "Size", value: stats.prettyFileSize)
                        TransferDetailRow(label: "Duration", value: stats.prettyDuration)
                        TransferDetailRow(label: "Speed", value: stats.prettySpeed)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Speed chart (if we have samples)
                    if !stats.speedSamples.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Transfer Speed")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            SpeedChartView(stats: stats)
                                .padding(.horizontal)
                                .frame(height: 200)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Transfer Summary")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

/// Helper view for displaying transfer details in rows
struct TransferDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .lineLimit(1)
            Spacer()
        }
    }
}
