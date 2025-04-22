import SwiftUI

struct BLEDeviceStatusView: View {
    @EnvironmentObject private var bleManager: BLEManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Device name and connection status
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(bleManager.connectedDeviceName)
                        .font(.headline)
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
                
                Text("Connected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // WiFi status
            VStack(alignment: .center, spacing: 2) {
                Button(action: {
                    bleManager.toggleWifi()
                }) {
                    Image(systemName: bleManager.isWifiOn ? "wifi" : "wifi.slash")
                        .font(.system(size: 16))
                        .foregroundColor(bleManager.isWifiOn ? .blue : .gray)
                }
                
                Text("WiFi")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 40)
            
            // Battery status
            VStack(alignment: .center, spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: batteryIconName)
                        .font(.system(size: 16))
                        .foregroundColor(batteryColor)
                    
                    Text("\(bleManager.batteryLevel)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Battery")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    // Dynamically choose battery icon based on level
    private var batteryIconName: String {
        let level = bleManager.batteryLevel
        
        if level <= 10 {
            return "battery.0"
        } else if level <= 25 {
            return "battery.25"
        } else if level <= 50 {
            return "battery.50"
        } else if level <= 75 {
            return "battery.75"
        } else {
            return "battery.100"
        }
    }
    
    // Dynamically choose battery color based on level
    private var batteryColor: Color {
        let level = bleManager.batteryLevel
        
        if level <= 20 {
            return .red
        } else if level <= 40 {
            return .orange
        } else {
            return .green
        }
    }
}
