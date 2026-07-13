# CBClassic

<div align="center">

**A GATT over BR/EDR device connection sample based on the CoreBluetooth framework, demonstrating how to communicate with Bluetooth devices via the GATT protocol on iOS.**

[中文](./README.md) · [English](./README_en.md) · [Documentation Center](https://doc.zh-jieli.com/Apps/iOS/ota/zh-cn/master/Development/Content/gatt_over_edr_desc.html#gatt-over-edr) · [Version History](#10-version-history) · [Report Issues](https://github.com/Jieli-Tech/ios-bt-demo/issues)

</div>

---

## 📋 Table of Contents

- [1. Overview](#1-overview)
- [2. Supported Platforms and Devices](#2-supported-platforms-and-devices)
- [3. Quick Start](#3-quick-start)
- [4. Project Structure](#4-project-structure)
- [5. Usage Guide](#5-usage-guide)
- [6. Configuration](#6-configuration)
- [7. Debugging](#7-debugging)
- [8. Notes](#8-notes)
- [9. Community & Support](#9-community--support)
- [10. Version History](#10-version-history)
- [11. License](#11-license)

---

## 1. Overview

`CBClassic` is an iOS GATT over BR/EDR device connection sample project provided by Zhuhai Jieli Technology Co., Ltd.

In iOS development, the CoreBluetooth framework allows applications to communicate with Bluetooth Low Energy (BLE) devices. GATT communication is divided into two types: **GATT over BLE** and **GATT over BR/EDR**:

| Protocol Type | Underlying Protocol | Characteristics |
|---------|---------|------|
| **GATT over BR/EDR** | BR/EDR underlying protocol | Higher efficiency, faster transfer rates, and larger data volumes |

This sample is based on Apple's official [Using Core Bluetooth Classic](https://developer.apple.com/documentation/corebluetooth/using-core-bluetooth-classic) example, demonstrating GATT over BR/EDR device connection event monitoring, connection/disconnection management, service discovery, and data transmission/reception.

> **Core API**: Use the `registerForConnectionEvents(options:)` method and the delegate method `centralManager(_:connectionEventDidOccur:for:)` from `CBCentralManagerDelegate` to monitor GATT over BR/EDR connection events.

---

## 2. Supported Platforms and Devices

### 2.1 iOS System Requirements

| Item | Description |
|------|------|
| **Minimum Version** | iOS 13.0 |
| **Target Version** | iOS 13.0+ |
| **Language** | Swift |
| **Development Environment** | Xcode 14.0+ |

### 2.2 Supported Bluetooth Protocols

| Protocol | Description | Status |
|------|------|------|
| GATT over BR/EDR | GATT communication based on Classic Bluetooth, higher throughput | ✅ Supported |

> **Note**: The `registerForConnectionEvents` method is available on iOS 13.0 and above.

---

## 3. Quick Start

### 3.1 Clone the Repository

```bash
git clone <repository-url>
cd UsingCoreBluetoothClassic
```

### 3.2 Open the Project

1. Open **Xcode**
2. Click **File → Open**, select `CoreBluetoothClassicSample.xcodeproj`
3. Choose a target device or simulator
4. Click **Run (▶)** to build and run

### 3.3 Permission Configuration

Bluetooth usage permission has been configured in `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Use bluetooth to discover, connect to, and share information with nearby devices</string>
```

For background Bluetooth support, configure the background mode:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
</array>
```

---

## 4. Project Structure

```
UsingCoreBluetoothClassic/
├── CoreBluetoothClassicSample.xcodeproj/      # Xcode project file
├── CoreBluetoothClassicSample/                # Main application module
│   ├── AppDelegate.swift                      #   App delegate
│   ├── CentralViewController.swift            #   Central device controller (scan & connect)
│   ├── PeripheralViewController.swift         #   Peripheral interaction controller (data TX/RX)
│   ├── Assets.xcassets/                       #   Asset catalog
│   ├── Base.lproj/                            #   Storyboard files
│   └── Info.plist                             #   App configuration (permissions, etc.)
├── Configuration/                             # Build configuration
│   └── SampleCode.xcconfig
└── LICENSE                                    # Apache 2.0 license
```

### 4.1 Core Class Overview

| Class | Path | Description |
|------|------|------|
| `CentralViewController` | `CoreBluetoothClassicSample/CentralViewController.swift` | Central device controller, responsible for CBCentralManager initialization and ATT device connection event monitoring |
| `PeripheralViewController` | `CoreBluetoothClassicSample/PeripheralViewController.swift` | Peripheral interaction controller, responsible for service discovery, characteristic read/write, and data transmission/reception |
| `BTConstants` | Defined inside `CentralViewController.swift` | Global UUID constants, including service UUID and read/write characteristic UUIDs |

---

## 5. Usage Guide

### 5.1 Permission Request

Starting from iOS 13, accessing Bluetooth requires explicit user consent. You must declare `NSBluetoothAlwaysUsageDescription` in `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Use bluetooth to discover, connect to, and share information with nearby devices</string>
```

### 5.2 GATT over BR/EDR Connection Event Monitoring

Use `registerForConnectionEvents(options:)` to register for GATT over BR/EDR connection event monitoring:

```swift
// Initialize CBCentralManager
cbManager = CBCentralManager(delegate: self, queue: nil)

// Check Bluetooth status in centralManagerDidUpdateState(_:)
func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .poweredOn:
        os_log("Starting cbManager")
        let matchingOptions = [
            CBConnectionEventMatchingOption.serviceUUIDs: [BTConstants.sampleServiceUUID]
        ]
        cbManager.registerForConnectionEvents(options: matchingOptions)
    case .poweredOff:
        os_log("Bluetooth is currently powered off")
    default:
        break
    }
}
```

After registration, when a GATT over BR/EDR device connects or disconnects, the system calls the following delegate method:

```swift
func centralManager(_ central: CBCentralManager,
                    connectionEventDidOccur event: CBConnectionEvent,
                    for peripheral: CBPeripheral) {
    switch event {
    case .peerConnected:
        os_log("peerConnected for peripheral: %@", peripheral)
        cbPeripherals.append(peripheral)
    case .peerDisconnected:
        os_log("peerDisconnected for peripheral: %@", peripheral)
        if let idx = cbPeripherals.firstIndex(where: { $0 === peripheral }) {
            cbPeripherals.remove(at: idx)
        }
    @unknown default:
        fatalError("Unhandled event type")
    }
    tableView.reloadData()
}
```

### 5.3 Connecting to a Device and Discovering Services

After the user taps a device in the device list, `connect(_:options:)` is called to establish a connection. On successful connection, the app navigates to `PeripheralViewController` for service discovery:

```swift
// Handle connection in CentralViewController
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let peripheral = cbPeripherals[indexPath.row]
    cbManager.connect(peripheral, options: nil)
}

func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    os_log("peripheral: %@ connected", peripheral)
    let peripheralVC = PeripheralViewController()
    peripheralVC.cbManager = cbManager
    peripheralVC.selectedPeripheral = peripheral
    present(peripheralVC, animated: true, completion: nil)
}
```

In `PeripheralViewController`, set the delegate and initiate service discovery:

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    selectedPeripheral.delegate = self
    selectedPeripheral.discoverServices([BTConstants.sampleServiceUUID])
}
```

### 5.4 Sending Data

Send data to the device via the Write Characteristic:

```swift
@objc private func sendData() {
    guard let characteristic = writeCharacteristic else {
        os_log("Write characteristic not found")
        return
    }
    guard let text = inputTextField.text, !text.isEmpty else { return }

    let dataToSend = text.data(using: .utf8)!
    selectedPeripheral.writeValue(dataToSend, for: characteristic, type: .withResponse)
    os_log("Sent data: %@", text)
}
```

### 5.5 Receiving Data

After subscribing to the Notify Characteristic, data pushed from the device is received via the delegate method:

```swift
// Subscribe to notifications
peripheral.setNotifyValue(true, for: characteristic)

// Data reception callback
func peripheral(_ peripheral: CBPeripheral,
                didUpdateValueFor characteristic: CBCharacteristic,
                error: Error?) {
    if characteristic.uuid == BTConstants.readCharacteristicUUID,
       let value = characteristic.value {
        let receivedText = String(data: value, encoding: .utf8) ?? "Invalid Data"
        os_log("Received data: %@", receivedText)
        DispatchQueue.main.async {
            self.receivedDataLabel.text = "Received: \(receivedText)"
        }
    }
}
```

---

## 6. Configuration

UUID constants are defined in the `BTConstants` struct inside `CentralViewController.swift`:

```swift
struct BTConstants {
    static let sampleServiceUUID = CBUUID(string: "AE00")          // Service UUID
    static let writeCharacteristicUUID = CBUUID(string: "AE01")    // Write Characteristic UUID
    static let readCharacteristicUUID = CBUUID(string: "AE02")     // Read/Notify Characteristic UUID
}
```

> **💡 Tip**: Modify the above constants to match the UUID configuration of your actual device, ensuring that the app-side UUIDs are consistent with the device-side UUIDs.

---

## 7. Debugging

### 7.1 Log Output

The project uses `os_log` for log output. You can view runtime logs in the Xcode Console:

```swift
import os.log

os_log("Starting cbManager")
os_log("peerConnected for peripheral: %@", peripheral)
os_log("Received data: %@", receivedText)
```

### 7.2 Console Filtering

Enter keywords (such as `peripheral`, `Received`, `Error`) in the Xcode Console search box to quickly filter relevant logs.

### 7.3 Troubleshooting

| Issue | Possible Cause | Troubleshooting |
|------|---------|---------|
| Device not found | Bluetooth disabled / permission not granted | Check system Bluetooth switch and app permission settings |
| Connection failed | Device not paired / UUID mismatch | Ensure the device is paired and UUIDs are correctly configured |
| Data TX/RX failed | Characteristic not discovered / notification not subscribed | Check `didDiscoverCharacteristicsFor` callback logs |

---

## 8. Notes

1. **iOS Version Requirement**: The `registerForConnectionEvents` method requires iOS 13.0 or above.
2. **Performance Impact**: Frequent connection event reception may affect app performance; it is recommended to carefully choose which device connection events to monitor.
3. **Background Mode**: To handle Bluetooth connection events in the background, configure the `bluetooth-central` background mode in Info.plist.
4. **ATT Device Requirements**:
   - The device must be a **dual-mode device**
   - The device must be **paired** before connecting (as required by the BR/EDR underlying protocol)
   - iOS ATT functionality may have compatibility differences; thorough testing on target devices is recommended.
5. **Simulator Limitation**: Bluetooth functionality cannot be used on the iOS Simulator; use a physical device for testing.

> Note: This sample code project is associated with WWDC 2019 session [901: What's New in Core Bluetooth](https://developer.apple.com/videos/play/wwdc19/901/).

---

## 9. Community & Support

### Technical Discussion

| Platform | Link | Status |
|------|------|------|
| **Gitee** | [JieLi-Tech](https://github.com/Jieli-Tech) | ✅ Active |
| **Issue Tracking** | [Submit Issue](https://github.com/Jieli-Tech/ios-bt-demo/issues) | ✅ Open |

### Resources

| Resource | Link |
|------|------|
| 📖 **Online Documentation Center** | [https://doc.zh-jieli.com/vue](https://doc.zh-jieli.com/vue/#/home) |
| 🐛 **Issue Tracking** | [Gitee Issues](https://github.com/Jieli-Tech/ios-bt-demo/issues) |

---

## 10. Version History

| Version | Date       | Changes                                  |
| ------- | ---------- | ---------------------------------------- |
| 1.0.0   | 2025/03/31 | 1. Initial version<br />2. Added GATT over BR/EDR device connection event monitoring sample<br />3. Added data transmission and reception functionality |

---

## 11. License

This project is licensed under the [Apache License 2.0](./LICENSE).

```
Copyright 2024 Zhuhai Jieli Technology Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

<div align="center">

   **© 2024 Zhuhai Jieli Technology Co., Ltd. | Licensed under Apache License 2.0**

</div>
