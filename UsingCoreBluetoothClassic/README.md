# Using Core Bluetooth  Classic


## 概述

在 iOS 开发中，CoreBluetooth 框架允许应用程序与支持蓝牙低能耗（BLE）的设备进行通信。为了更高效地管理蓝牙连接状态，iOS 提供了 `CBCentralManagerDelegate` 中的 `registerForConnectionEvents(options:)` 方法和对应的代理方法 `centralManager(_:connectionEventDidOccur:for:)` 来监听蓝牙设备的连接事件。对应底层描述是 GATT OVER EDR 连接业务，简称 ATT 连接业务。

本 Demo 来自 Apple 的：[using-core-bluetooth-classic](https://developer.apple.com/documentation/corebluetooth/using-core-bluetooth-classic)

本指南将详细介绍如何使用这些 API，并结合一个示例代码来展示其应用。

## 准备工作

在开始之前，请确保你的项目已经导入了 `CoreBluetooth` 框架，并且你已经在 Info.plist 文件中添加了必要的权限声明：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>我们需要您的许可来使用蓝牙功能。</string>
```

这一步是必须的，因为从 iOS 13 开始，访问蓝牙需要用户的明确同意。

## 注册连接事件监听器

首先，你需要创建一个 `CBCentralManager` 实例，并设置其代理。然后调用 `registerForConnectionEvents(options:)` 方法注册对连接事件的兴趣。以下是如何实现这一点的示例代码片段：

```swift
cbManager = CBCentralManager(delegate: self, queue: nil)
// 在 centralManagerDidUpdateState(_:) 回调中检查中央管理器的状态是否为 poweredOn
if cbManager.state == .poweredOn {
    let matchingOptions = [CBConnectionEventMatchingOption.serviceUUIDs: [BTConstants.sampleServiceUUID]]
    cbManager.registerForConnectionEvents(options: matchingOptions)
}
```

这里我们指定了一个服务 UUID 列表作为匹配选项，这意味着只有那些提供特定服务的外围设备的连接事件会被监听到。

## 监听连接事件

一旦注册完成，每当有蓝牙设备连接或断开时，系统会调用 `centralManager(_:connectionEventDidOccur:for:)` 方法。下面是一个简单的实现例子：

```swift
func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
    switch event {
    case .peerConnected:
        // 处理设备连接事件
        os_log("Device %@ connected", peripheral)
        cbPeripherals.append(peripheral)
    case .peerDisconnected:
        // 处理设备断开连接事件
        os_log("Device %@ disconnected!", peripheral)
        if let idx = cbPeripherals.firstIndex(where: { $0 === peripheral }) {
            cbPeripherals.remove(at: idx)
        }
    @unknown default:
        fatalError("Unhandled event type")
    }
    
    tableView.reloadData()
}
```

在这个回调函数中，你可以根据不同的连接事件类型执行相应的逻辑，比如更新用户界面、重新尝试连接等。

## 注意事项

- **性能影响**：频繁地接收连接事件可能会影响应用性能，因此应该谨慎选择监听哪些设备的连接事件。

- **后台模式**：如果你的应用程序需要在后台处理蓝牙连接事件，记得在项目的 Info.plist 文件中配置适当的后台模式权限。

  ![20250326205931](20250326205931.jpg)

- Note: This sample code project is associated with WWDC 2019 session [901: What's New in Core Bluetooth](https://developer.apple.com/videos/play/wwdc19/901/).

# 
