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
            
            if let connectedDevice = bleManager.connectedDevice {
                Text(connectedDevice.name ?? "Unknown Device")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                // If connected, offer disconnect option
                if bleManager.isConnected {
                    bleManager.disconnect()
                } else {
                    isBLEConnectSheetPresented = true
                }
            }) {
                Image(systemName: bleManager.isConnected ? "xmark.circle" : "antenna.radiowaves.left.and.right")
                    .foregroundColor(bleManager.isConnected ? .red : .blue)
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
