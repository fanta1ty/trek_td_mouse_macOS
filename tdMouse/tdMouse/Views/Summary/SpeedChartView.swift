//
//  SpeedChartView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 14/3/25.
//

import SwiftUI
import Foundation

struct SpeedChartView: View {
    let speedSamples: [Double]
    let maxSpeed: Double? // Optional maximum speed for consistent scaling
    
    @State private var animationProgress: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    
    // Normalized samples for consistent scaling
    private var normalizedSamples: [Double] {
        guard !speedSamples.isEmpty else { return [] }
        
        if let userMaxSpeed = maxSpeed, userMaxSpeed > 0 {
            // Use provided max speed for normalization if available
            return speedSamples.map { min($0 / userMaxSpeed, 1.0) }
        } else if let maxValue = speedSamples.max(), maxValue > 0 {
            // Otherwise use the max value in the samples
            return speedSamples.map { $0 / maxValue }
        } else {
            return speedSamples.map { _ in 0 }
        }
    }
    
    // Format speed values
    private var formattedMaxSpeed: String {
        guard let maxValue = speedSamples.max() else { return "0 KB/s" }
        return formatSpeed(maxValue)
    }
    
    private var formattedAvgSpeed: String {
        guard !speedSamples.isEmpty else { return "0 KB/s" }
        let avgValue = speedSamples.reduce(0, +) / Double(speedSamples.count)
        return formatSpeed(avgValue)
    }
    
    // Format speed values with appropriate units
    private func formatSpeed(_ speed: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        
        let bytesPerSecond = Int64(speed)
        return formatter.string(fromByteCount: bytesPerSecond) + "/s"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Chart header with statistics
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Transfer Speed")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(speedSamples.isEmpty ? "No data" : "Real-time monitoring")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Statistics
                if !speedSamples.isEmpty {
                    HStack(spacing: 16) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Peak")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(formattedMaxSpeed)
                                .font(.system(size: 12, weight: .medium))
                                .monospacedDigit()
                        }
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Average")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(formattedAvgSpeed)
                                .font(.system(size: 12, weight: .medium))
                                .monospacedDigit()
                        }
                    }
                }
            }
            
            // Chart with enhanced visuals
            ZStack(alignment: .bottomLeading) {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        Divider()
                            .opacity(0.3)
                        
                        if i < 4 {
                            Spacer()
                        }
                    }
                }
                
                // Main chart area
                GeometryReader { geometry in
                    ZStack {
                        // Area fill
                        speedAreaFill(in: geometry)
                            .opacity(0.3)
                        
                        // Line chart
                        speedLinePath(in: geometry)
                            .trim(from: 0, to: animationProgress)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .green]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 2.5, lineJoin: .round)
                            )
                        
                        // Data points
                        ForEach(0..<normalizedSamples.count, id: \.self) { index in
                            if index < Int(CGFloat(normalizedSamples.count) * animationProgress) + 1 {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 6, height: 6)
                                    .shadow(color: Color.green.opacity(0.5), radius: 2, x: 0, y: 0)
                                    .position(
                                        x: pointPosition(at: index, in: geometry).x,
                                        y: pointPosition(at: index, in: geometry).y
                                    )
                                    .opacity(normalizedSamples.count > 15 ? 0 : 1) // Hide points if too many samples
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
                .frame(height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ?
                              Color.black.opacity(0.3) :
                              Color.white.opacity(0.5))
                        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                )
            }
            
            // X-axis labels
            if normalizedSamples.count > 1 {
                HStack(spacing: 0) {
                    Text("Start")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Time")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("End")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ?
                      Color(NSColor.controlBackgroundColor).opacity(0.5) :
                      Color(NSColor.controlBackgroundColor))
        )
        .onAppear {
            // Animate the chart on appearance
            withAnimation(.easeInOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
    }
    
    // Helper function to calculate point positions
    private func pointPosition(at index: Int, in geometry: GeometryProxy) -> CGPoint {
        let width = geometry.size.width
        let height = geometry.size.height
        let stepX = width / CGFloat(max(1, normalizedSamples.count - 1))
        let x = stepX * CGFloat(index)
        let y = height - (CGFloat(normalizedSamples[index]) * height)
        
        return CGPoint(x: x, y: y)
    }
    
    // Create path for the line chart
    private func speedLinePath(in geometry: GeometryProxy) -> Path {
        Path { path in
            guard normalizedSamples.count > 1 else { return }
            
            let startPoint = pointPosition(at: 0, in: geometry)
            path.move(to: startPoint)
            
            for i in 1..<normalizedSamples.count {
                let point = pointPosition(at: i, in: geometry)
                path.addLine(to: point)
            }
        }
    }
    
    // Create area fill below the line
    private func speedAreaFill(in geometry: GeometryProxy) -> some View {
        Path { path in
            guard normalizedSamples.count > 1 else { return }
            
            let width = geometry.size.width
            let height = geometry.size.height
            
            // Start at the bottom left
            path.move(to: CGPoint(x: 0, y: height))
            
            // Draw line to the first data point
            path.addLine(to: pointPosition(at: 0, in: geometry))
            
            // Draw lines through all data points
            for i in 1..<normalizedSamples.count {
                path.addLine(to: pointPosition(at: i, in: geometry))
            }
            
            // Complete the path to the bottom right and back to start
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                gradient: Gradient(colors: [.blue, .green.opacity(0.5)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Preview
struct SpeedChartView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Simple chart with few points
            SpeedChartView(
                speedSamples: [100_000, 200_000, 350_000, 500_000, 400_000, 600_000, 300_000],
                maxSpeed: nil
            )
            .padding()
            .frame(width: 500)
            .previewDisplayName("Regular Chart (Light)")
            
            // More complex chart with many points
            SpeedChartView(
                speedSamples: [
                    100_000, 150_000, 220_000, 280_000, 350_000, 400_000, 450_000,
                    520_000, 480_000, 550_000, 600_000, 580_000, 620_000, 700_000,
                    680_000, 720_000, 650_000, 600_000, 550_000, 500_000, 480_000,
                    450_000, 400_000
                ],
                maxSpeed: 800_000 // 800 KB/s cap for consistent scaling
            )
            .padding()
            .frame(width: 500)
            .preferredColorScheme(.dark)
            .previewDisplayName("Complex Chart (Dark)")
            
            // Empty chart
            SpeedChartView(
                speedSamples: [],
                maxSpeed: nil
            )
            .padding()
            .frame(width: 500)
            .previewDisplayName("Empty Chart")
        }
    }
}
