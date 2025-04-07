//
//  TransferSummaryView.swift
//  tdMouse
//
//  Created by mobile on 7/4/25.
//

import SwiftUI

struct TransferSummaryView: View {
    let summary: TransferSummary
    
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: summary.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(summary.isSuccess ? .green : .red)
                
                Text(summary.isSuccess ? "Transfer Complete" : "Transfer Failed")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.top)
            
            Divider()
            
            // Transfer Details
            VStack(alignment: .leading, spacing: 12) {
                TransferSummaryDetailView(
                    icon: summary.type == .upload ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                    label: "Transfer Type",
                    value: summary.type == .upload ? "Upload" : "Download"
                )
                
                if summary.fileCount > 0 {
                    TransferSummaryDetailView(
                        icon: "doc.fill",
                        label: "Files",
                        value: "\(summary.fileCount)"
                    )
                }
                
                TransferSummaryDetailView(
                    icon: "internaldrive.fill",
                    label: "Total Size",
                    value: Helpers.formatFileSize(summary.totalBytes)
                )
                
                TransferSummaryDetailView(
                    icon: "clock.fill",
                    label: "Duration",
                    value: Helpers.formatDuration(summary.duration)
                )
                
                TransferSummaryDetailView(
                    icon: "speedometer",
                    label: "Average Speed",
                    value: Helpers.formatSpeed( Double(summary.totalBytes)
                    )
                )
                
                TransferSummaryDetailView(
                    icon: "arrow.up.forward",
                    label: "Peak Speed",
                    value: Helpers.formatSpeed(summary.peakSpeed)
                )
                
                if summary.minSpeed > 0 {
                    TransferSummaryDetailView(
                        icon: "arrow.down.forward",
                        label: "Minimum Speed",
                        value: Helpers.formatSpeed(summary.minSpeed)
                    )
                }
                
                if !summary.speedSamples.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transfer Speed")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        TransferSummarySpeedChartView(samples: summary.speedSamples)
                            .frame(height: 70)
                            .padding(.vertical, 4)
                    }
                }
                
                if !summary.isSuccess, let errorMessage = summary.errorMessage {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Error:")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                isPresented = false
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(maxWidth: 350, maxHeight: 500)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

struct TransferSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        TransferSummaryView(
            summary: .init(
                type: .download,
                fileCount: 10,
                directoryCount: 20,
                totalBytes: 1024 * 1024 * 15,
                startTime: Date.init().addingTimeInterval(-65),
                endDate: Date.init(),
                isSuccess: true,
                errorMessage: "Error Message",
                speedSamples: [
                    256 * 1024,
                    512 * 1024,
                    650 * 1024,
                    325 * 1024,
                    420 * 1024
                ]),
            isPresented: .constant(true)
        )
    }
}
