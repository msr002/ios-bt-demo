##  1. 概述

当前工程珠海市杰理科技股份有限公司(以下简称“本公司”)开发收集，为本公司相关产品提供蓝牙接入提供的开发示例工程。

### 1.1. 运行环境

| 类别     | 兼容范围  | 备注                 |
| -------- | --------- | -------------------- |
| iOS 系统 | iOS 12.0+ | 支持 BLE 功能        |
| 硬件要求 | BLE/EDR   | 蓝牙 4.2+设备        |
| 开发平台 | xcode     | 建议使用最新版本开发 |

## 2. 历史修改说明

| Date       | Author   | Content                                                      |
| ---------- | -------- | ------------------------------------------------------------ |
| 2025/03/32 | EzioChan | 1. 新增收集 **[Using Core Bluetooth Classic](#2.1 Using Core Bluetooth Classic)** |



## 2. 目录结构

### 2.1 Using Core Bluetooth Classic

在 iOS 开发中，CoreBluetooth 框架允许应用程序与支持蓝牙低能耗（BLE）的设备进行通信。为了更高效地管理蓝牙连接状态，iOS 提供了 `CBCentralManagerDelegate` 中的 `registerForConnectionEvents(options:)` 方法和对应的代理方法 `centralManager(_:connectionEventDidOccur:for:)` 来监听蓝牙设备的连接事件。对应底层描述是 GATT OVER EDR 连接业务，简称 ATT 连接业务。

本 Demo 来自 Apple 的：[using-core-bluetooth-classic](https://gitee.com/link?target=https%3A%2F%2Fdeveloper.apple.com%2Fdocumentation%2Fcorebluetooth%2Fusing-core-bluetooth-classic)

