// FileTransferProgressView.swift
import SwiftUI

//struct FileTransferProgressView: View {
//    @EnvironmentObject private var bleManager: BLEManager
//    @State private var showTransferCompleteAlert = false
//    
//    var body: some View {
//        if bleManager.isTransferring {
//            VStack(spacing: 16) {
//                Text("Receiving File...")
//                    .font(.headline)
//                
//                ProgressView(value: bleManager.transferProgress)
//                    .progressViewStyle(LinearProgressViewStyle())
//                    .frame(height: 20)
//                
//                Text("\(Int(bleManager.transferProgress * 100))%")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//            }
//            .padding()
//            .background(Color(UIColor.secondarySystemBackground))
//            .cornerRadius(10)
//            .padding()
//        }
//    }
//}
