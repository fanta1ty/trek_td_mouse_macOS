//
//  WiFiConnectionView.swift
//  tdMouse
//
//  Created by Thinh Nguyen on 9/4/25.
//

import SwiftUI
import NetworkExtension

struct WiFiConnectionView: View {
    @State private var isConnectingToWiFi = false
    @State private var connectionStatus = "Ready to connect"
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // TD Mouse WiFi details
    let tdMouseSSID = "A73PHP"
    let tdMousePassword = "password123"
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Connect to TD Mouse")
                .font(.title)
                .padding()
            
            // Status indicator
            Text(connectionStatus)
                .padding()
                .background(statusBackgroundColor)
                .cornerRadius(8)
            
            // Connection button
            Button(action: {
                connectToTDMouse()
            }) {
                Text("Connect to TD Mousee")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isConnectingToWiFi)
            
            if isConnectingToWiFi {
                ProgressView()
                    .padding()
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Connection Status"),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    private var statusBackgroundColor: Color {
        switch connectionStatus {
        case "Connected":
            return Color.green.opacity(0.3)
        case "Failed to connect":
            return Color.red.opacity(0.3)
        default:
            return Color.gray.opacity(0.3)
        }
    }
    
    private func connectToTDMouse() {
        isConnectingToWiFi = true
        connectionStatus = "Connecting via Bluetooth..."
        
        triggerWiFiConnectionDialog()
    }
    
    private func triggerWiFiConnectionDialog() {
        connectionStatus = "Requesting WiFi connection..."
        
        // This is where the system dialog is triggered
        let configuration = NEHotspotConfiguration(ssid: tdMouseSSID, passphrase: tdMousePassword, isWEP: false)
        configuration.joinOnce = false
        
        NEHotspotConfigurationManager.shared.apply(configuration) { error in
            isConnectingToWiFi = false
            
            if let error = error {
                handleError("WiFi connection error: \(error.localizedDescription)")
            } else {
                connectionStatus = "Connected"
                alertMessage = "Successfully connected to TD Mouse WiFi network"
                showAlert = true
                
                // Proceed with file transfer or other operations
                // initiateFileTransfer()
            }
        }
    }
    
    private func handleError(_ message: String) {
        connectionStatus = "Failed to connect"
        alertMessage = message
        showAlert = true
        isConnectingToWiFi = false
    }
}
