//
//  BLEConnectView.swift
//  tdMouse_ios
//
//  Created by mobile on 8/4/25.
//
import SwiftUI

struct BLEConnectionStatusView: View {
    @Binding var isBLEConnectSheetPresented: Bool
    @EnvironmentObject var bleManager: BLEManager
    
    var body: some View {
        HStack {
            Text("BLE Connection: ")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(bleManager.isConnected ? "Connected" : "Disconnected")
                .font(.subheadline)
                .foregroundColor(bleManager.isConnected ? .green : .red)
            
            Spacer()
            
            Button(action: {
                isBLEConnectSheetPresented = true
            }) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct BLEConnectionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        BLEConnectionStatusView(isBLEConnectSheetPresented: .constant(false))
            .environmentObject(BLEManager())
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
