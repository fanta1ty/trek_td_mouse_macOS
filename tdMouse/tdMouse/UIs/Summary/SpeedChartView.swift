//
//  SpeedChartView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 14/3/25.
//

import SwiftUI

struct SpeedChartView: View {
    let speedSamples: [Double]
    
    private var normalizedSamples: [Double] {
        guard let maxValue = speedSamples.max(), maxValue > 0 else {
            return speedSamples.map { _ in 0 }
        }
        
        return speedSamples.map { $0 / maxValue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Transfer Speed")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(normalizedSamples.count - 1)
                    
                    // Start at the first point
                    path.move(
                        to: .init(
                            x: 0,
                            y: height - (CGFloat(normalizedSamples[0] * height))
                        )
                    )
                    
                    // Draw lines
                    for i in 1..<normalizedSamples.count {
                        path.addLine(
                            to: .init(
                                x: stepX * CGFloat(i),
                                y: height - (CGFloat(normalizedSamples[i]) * height)
                            )
                        )
                    }
                }
                .stroke(Color.accentColor, lineWidth: 2)
            }
        }
    }
}

struct SpeedChartView_Previews: PreviewProvider {
    static var previews: some View {
        SpeedChartView(speedSamples: [100, 200, 300, 200, 100])
    }
}
