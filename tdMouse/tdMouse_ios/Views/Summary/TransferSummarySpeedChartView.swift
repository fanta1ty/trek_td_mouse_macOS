//
//  TransferSummarySpeedChartView.swift
//  tdMouse
//
//  Created by mobile on 7/4/25.
//

import SwiftUI

struct TransferSummarySpeedChartView: View {
    let samples: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Background
                VStack(spacing: 0) {
                    Divider()
                    Spacer()
                    Divider()
                    Spacer()
                    Divider()
                }
                
                // Y-axis labels
                if let maxSpeed = samples.max(), maxSpeed > 0 {
                    VStack(alignment: .leading) {
                        Text(Helpers.formatSpeed(maxSpeed))
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(Helpers.formatSpeed(maxSpeed/2))
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("0")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 20)
                }
                
                // Chart
                Path { path in
                    guard samples.count > 1, let maxSpeed = samples.max(), maxSpeed > 0 else {
                        return
                    }
                    
                    let width = geometry.size.width - 20
                    let height = geometry.size.height
                    let stepX = width / CGFloat(samples.count - 1)
                    
                    let points = samples.enumerated().map { index, speed in
                        CGPoint(
                            x: 20 + CGFloat(index) * stepX,
                            y: height - CGFloat(speed / maxSpeed) * height
                        )
                    }
                    
                    if let firstPoint = points.first {
                        path.move(to: firstPoint)
                    }
                    
                    // Connect the dots
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
                
                // Points on the chart
                ForEach(0..<samples.count, id: \.self) { index in
                    if let maxSpeed = samples.max(), maxSpeed > 0 {
                        let width = geometry.size.width - 20
                        let height = geometry.size.height
                        let stepX = width / CGFloat(samples.count - 1)
                        
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 4, height: 4)
                            .position(
                                x: 20 + CGFloat(index) * stepX,
                                y: height - CGFloat(samples[index] / maxSpeed) * height
                            )
                    }
                }
            }
        }
    }
}

struct TransferSummarySpeedChartView_Previews: PreviewProvider {
    static var previews: some View {
        TransferSummarySpeedChartView(
            samples: [
                256 * 1024,
                512 * 1024,
                650 * 1024,
                325 * 1024,
                420 * 1024
            ]
        )
    }
}
