import Foundation
import CoreBluetooth

class BLEManager: NSObject, ObservableObject, CBPeripheralDelegate {
    // MARK: - Published Properties
    @Published var isScanning: Bool = false
    @Published var isConnected: Bool = false
    @Published var discoveredPeripherals: [CBPeripheral] = []
    @Published var isTransferring: Bool = false
    @Published var transferProgress: Float = 0.0
    @Published var transferCompleted: Bool = false
    @Published var transferError: Error?
    @Published var savedFileURL: URL?
    @Published var connectedDeviceName: String = ""
    
    @Published var batteryLevel: Int = 100
    @Published var isWifiOn: Bool = true
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    private var characteristics: [CBUUID: CBCharacteristic] = [:]
    var fileTransferInfo = FileTransferInfo(
        fileName: "",
        fileSize: 0,
        totalChunks: 0,
        currentChunk: 0,
        fileData: Data()
    )
    
    // MARK: - Initialization
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateBatteryLevel()
        }
    }
    
    // MARK: - Public Methods
    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        
        isScanning = true
        discoveredPeripherals.removeAll()
        
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScan() {
        centralManager.stopScan()
        isScanning = false
    }
    
    func connect(to peripheral: CBPeripheral) {
        stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func toggleWifi() {
        isWifiOn.toggle()
        print("Wifi is now \(isWifiOn ? "ON" : "OFF")")
    }
    
    private func updateBatteryLevel() {
        // hard code ble battery level
        if batteryLevel > 1 {
            batteryLevel -= 1
        }
    }
    
    // MARK: - Helper Methods for BLE File Transfer
    func writeCharacteristic(uuid: String, data: Data) async throws {
        guard let peripheral = connectedPeripheral else {
            throw BLEError.notConnected
        }
        
        guard let characteristic = findCharacteristic(by: uuid) else {
            throw BLEError.characteristicNotFound
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            continuation.resume()
        }
    }
    
    func readCharacteristic(uuid: String) async throws -> Data {
        guard let peripheral = connectedPeripheral else {
            throw BLEError.notConnected
        }
        
        guard let characteristic = findCharacteristic(by: uuid) else {
            throw BLEError.characteristicNotFound
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            peripheral.readValue(for: characteristic)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let value = characteristic.value {
                    continuation.resume(returning: value)
                } else {
                    continuation.resume(throwing: BLEError.readFailed)
                }
            }
        }
    }
    
    private func findCharacteristic(by uuid: String) -> CBCharacteristic? {
        let targetUUID = uuid.lowercased()
        
        let shortUUID = String(targetUUID.dropFirst(4).prefix(4)).uppercased()
        
        print("Looking for UUID: \(uuid)")
        print("Searching for short UUID: \(shortUUID)")
        print("Available characteristics: \(characteristics.keys.map { $0.uuidString })")
        
        return characteristics.first { (key, characteristic) in
            key.uuidString.lowercased() == targetUUID ||
            key.uuidString.uppercased() == shortUUID
        }?.value
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            guard let services = peripheral.services else { return }
            
            for service in services {
                // Discover characteristics for each service
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            guard let characteristics = service.characteristics else { return }
            
            // Populate characteristics dictionary
            for characteristic in characteristics {
                self.characteristics[characteristic.uuid] = characteristic
                
                // Optional: Enable notifications for specific characteristics if needed
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
            
            // Debug print
            print("Discovered Characteristics:")
            characteristics.forEach { char in
                print("- UUID: \(char.uuid.uuidString)")
            }
        }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth is powered on")
        } else {
            print("Bluetooth is not available: \(central.state.rawValue)")
            isConnected = false
            connectedPeripheral = nil
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Filter for peripherals that start with "TD"
        if let name = peripheral.name, name.hasPrefix("TD") {
            // Check if this peripheral is already in our list
            if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                discoveredPeripherals.append(peripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        connectedDeviceName = peripheral.name ?? "Unknown Device"
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        isConnected = true
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "unknown device"): \(error?.localizedDescription ?? "unknown error")")
        isConnected = false
        connectedPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "unknown device")")
        isConnected = false
        connectedPeripheral = nil
        characteristics.removeAll()
    }
}
