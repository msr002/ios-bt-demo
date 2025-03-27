import CoreBluetooth
import UIKit
import os.log

class PeripheralViewController: UIViewController {
    private var sendButton: UIButton!
    private var inputTextField: UITextField!
    private var receivedDataLabel: UILabel!

    var cbManager: CBCentralManager!
    var selectedPeripheral: CBPeripheral!
    
    private var writeCharacteristic: CBCharacteristic?
    private var readCharacteristic: CBCharacteristic?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        
        selectedPeripheral.delegate = self
        selectedPeripheral.discoverServices([BTConstants.sampleServiceUUID])
    }
    
    private func setupUI() {
        // 1. 创建输入框
        inputTextField = UITextField()
        inputTextField.placeholder = "请输入要发送的内容"
        inputTextField.borderStyle = .roundedRect
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputTextField)

        // 2. 创建发送按钮
        sendButton = UIButton(type: .system)
        sendButton.setTitle("发送", for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.backgroundColor = .blue
        sendButton.layer.cornerRadius = 8
        sendButton.addTarget(self, action: #selector(sendData), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)

        // 3. 创建接收数据标签
        receivedDataLabel = UILabel()
        receivedDataLabel.text = "接收数据："
        receivedDataLabel.numberOfLines = 0
        receivedDataLabel.textAlignment = .center
        receivedDataLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(receivedDataLabel)

        // 4. 添加 Auto Layout 约束
        NSLayoutConstraint.activate([
            // 输入框居中，宽度 80%
            inputTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            inputTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            inputTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            inputTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // 发送按钮位于输入框下方
            sendButton.topAnchor.constraint(equalTo: inputTextField.bottomAnchor, constant: 20),
            sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 100),
            sendButton.heightAnchor.constraint(equalToConstant: 44),
            
            // 接收数据标签位于按钮下方
            receivedDataLabel.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 30),
            receivedDataLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            receivedDataLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9)
        ])
    }

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
}

extension PeripheralViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            os_log("Error discovering services: %@", error.localizedDescription)
            return
        }

        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics([BTConstants.writeCharacteristicUUID, BTConstants.readCharacteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            os_log("Error discovering characteristics: %@", error.localizedDescription)
            return
        }

        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid == BTConstants.writeCharacteristicUUID {
                writeCharacteristic = characteristic
                os_log("Found write characteristic AE01")
            }
            if characteristic.uuid == BTConstants.readCharacteristicUUID {
                readCharacteristic = characteristic
                os_log("Found read characteristic AE02, subscribing...")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            os_log("Error reading characteristic: %@", error.localizedDescription)
            return
        }

        if characteristic.uuid == BTConstants.readCharacteristicUUID, let value = characteristic.value {
            let receivedText = String(data: value, encoding: .utf8) ?? "Invalid Data"
            os_log("Received data: %@", receivedText)
            DispatchQueue.main.async {
                self.receivedDataLabel.text = "接收数据：\(receivedText)"
            }
        }
    }
}
