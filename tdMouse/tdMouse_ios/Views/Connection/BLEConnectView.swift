import SwiftUI
import CoreBluetooth

struct BLEConnectView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var isPresented: Bool
    
    private var uniqueDevices: [CBPeripheral] {
        return Array(Set(bleManager.discoveredDevices))
    }
    
    var body: some View {
        NavigationView {
            List(uniqueDevices, id: \.identifier) { device in
                Button(action: {
                    bleManager.connect(to: device)
                    isPresented = false
                }) {
                    HStack {
                        Text(device.name ?? "Unknown Device")
                        Spacer()
                        if bleManager.connectedDevice?.identifier == device.identifier {
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
            }
            .overlay(
                Group {
                    if uniqueDevices.isEmpty {
                        Text("No BLE devices found")
                            .foregroundColor(.gray)
                    }
                }
            )
        }
    }
}

struct BLEConnectView_Previews: PreviewProvider {
    static var previews: some View {
        BLEConnectView(isPresented: .constant(true))
            .environmentObject(BLEManager())
    }
}

