//
//  TransferSummaryView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 14/3/25.
//

import SwiftUI

struct TransferSummaryView: View {
    @Binding var isPresented: Bool
    let stats: TransferStats
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack {
                Image(systemName: stats.transferType == .download ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)
                
                Text("\(stats.transferType == .download ? "Download" : "Upload") Complete")
                    .font(.headline)
                
                Text(stats.fileName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical)
            
            // Stats grid
            VStack(spacing: 16) {
                statRow(
                    label: "File Size",
                    value: Helpers.formatFileSize(stats.fileSize)
                )
                
                statRow(
                    label: "Time Taken",
                    value: formatDuration(stats.duration)
                )
                
                statRow(label: "Average Speed", value: formatSpeed(stats.averageSpeed))
                statRow(label: "Maximum Speed", value: formatSpeed(stats.maxSpeed))
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Speed chart
            if !stats.speedSamples.isEmpty {
                SpeedChartView(speedSamples: stats.speedSamples)
                    .frame(height: 100)
                    .padding(.horizontal)
            }
            
            // Close button
            Button("Close") {
                isPresented = false
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top)
        }
        .padding()
        .frame(width: 400)
    }
    
    private func statRow(
        label: String,
        value: String
    ) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .bold()
                .multilineTextAlignment(.trailing)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 1 {
            return String(format: "%.2f seconds", duration)
        } else if duration < 60 {
            return String(format: "%.1f seconds", duration)
        } else {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(minutes)m \(seconds)s"
        }
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }
}

struct TransferSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        TransferSummaryView(
            isPresented: .constant(true),
            stats: TransferStats(
                fileSize: 100,
                fileName: "Test",
                startTime: Date.now,
                endTime: Date.now,
                transferType: .download,
                speedSamples: [
                    50_000, 75_000, 100_000, 95_000, 85_000,
                    90_000, 100_000, 110_000, 105_000, 95_000
                ])
        )
    }
}
