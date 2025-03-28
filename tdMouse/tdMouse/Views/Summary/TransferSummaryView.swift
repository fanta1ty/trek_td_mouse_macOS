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
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateStats = false
    
    private var accentGradient: LinearGradient {
        stats.transferType == .download ?
        LinearGradient(
            gradient: Gradient(colors: [.blue, .cyan]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ) :
        LinearGradient(
            gradient: Gradient(colors: [.green, .mint]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with visual appeal
            headerSection
                .background(
                    accentGradient
                        .opacity(0.1)
                        .overlay(
                            colorScheme == .dark ?
                            Color.black.opacity(0.2) :
                            Color.white.opacity(0.4)
                        )
                )
            
            // Stats and chart
            ScrollView {
                VStack(spacing: 24) {
                    // Summary card
                    summaryCard
                    
                    // Detailed statistics
                    detailedStatsSection
                    
                    // Speed chart
                    speedChartSection
                }
                .padding(20)
            }
            
            // Footer with close button
            Button("Close") {
                isPresented = false
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                colorScheme == .dark ?
                Color(NSColor.windowBackgroundColor).opacity(0.8) :
                Color(NSColor.windowBackgroundColor)
            )
        }
        .frame(width: 450, height: 650)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    animateStats = true
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon with background circle
            ZStack {
                Circle()
                    .fill(stats.transferType == .download ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: stats.transferType == .download ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(stats.transferType == .download ? Color.blue : Color.green)
            }
            .padding(.top, 24)
            
            // Title
            Text("\(stats.transferType == .download ? "Download" : "Upload") Complete")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Filename with truncation handling
            Text(stats.fileName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
    }
    
    private var summaryCard: some View {
        HStack(spacing: 20) {
            // File size
            VStack {
                Image(systemName: "doc.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .padding(.bottom, 4)
                
                Text("Size")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(Helpers.formatFileSize(stats.fileSize))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            
            // Divider
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1, height: 40)
            
            // Duration
            VStack {
                Image(systemName: "clock.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                    .padding(.bottom, 4)
                
                Text("Duration")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatDuration(stats.duration))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            
            // Divider
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1, height: 40)
            
            // Speed
            VStack {
                Image(systemName: "speedometer")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
                    .padding(.bottom, 4)
                
                Text("Avg Speed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatSpeed(stats.averageSpeed))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Detailed Statistics")
                .font(.headline)
                .padding(.bottom, 4)
            
            VStack(spacing: 12) {
                // Time info
                Group {
                    enhancedStatRow(
                        icon: "calendar",
                        label: "Start Time",
                        value: formatDate(stats.startTime),
                        iconColor: .blue
                    )
                    
                    enhancedStatRow(
                        icon: "calendar.badge.clock",
                        label: "End Time",
                        value: formatDate(stats.endTime),
                        iconColor: .blue
                    )
                    
                    enhancedStatRow(
                        icon: "clock.arrow.2.circlepath",
                        label: "Duration",
                        value: formatDuration(stats.duration),
                        iconColor: .orange
                    )
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                // Speed info
                Group {
                    enhancedStatRow(
                        icon: "gauge.high",
                        label: "Average Speed",
                        value: formatSpeed(stats.averageSpeed),
                        iconColor: .green
                    )
                    
                    enhancedStatRow(
                        icon: "arrow.up.right.circle",
                        label: "Maximum Speed",
                        value: formatSpeed(stats.maxSpeed),
                        iconColor: .green
                    )
                    
                    if stats.duration > 0 {
                        enhancedStatRow(
                            icon: "percent",
                            label: "Efficiency",
                            value: String(format: "%.1f%%", min(stats.averageSpeed / stats.maxSpeed * 100, 100)),
                            iconColor: .purple
                        )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
    
    private var speedChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Speed Analysis")
                .font(.headline)
                .padding(.bottom, 4)
            
            if !stats.speedSamples.isEmpty {
                SpeedChartView(speedSamples: stats.speedSamples, maxSpeed: stats.maxSpeed * 1.1)
                    .frame(height: 150)
                    .padding(.top, 8)
            } else {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                            .opacity(0.5)
                        
                        Text("No speed data available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 120)
                    
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        .background(Color.secondary.opacity(0.05))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Views
    
    private func enhancedStatRow(
        icon: String,
        label: String,
        value: String,
        iconColor: Color
    ) -> some View {
        HStack(spacing: 12) {
            // Icon with background
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }
            
            // Label
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Value with animation
            Text(value)
                .fontWeight(.medium)
                .opacity(animateStats ? 1 : 0)
                .offset(x: animateStats ? 0 : 20)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 1 {
            return String(format: "%.2f seconds", duration)
        } else if duration < 60 {
            return String(format: "%.1f seconds", duration)
        } else if duration < 3600 {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            let hours = Int(duration) / 3600
            let minutes = (Int(duration) % 3600) / 60
            let seconds = Int(duration) % 60
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        }
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct TransferSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Download example
            TransferSummaryView(
                isPresented: .constant(true),
                stats: TransferStats(
                    fileSize: 1_546_788_234,
                    fileName: "project-backup-2024-03-27.zip",
                    startTime: Date().addingTimeInterval(-145),
                    endTime: Date(),
                    transferType: .download,
                    speedSamples: [
                        5_000_000, 7_500_000, 10_000_000, 9_500_000, 8_500_000,
                        9_000_000, 10_000_000, 11_000_000, 10_500_000, 9_500_000,
                        10_200_000, 10_800_000, 11_500_000, 12_000_000, 11_800_000,
                        12_500_000, 12_800_000, 13_000_000, 12_700_000, 12_200_000
                    ]
                )
            )
            .previewDisplayName("Download Summary (Light)")
            
            // Upload example
            TransferSummaryView(
                isPresented: .constant(true),
                stats: TransferStats(
                    fileSize: 85_456_982,
                    fileName: "Presentation_Final_Version.pptx",
                    startTime: Date().addingTimeInterval(-63),
                    endTime: Date(),
                    transferType: .upload,
                    speedSamples: [
                        2_000_000, 3_500_000, 4_800_000, 4_200_000, 3_800_000,
                        4_100_000, 4_600_000, 4_400_000, 3_900_000, 4_300_000
                    ]
                )
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Upload Summary (Dark)")
            
            // Small file example
            TransferSummaryView(
                isPresented: .constant(true),
                stats: TransferStats(
                    fileSize: 45_982,
                    fileName: "config.json",
                    startTime: Date().addingTimeInterval(-0.8),
                    endTime: Date(),
                    transferType: .download,
                    speedSamples: [
                        40_000, 45_000, 50_000
                    ]
                )
            )
            .previewDisplayName("Small File")
        }
    }
}
