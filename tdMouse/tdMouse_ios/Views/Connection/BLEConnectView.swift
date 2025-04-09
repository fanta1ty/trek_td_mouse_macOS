//
//  BLEConnectView.swift
//  tdMouse_ios
//
//  Created by mobile on 8/4/25.
//
import SwiftUI
import CoreBluetooth

struct BLEConnectView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List(bleManager.discoveredDevices, id: \..identifier) { device in
                Button(action: {
                    bleManager.connect(to: device)
                    isPresented = false
                }) {
                    HStack {
                        Text(device.name ?? "Unknown")
                        Spacer()
                        if bleManager.isConnected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Connect to BLE Device")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct BLEConnectView_Previews: PreviewProvider {
    static var previews: some View {
        BLEConnectView(isPresented: .constant(true))
            .environmentObject(BLEManager())
    }
}
