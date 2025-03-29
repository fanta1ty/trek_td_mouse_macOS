//
//  SpeedChartView.swift
//  tdMouse
//
//  Created by mobile on 29/3/25.
//

import SwiftUI
import Charts

struct SpeedChartView: View {
    let speedSamples: [Double]  // Changed to match TransferStats definition
    let startTime: Date
    let endTime: Date
    let maxSpeed: Double
    
    init(stats: TransferStats) {
        self.speedSamples = stats.speedSamples
        self.startTime = stats.startTime
        self.endTime = stats.endTime
        
        // Calculate max speed for y-axis scaling
        if speedSamples.isEmpty {
            self.maxSpeed = stats.averageSpeed * 1.5 // Use average as fallback
        } else {
            let samplesMax = speedSamples.max() ?? 0
            self.maxSpeed = samplesMax * 1.2 // Add 20% for headroom
        }
    }
    
    var body: some View {
        if #available(iOS 16.0, *) {
            // Use Swift Charts on iOS 16+
            modernChart
        } else {
            // Fallback for earlier iOS versions
            legacyChart
        }
    }
    
    // Modern chart using Swift Charts (iOS 16+)
    @available(iOS 16.0, *)
    private var modernChart: some View {
        Chart {
            ForEach(Array(speedSamples.enumerated()), id: \.offset) { index, speed in
                // Calculate timestamp for this sample
                let timePoint = calculateTimeForSample(index: index)
                
                LineMark(
                    x: .value("Time", timePoint),
                    y: .value("Speed", speed)
                )
                .foregroundStyle(Color.blue)
                .interpolationMethod(.monotone)
                
                AreaMark(
                    x: .value("Time", timePoint),
                    y: .value("Speed", speed)
                )
                .foregroundStyle(LinearGradient(
                    colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .interpolationMethod(.monotone)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let speed = value.as(Double.self) {
                        Text(formatSpeed(bytes: speed))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatTime(date: date))
                    }
                }
            }
        }
        .frame(height: 150)
    }
    
    // Legacy chart for iOS 15 and earlier
    private var legacyChart: some View {
        // Simple line representation using GeometryReader
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Grid lines
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<4) { i in
                        Divider()
                        Spacer()
                            .frame(height: geometry.size.height / 4 - 1)
                    }
                    Divider()
                }
                
                // Speed curve
                Path { path in
                    if speedSamples.isEmpty {
                        return
                    }
                    
                    // Scale to view size
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let xStep = width / CGFloat(speedSamples.count - 1)
                    let yScale = height / CGFloat(maxSpeed)
                    
                    // Start at first point
                    let firstPoint = CGPoint(
                        x: 0,
                        y: height - CGFloat(speedSamples[0]) * yScale
                    )
                    path.move(to: firstPoint)
                    
                    // Draw line to each point
                    for i in 1..<speedSamples.count {
                        let xPos = CGFloat(i) * xStep
                        let yPos = height - CGFloat(speedSamples[i]) * yScale
                        path.addLine(to: CGPoint(x: xPos, y: yPos))
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
                
                // Fill area under curve
                Path { path in
                    if speedSamples.isEmpty {
                        return
                    }
                    
                    // Scale to view size
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let xStep = width / CGFloat(speedSamples.count - 1)
                    let yScale = height / CGFloat(maxSpeed)
                    
                    // Start bottom left
                    path.move(to: CGPoint(x: 0, y: height))
                    
                    // Add first point
                    let firstPoint = CGPoint(
                        x: 0,
                        y: height - CGFloat(speedSamples[0]) * yScale
                    )
                    path.addLine(to: firstPoint)
                    
                    // Add all sample points
                    for i in 1..<speedSamples.count {
                        let xPos = CGFloat(i) * xStep
                        let yPos = height - CGFloat(speedSamples[i]) * yScale
                        path.addLine(to: CGPoint(x: xPos, y: yPos))
                    }
                    
                    // Complete the path by adding bottom right
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                
                // Y-axis labels
                VStack(alignment: .leading) {
                    ForEach(0..<5) { i in
                        Text(formatSpeed(bytes: maxSpeed / 4 * Double(4 - i)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(height: geometry.size.height / 4)
                    }
                }
                .offset(x: -2)
            }
        }
        .frame(height: 150)
        .padding(.leading, 40) // Space for labels
    }
    
    // MARK: - Helper Methods
    
    private func calculateTimeForSample(index: Int) -> Date {
        // Evenly distribute sample times between start and end time
        let totalDuration = endTime.timeIntervalSince(startTime)
        let sampleInterval = totalDuration / Double(max(1, speedSamples.count - 1))
        return startTime.addingTimeInterval(sampleInterval * Double(index))
    }
    
    private func formatSpeed(bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes)) + "/s"
    }
    
    private func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
