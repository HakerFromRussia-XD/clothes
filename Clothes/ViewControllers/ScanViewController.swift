import UIKit
import CoreBluetooth

@objc class ScanViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var centralManager: CBCentralManager!
    private var scale: CBPeripheral!
    private var devicesMass = [CBPeripheral]()
    private var servicesMass = [CBService]()
    private var characteristicsMass = [CBCharacteristic]()
    private var myDevice: CBPeripheral?
    
    
    var scanItems:[ScanItem]!
    var selectedItem: Int = 0
    
    @IBAction func unwindToThisScanViewController (sender: UIStoryboardSegue){}
    
    var dataForSensorsViewController = ["reseivedFirstNotifyData":"false", "real_temperature":"", "target_temperature":"", "operation_mode":"", "status_modules":"", "battery_charge":"", "voice":""]
    var dataState = ["state":"0"]
    let sampleGattAttributes = SampleGattAttributes()
    var reconecting: Bool = false
    var myTimer = Timer()
    var reseivedFirstNotifyData: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager()
        scanItems = [ScanItem]()
        NotificationCenter.default.addObserver(self, selector: #selector(readWriteToBLENotification), name: .notificationFromSensorsViewController, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        centralManager.delegate = self
//        fukeDeviceConnect()
    }


    // MARK: Запуск сканирования и подключения к выбранному устройству
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn
        {
            centralManager.scanForPeripherals(withServices: nil,
                                              options: nil)
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral:
        CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        guard let title = peripheral.name else { return }
        if (devicesMass.count == 0) {
            let newTodo = ScanItem(title: title, completed: false, createdAt: Date(), itemIdentifier: UUID())
            self.scanItems.append(newTodo)
            let indexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 0), section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            self.devicesMass.append(peripheral)
        }
        var find: Bool = false
        for myDevicesMass in devicesMass {
            if (myDevicesMass.name == title ) {
                find = true
            }
        }
        if (!find) {
            let newTodo = ScanItem(title: title, completed: false, createdAt: Date(), itemIdentifier: UUID())
            self.scanItems.append(newTodo)
            let indexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 0), section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            self.devicesMass.append(peripheral)
        }
        print("name: " + peripheral.name! + "    identifier: " + peripheral.identifier.uuidString)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("did DISConnect")
        self.dataState["state"] = "did DISConnect"
        NotificationCenter.default.post(name: .notificationCheckStateConnection, object: nil, userInfo: self.dataState)
        myTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
            print("did REConnect")
            self.centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("did FAILConnect")
        myTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
            print("did REConnect")
            self.centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral:
        CBPeripheral) {
        print("did Connect")
        self.dataState["state"] = "did Connect"
        NotificationCenter.default.post(name: .notificationCheckStateConnection, object: nil, userInfo: self.dataState)
        myTimer.invalidate()
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    
    //MARK: - работа с конкретным устройством
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error:
        Error?) {
//        print("did Discover Services")

        if let servicePeripherals = peripheral.services as [CBService]?
        {
            for service in servicePeripherals
            {
                self.servicesMass.append(service)
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor
        service: CBService, error: Error?) {
        if let characterArray = service.characteristics as [CBCharacteristic]?
        {
            for cc in characterArray
            {
                self.characteristicsMass.append(cc)
                peripheral.setNotifyValue(true, for: cc) // нотификация
            }
        }
    }


    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic:
        CBCharacteristic, error: Error?) {

        // Работа с характеристикой нотификации и чтения
        print ("Получили данные из характеристики: "+characteristic.uuid.uuidString)
        if (characteristic.uuid.uuidString == sampleGattAttributes.GET_REAL_TEMPERATURE) {
            print("Получили данные из характеристики GET_REAL_TEMPERATURE")
            if let data = characteristic.value {
                data.withUnsafeBytes({(bytes: UnsafePointer<UInt8>) -> Void in
                    self.dataForSensorsViewController["real_temperature"] = String(Int(bytes[0]))+" "+String(Int(bytes[1]))+" "+String(Int(bytes[2]))+" "+String(Int(bytes[3]))
                })
                
                NotificationCenter.default.post(name: .notificationReseiveBLEData, object: nil, userInfo: self.dataForSensorsViewController)
            }
        }
        if (characteristic.uuid.uuidString == sampleGattAttributes.SET_TARGET_TEMPERATURE) {
            print("Получили данные из характеристики SET_TARGET_TEMPERATURE")
            if let data = characteristic.value {
                data.withUnsafeBytes({(bytes: UnsafePointer<UInt8>) -> Void in
                    self.dataForSensorsViewController["target_temperature"] = String(Int(bytes[0]))+" "+String(Int(bytes[1]))+" "+String(Int(bytes[2]))+" "+String(Int(bytes[3]))
                })
                
                NotificationCenter.default.post(name: .notificationReseiveBLEData, object: nil, userInfo: self.dataForSensorsViewController)
            }
        }
        if (characteristic.uuid.uuidString == sampleGattAttributes.SET_OPERATION_MODE) {
            print("Получили данные из характеристики SET_OPERATION_MODE")
            if let data = characteristic.value {
                data.withUnsafeBytes({(bytes: UnsafePointer<UInt8>) -> Void in
                    self.dataForSensorsViewController["operation_mode"] = String(Int(bytes[0]))+" "+String(Int(bytes[1]))+" "+String(Int(bytes[2]))+" "+String(Int(bytes[3]))
                })
                
                NotificationCenter.default.post(name: .notificationReseiveBLEData, object: nil, userInfo: self.dataForSensorsViewController)
            }
        }
        if (characteristic.uuid.uuidString == sampleGattAttributes.GET_STATUS_MODULES) {
            print("Получили данные из характеристики GET_STATUS_MODULES")
//            if let data = characteristic.value {
//                data.withUnsafeBytes({(bytes: UnsafePointer<UInt8>) -> Void in
//                    self.dataForSensorsViewController["status_modules"] = String(Int(bytes[0]))+" "+String(Int(bytes[1]))+" "+String(Int(bytes[2]))+" "+String(Int(bytes[3]))
//                })
//
//                NotificationCenter.default.post(name: .notificationReseiveBLEData, object: nil, userInfo: self.dataForSensorsViewController)
//            }
        }
        if (characteristic.uuid.uuidString == sampleGattAttributes.GET_BATTERY_CHARGE_USE) {
            print("Получили данные из характеристики GET_BATTERY_CHARGE")
            if let data = characteristic.value {
                data.withUnsafeBytes({(bytes: UnsafePointer<UInt8>) -> Void in
                    self.dataForSensorsViewController["battery_charge"] = String(Int(bytes[0]))
                })
                
                NotificationCenter.default.post(name: .notificationReseiveBLEData, object: nil, userInfo: self.dataForSensorsViewController)
            }
        }
        if (characteristic.uuid.uuidString == sampleGattAttributes.SET_VOICE) {
            print("Получили данные из характеристики SET_VOICE")
            if let data = characteristic.value {
                data.withUnsafeBytes({(bytes: UnsafePointer<UInt8>) -> Void in
                    self.dataForSensorsViewController["voice"] = String(Int(bytes[0]))
                })
                
                NotificationCenter.default.post(name: .notificationReseiveBLEData, object: nil, userInfo: self.dataForSensorsViewController)
            }
        }
        if (characteristic.uuid.uuidString == sampleGattAttributes.GET_REAL_TEMPERATURE) {
//            print("Получили данные из характеристики 0001")
            if let data = characteristic.value {
                data.withUnsafeBytes({(bytes: UnsafePointer<UInt8>) -> Void in
                    print("Получили данные из характеристики 0001  "+String(Int(bytes[0])))
                })
            }
        }
    }

    
    // MARK: - работа с ячейками
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scanItems.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ToDoTableViewCell
        let scanItem = scanItems[indexPath.row]
        cell.scanLable.text = scanItem.title
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectDeviceToConnect(indexPath)
    }
    func selectDeviceToConnect(_ indexPath:IndexPath) {
        let scanItem = scanItems[indexPath.row]
        scanItems[indexPath.row] = scanItem
        centralManager.stopScan()
        myTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] (_) in
            print("did REConnect")
            centralManager.connect(devicesMass[indexPath.row], options: nil)
        }
        myDevice = devicesMass[indexPath.row]
        saveDataString(key: sampleGattAttributes.DEVICE_NAME, value: (myDevice?.name)!)
        performSegue(withIdentifier: "goSensorsSettings", sender: nil)
    }
    func fukeDeviceConnect() {
        saveDataString(key: sampleGattAttributes.DEVICE_NAME, value: "Test")
        performSegue(withIdentifier: "goSensorsSettings", sender: nil)
    }

    private func saveDataString(key: String, value: String) {
        let saveObjectString = SaveObjectString(key: key, value: value)
        print("save   key: \(key) value: \(value)")
        DataManager.save(saveObjectString, with: key)
    }
    // MARK: -  Передача информации при помощи нотификации
    @objc func readWriteToBLENotification(notification: Notification) {
        guard let sendMassage = notification.userInfo,
        let data = sendMassage["byteArray"] as? String,
        let characteristic = sendMassage["characteristic"] as? String,
        let type = sendMassage["type"] as? String else { return }
        for characteristics in characteristicsMass {
//        print("характеристика в списке: \(characteristics.uuid.uuidString)  а мы ищем: \(characteristic)")
            if (characteristics.uuid.uuidString == characteristic) {
//                print("попытались отправить данные type: \(type)")
                if (type == sampleGattAttributes.WRITE) {
                    myDevice?.writeValue(data.hexDecodedData(), for: characteristics, type: .withResponse) //запись
                    print("сюда записали: \(characteristics.uuid)   \(data) \(data.count))")
                }
                if (type == sampleGattAttributes.READ) {
                    myDevice?.readValue(for: characteristics) //чтение
                    print("от сюда прочитали: \(characteristics.uuid)")
                }
            }
        }
    }
}

extension Notification.Name {
    static let notificationFromSensorsViewController = Notification.Name(rawValue: "notificationFromSensorsViewController")
}

extension String {
    /// A data representation of the hexadecimal bytes in this string.
    func hexDecodedData() -> Data {
        // Get the UTF8 characters of this string
        let chars = Array(utf8)
        
        // Keep the bytes in an UInt8 array and later convert it to Data
        var bytes = [UInt8]()
        bytes.reserveCapacity(count / 2)
        
        // It is a lot faster to use a lookup map instead of strtoul
        let map: [UInt8] = [
            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, // 01234567
            0x08, 0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 89:;<=>?
            0x00, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x00, // @ABCDEFG
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  // HIJKLMNO
        ]
        
        // Grab two characters at a time, map them and turn it into a byte
        for i in stride(from: 0, to: count, by: 2) {
            let index1 = Int(chars[i] & 0x1F ^ 0x10)
            let index2 = Int(chars[i + 1] & 0x1F ^ 0x10)
            bytes.append(map[index1] << 4 | map[index2])
        }
        
        return Data(bytes)
    }
}
