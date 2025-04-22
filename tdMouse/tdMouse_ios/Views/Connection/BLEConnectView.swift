import SwiftUI
import CoreBluetooth

struct BLEConnectView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var isPresented: Bool
    
    // Sửa phần này để lấy các thiết bị duy nhất thay vì dùng Set
    private var uniqueDevices: [CBPeripheral] {
        // Tạo một dictionary với key là identifier để loại bỏ trùng lặp
        var deviceDict = [UUID: CBPeripheral]()
        for device in bleManager.discoveredPeripherals {
            deviceDict[device.identifier] = device
        }
        return Array(deviceDict.values)
    }
    
    var body: some View {
        List(uniqueDevices, id: \.identifier) { device in
            Button(action: {
                bleManager.connect(to: device)
                isPresented = false
            }) {
                HStack {
                    Text(device.name ?? "Unknown Device")
                    Spacer()
                    if bleManager.connectedPeripheral?.identifier == device.identifier {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .navigationTitle("Connect To Devices")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isPresented = false
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    bleManager.startScan()
                }) {
                    Label("Scan", systemImage: "arrow.clockwise")
                }
            }
        }
        .overlay(
            Group {
                if uniqueDevices.isEmpty {
                    VStack {
                        Text("No BLE devices found")
                            .foregroundColor(.gray)
                        
                        if bleManager.isScanning {
                            ProgressView()
                                .padding(.top, 8)
                        } else {
                            Button(action: {
                                bleManager.startScan()
                            }) {
                                Text("Scan for Devices")
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            }
        )
        .onAppear {
            bleManager.startScan()
        }
        .onDisappear {
            bleManager.stopScan()
        }
    }
}

struct BLEConnectView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BLEConnectView(isPresented: .constant(true))
                .environmentObject(BLEManager())
        }
    }
}
