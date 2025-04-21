import CoreBluetooth
import Foundation

class BLEManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var connectedDevice: CBPeripheral?

    @Published var batteryLevel: Int = 0
    @Published var isWiFiEnabled: Bool = false
    
    private var centralManager: CBCentralManager!
    
    private struct UUIDTable {
        static let gattService = CBUUID(string: "4D45")
        static let earbudNameService = CBUUID(string: "4C48")
    }
    
    private struct CharacteristicUUIDs {
        static let battery = CBUUID(string: "4C47")
        static let wifiControl = CBUUID(string: "FFA1")
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        discoveredDevices.removeAll()
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }
    
    func stopScanning() {
        centralManager.stopScan()
    }
    
    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        if let peripheral = connectedDevice {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func toggleWiFi(enabled: Bool) {
        guard isConnected, let peripheral = connectedDevice else { return }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            guard let characteristics = service.characteristics else { continue }
            
            for characteristic in characteristics {
                print("toggleWiFi is: \(enabled)  - \(characteristic.uuid)")
                if characteristic.uuid == CharacteristicUUIDs.wifiControl {
                    // Gửi lệnh bật/tắt WiFi (1 byte: 0x01 để bật, 0x00 để tắt)
                    let value: [UInt8] = [enabled ? 0x01 : 0x00]
                    let data = Data(value)
                    
                    peripheral.writeValue(data, for: characteristic, type: .withResponse)
                    print("Sending WiFi command: \(enabled ? "ON" : "OFF")")
                    
                    isWiFiEnabled = enabled
                    return
                }
            }
        }
    }
    
    func processUpdatedCharacteristic(_ characteristic: CBCharacteristic) {
        guard let value = characteristic.value else { return }
        
        switch characteristic.uuid {
        case CharacteristicUUIDs.battery:
            if value.count > 0 {
                let percentage = Int(value[0])
                DispatchQueue.main.async {
                    self.batteryLevel = percentage
                    print("Battery level updated: \(percentage)%")
                }
            }
            
        case CharacteristicUUIDs.wifiControl:
            if value.count > 0 {
                let status = value[0] > 0
                DispatchQueue.main.async {
                    self.isWiFiEnabled = status
                    print("WiFi status updated: \(status ? "ON" : "OFF")")
                }
            }
            
        default:
            break
        }
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        default:
            isConnected = false
            discoveredDevices.removeAll()
            connectedDevice = nil
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            discoveredDevices.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        connectedDevice = peripheral
        isConnected = true
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectedDevice = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.startScanning()
        }
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            switch service.uuid {
            case UUIDTable.gattService,
                UUIDTable.earbudNameService:
                
                peripheral.discoverCharacteristics(nil, for: service)
            default:
                // Discover all characteristics for battery and WiFi control
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            
            // Enable notifications for battery and WiFi control if supported
            if (characteristic.uuid == CharacteristicUUIDs.battery ||
                characteristic.uuid == CharacteristicUUIDs.wifiControl) &&
                characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error updating characteristic value: \(error.localizedDescription)")
            return
        }
        
        guard let value = characteristic.value else {
            return
        }
        
        processUpdatedCharacteristic(characteristic)
        
        // Log debug
        if characteristic.uuid == CharacteristicUUIDs.battery || characteristic.uuid == CharacteristicUUIDs.wifiControl {
            let hexString = value.map { String(format: "%02X", $0) }.joined()
            print("Read data 1: \(characteristic.uuid.uuidString): \(hexString)")
        } else if characteristic.uuid == UUIDTable.earbudNameService {
            if let stringValue = String(data: value, encoding: .utf8) {
                print("Read data 2: \(characteristic.uuid.uuidString): \(stringValue)")
            }
        } else {
            let hexString = value.map { String(format: "%02X", $0) }.joined()
            print("Read data 3: \(characteristic.uuid.uuidString): \(hexString)")
        }
    }
}
