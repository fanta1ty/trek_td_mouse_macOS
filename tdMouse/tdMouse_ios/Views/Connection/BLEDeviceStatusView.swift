import SwiftUI

struct BLEDeviceStatusView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    var body: some View {
        VStack(spacing: 8) {
            if bleManager.isConnected {
                // First row: Battery and Device name
                HStack {
                    // Battery status
                    BatteryIndicator(percentage: bleManager.batteryLevel)
                    
                    Spacer()
                    
                    // Connected device name
                    Text(bleManager.connectedDevice?.name ?? "Device")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Second row: WiFi toggle
                WiFiToggleView()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .opacity(bleManager.isConnected ? 1 : 0)
        .frame(height: bleManager.isConnected ? nil : 0)
    }
}

struct BatteryIndicator: View {
    var percentage: Int
    
    private var batteryColor: Color {
        if percentage <= 20 {
            return .red
        } else if percentage <= 40 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var batteryIcon: String {
        if percentage <= 10 {
            return "battery.0"
        } else if percentage <= 25 {
            return "battery.25"
        } else if percentage <= 50 {
            return "battery.50"
        } else if percentage <= 75 {
            return "battery.75"
        } else {
            return "battery.100"
        }
    }
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: batteryIcon)
                .foregroundColor(batteryColor)
            
            Text("\(percentage)%")
                .font(.subheadline)
                .foregroundColor(batteryColor)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.tertiarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        )
    }
}

struct WiFiToggleView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var isWifiEnabled: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: isWifiEnabled ? "wifi" : "wifi.slash")
                .foregroundColor(isWifiEnabled ? .blue : .gray)
            
            Text("Wi-Fi")
                .font(.subheadline)
            
            Spacer()
            
            Toggle("", isOn: $isWifiEnabled)
                .labelsHidden()
                .onChange(of: isWifiEnabled) { newValue in
                    bleManager.toggleWiFi(enabled: newValue)
                }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.tertiarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        )
        .onAppear {
            isWifiEnabled = bleManager.isWiFiEnabled
        }
    }
}

struct BLEDeviceStatusView_Previews: PreviewProvider {
    static var previews: some View {
        let mockBLEManager = BLEManager()
        
        return BLEDeviceStatusView()
            .environmentObject(mockBLEManager)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
