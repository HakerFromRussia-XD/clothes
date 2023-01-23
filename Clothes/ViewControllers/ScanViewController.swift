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
    
    var sensor_1_data: Int?
    var sensor_2_data: Int = 2
    
    @IBAction func unwindToThisScanViewController (sender: UIStoryboardSegue){}
    
    var dataForSensorsViewController = ["numderBytes": "0", "sens_1": "123", "sens_2": "124", "driver_num": "0", "bms_num": "0", "sens_num": "0", "open_ch_num": "0", "close_ch_num": "0", "corellator_noise_threshold_1_num": "0", "set_reverse":"0", "set_one_channel":"0", "add_gesture":"0", "corellator_noise_threshold_2_num": "0", "deviceName":"lol", "reseivedFirstNotifyData":"false", "gesture_use_num":"0", "gesture_switching_by_sensors":"0", "time_at_rest":"15","expected_id_command":"FFF0", "shutdown_current_num":"0", "scale_flags_and_revers_and_one_channel":"0"]
    var dataForDelayFingersViewController = ["":""]
    var dataForCalibrationStatusViewController = ["":""]
    var dataState = ["state":"0"]
    let sampleGattAttributes = SampleGattAttributes()
    var reconecting: Bool = false
    var myTimer = Timer()
    var reseivedFirstNotifyData: Bool = false
    @objc var gestureTable = [[[Int]]] (repeating: [[0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0]] , count: 7)
    @objc var byteEnabledGesture: Int = 0
    @objc var byteActiveGesture: Int = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager()
        scanItems = [ScanItem]()
        NotificationCenter.default.addObserver(self, selector: #selector(readWriteToBLENotification), name: .notificationFromSensorsViewController, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        centralManager.delegate = self
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

        guard var title = peripheral.name else { return }
        if (peripheral.name == "HRSTM") {
            title = "INDY"
//            print("смена имени   name: " + title)
        } else {
            title = peripheral.name!
//            print("смена имени   name: " + title)
        }
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
        if let data = characteristic.value {
            data.withUnsafeBytes(
                {(bytes: UnsafePointer<UInt8>) -> Void in
                    
                    if (myDevice?.name != sampleGattAttributes.FESTH_NAME && myDevice?.name != sampleGattAttributes.FESTX_NAME){
                        if (bytes[3] == 0 && bytes[4] == 0 && bytes[5] == 0 && bytes[6] == 0 && bytes[7] == 0 && bytes[8] == 0 && bytes[9] == 0) {
                            self.dataForSensorsViewController["numderBytes"] = String(Int(3))
                        } else {
                            self.dataForSensorsViewController["numderBytes"] = String(Int(12))
                            self.dataForSensorsViewController["driver_num"] = String(Int(bytes[3]))
                            self.dataForSensorsViewController["bms_num"] = String(Int(bytes[4]))
                            self.dataForSensorsViewController["sens_num"] = String(Int(bytes[5]))
                            self.dataForSensorsViewController["open_ch_num"] = String(Int(bytes[6]))
                            self.dataForSensorsViewController["close_ch_num"] = String(Int(bytes[7]))
                            self.dataForSensorsViewController["corellator_noise_threshold_1_num"] = String(Int(bytes[8]))
                            self.dataForSensorsViewController["corellator_noise_threshold_2_num"] = String(Int(bytes[9]))
                            self.dataForSensorsViewController["shutdown_current_num"] = String(Int(bytes[10]))
                            self.dataForSensorsViewController["scale_flags_and_revers_and_one_channel"] = String(Int(bytes[11]))
                        }
                    }
                    

                    if (myDevice?.name == sampleGattAttributes.FESTH_NAME){
                        if (characteristic.uuid.uuidString == sampleGattAttributes.MIO_MEASUREMENT_NEW) {
                            self.dataForSensorsViewController["sens_1"] = String(Int(bytes[0]))
                            self.dataForSensorsViewController["sens_2"] = String(Int(bytes[1]))
                            if (!reseivedFirstNotifyData) {
                                self.dataForSensorsViewController["reseivedFirstNotifyData"] = "true"
                                reseivedFirstNotifyData = true
                                print("Первое получение нотификации")
                            }
                        }
                        if (characteristic.uuid.uuidString == sampleGattAttributes.SENS_VERSION_NEW) {
                            print ("Получили данные из характеристики SENS_VERSION_NEW: "+String(Int(bytes[0])))
                            self.dataForSensorsViewController["numderBytes"] = String(Int(10))
                            self.dataForSensorsViewController["sens_num"] = String(Int(bytes[0]))
                            self.dataForSensorsViewController["bms_num"] = String(100)
                        }
                        if (characteristic.uuid.uuidString == sampleGattAttributes.DRIVER_VERSION_NEW) {
                            var temp = 0
                            temp = (Int(bytes[1]) - 48)*100 + (Int(bytes[3]) - 48)*10 + (Int(bytes[4]) - 48)
                            self.dataForSensorsViewController["driver_num"] = String(temp)
                            print ("Получили данные из характеристики DRIVER_VERSION_NEW: "+String(temp))

                        }
                        if (characteristic.uuid.uuidString == sampleGattAttributes.OPEN_THRESHOLD_NEW) {
                            self.dataForSensorsViewController["open_ch_num"] = String(Int(bytes[0]))
                            print ("Получили данные из характеристики OPEN_THRESHOLD_NEW: "+String(Int(bytes[0])))
                        }
                        if (characteristic.uuid.uuidString == sampleGattAttributes.CLOSE_THRESHOLD_NEW) {
                            self.dataForSensorsViewController["close_ch_num"] = String(Int(bytes[0]))
                            print ("Получили данные из характеристики CLOSE_THRESHOLD_NEW: "+String(Int(bytes[0])))
                        }
                        if (characteristic.uuid.uuidString == sampleGattAttributes.SENS_OPTIONS_NEW) {
                            self.dataForSensorsViewController["corellator_noise_threshold_1_num"] = String(Int(bytes[0]))
                            self.dataForSensorsViewController["corellator_noise_threshold_2_num"] = String(Int(bytes[13]))
                            print ("Получили данные из характеристики SENS_OPTIONS_NEW: "+String(Int(bytes[0])))
                        }
                        if (characteristic.uuid.uuidString == sampleGattAttributes.SET_REVERSE_NEW) {
                            self.dataForSensorsViewController["set_reverse"] = String(Int(bytes[0]))
                            print ("Получили данные из характеристики SET_REVERSE_NEW: "+String(Int(bytes[0])))
                        }
                        if (characteristic.uuid.uuidString == sampleGattAttributes.SET_ONE_CHANNEL_NEW) {
                            self.dataForSensorsViewController["set_one_channel"] = String(Int(bytes[0]))
                            print ("Получили данные из характеристики SET_ONE_CHANNEL_NEW: "+String(Int(bytes[0])))
                        }
                        if (characteristic.uuid.uuidString == sampleGattAttributes.ADD_GESTURE_NEW) {
                            var data: String = ""
                            for i in 0...86 {
                                data += String(Int(bytes[i]))+" "
                            }
                            saveDataString(key: sampleGattAttributes.ADD_GESTURE_NEW, value: data)
                            self.dataForSensorsViewController["add_gesture"] = data
                            for i in 0...6 {
                                for j in 0...1 {
                                    for k in 0...5 {
                                        gestureTable[i][j][k] = Int(bytes[i*12 + j*6 + k])
                                        if(k == 4) { gestureTable[i][j][k] = Int(bytes[i * 12 + j * 6 + k]) }
                                        if(k == 5) { gestureTable[i][j][k] = Int(bytes[i * 12 + j * 6 + k]) }
                                    }
                                }
                            }
                            byteEnabledGesture = Int(bytes[84])
                            byteActiveGesture = Int(bytes[85])
                            print ("Получили данные из характеристики ADD_GESTURE_NEW: "+data)
                        }
                        if (characteristic.uuid.uuidString == sampleGattAttributes.CALIBRATION_NEW) {
                            print ("Получили данные из характеристики CALIBRATION_NEW: ")
                        }
                        if (characteristic.uuid.uuidString == sampleGattAttributes.SHUTDOWN_CURRENT_NEW) {
                            for i in 0...5 {
                                saveDataString(key: "SHUTDOWN_CURRENT_NEW_"+String(i+1), value: String(Int(bytes[i])))
                            }
                            print ("Получили данные из характеристики SHUTDOWN_CURRENT_NEW: ")
                        }
                        if (characteristic.uuid.uuidString == sampleGattAttributes.SET_GESTURE_NEW) {
                            print ("Получили данные из характеристики SET_GESTURE_NEW: ")
                        }
                    } else {
                        if (myDevice?.name == sampleGattAttributes.FESTX_NAME) {
//                            print("Получение данных от FEST-X с характеристики: " + characteristic.uuid.uuidString)
                            if (characteristic.uuid.uuidString == sampleGattAttributes.MIO_MEASUREMENT_NEW_VM) {
                                self.dataForSensorsViewController["sens_1"] = String(Int(bytes[0]))
                                self.dataForSensorsViewController["sens_2"] = String(Int(bytes[1]))
                                self.dataForSensorsViewController["gesture_use_num"] = String(Int(bytes[2])+1)
                                
//                                if (bytes[10] != 0 && bytes[11] != 0) {
//                                    print("Команда пришедшая в ответ: " + String(format: "%02X", bytes[11]) + String(format: "%02X", bytes[10]))
                                    self.dataForSensorsViewController["expected_id_command"] = String(format: "%02X", bytes[11]) + String(format: "%02X", bytes[10])
//                                }
                                if (!reseivedFirstNotifyData) {
                                    self.dataForSensorsViewController["reseivedFirstNotifyData"] = "true"
                                    reseivedFirstNotifyData = true
                                    print("Первое получение нотификации ")
                                }
                            }
                            if (characteristic.uuid.uuidString == sampleGattAttributes.SENS_VERSION_NEW_VM) {
                                print ("Получили данные из характеристики SENS_VERSION_NEW_VM: "+String(Int(bytes[0])))
                                self.dataForSensorsViewController["numderBytes"] = String(Int(10))
                                self.dataForSensorsViewController["sens_num"] = String(Int(bytes[0]))
                                self.dataForSensorsViewController["bms_num"] = String(100)
                            }
                            if (characteristic.uuid.uuidString == sampleGattAttributes.DRIVER_VERSION_NEW) {
                                var temp = 0
                                temp = (Int(bytes[1]) - 48)*100 + (Int(bytes[3]) - 48)*10 + (Int(bytes[4]) - 48)
                                self.dataForSensorsViewController["driver_num"] = String(temp)
                                print ("Получили данные из характеристики DRIVER_VERSION_NEW: "+String(temp))
                            }
                            if (characteristic.uuid.uuidString == sampleGattAttributes.DRIVER_VERSION_NEW_VM) {
                                var temp = 0
                                temp = (Int(bytes[1]) - 48)*100 + (Int(bytes[3]) - 48)*10 + (Int(bytes[4]) - 48)
                                self.dataForSensorsViewController["driver_num"] = String(temp)
                                print ("Получили данные из характеристики DRIVER_VERSION_NEW_VM: "+String(temp))
                            }
                            if (characteristic.uuid.uuidString == sampleGattAttributes.OPEN_THRESHOLD_NEW_VM) {
                                self.dataForSensorsViewController["open_ch_num"] = String(Int(bytes[0]))
                                print ("Получили данные из характеристики OPEN_THRESHOLD_NEW: "+String(Int(bytes[0])))
                            }
                            if (characteristic.uuid.uuidString == sampleGattAttributes.CLOSE_THRESHOLD_NEW_VM) {
                                self.dataForSensorsViewController["close_ch_num"] = String(Int(bytes[0]))
                                print ("Получили данные из характеристики CLOSE_THRESHOLD_NEW: "+String(Int(bytes[0])))
                            }
                            if (characteristic.uuid.uuidString == sampleGattAttributes.SENS_OPTIONS_NEW_VM) {
                                self.dataForSensorsViewController["corellator_noise_threshold_1_num"] = String(Int(bytes[0]))
                                self.dataForSensorsViewController["corellator_noise_threshold_2_num"] = String(Int(bytes[13]))
                                print ("Получили данные из характеристики SENS_OPTIONS_NEW: "+String(Int(bytes[0])))
                            }
                            if (characteristic.uuid.uuidString == sampleGattAttributes.SET_REVERSE_NEW_VM) {
                                self.dataForSensorsViewController["set_reverse"] = String(Int(bytes[0]))
                                print ("Получили данные из характеристики SET_REVERSE_NEW: "+String(Int(bytes[0])))
                            }
                            if (characteristic.uuid.uuidString == sampleGattAttributes.SET_ONE_CHANNEL_NEW_VM) {
                                self.dataForSensorsViewController["set_one_channel"] = String(Int(bytes[0]))
                                print ("Получили данные из характеристики SET_ONE_CHANNEL_NEW: "+String(Int(bytes[0])))
                            }
                            if (characteristic.uuid.uuidString == sampleGattAttributes.ADD_GESTURE_NEW_VM) {
                                var data: String = ""
                                for i in 0...86 {
                                    data += String(Int(bytes[i]))+" "
                                }
                                saveDataString(key: sampleGattAttributes.ADD_GESTURE_NEW, value: data)
                                self.dataForSensorsViewController["add_gesture"] = data
                                for i in 0...6 {
                                    for j in 0...1 {
                                        for k in 0...5 {
                                            gestureTable[i][j][k] = Int(bytes[i*12 + j*6 + k])
                                            if(k == 4) { gestureTable[i][j][k] = Int(bytes[i * 12 + j * 6 + k]) }
                                            if(k == 5) { gestureTable[i][j][k] = Int(bytes[i * 12 + j * 6 + k]) }
                                        }
                                    }
                                }
                                byteEnabledGesture = Int(bytes[84])
//                                saveDataString(key: sampleGattAttributes.GESTURE_USE_NUM, value: String(Int(bytes[85])))
                                print ("Получили данные из характеристики ADD_GESTURE_NEW: "+data)
                            }
                            if (characteristic.uuid.uuidString == sampleGattAttributes.CALIBRATION_NEW_VM) {
                                print ("Получили данные из характеристики CALIBRATION_NEW: ")
                            }
                            if (characteristic.uuid.uuidString == sampleGattAttributes.SHUTDOWN_CURRENT_NEW_VM) {
                                for i in 0...5 {
                                    saveDataString(key: "SHUTDOWN_CURRENT_NEW_"+String(i+1), value: String(Int(bytes[i])))
                                }
                                print ("Получили данные из характеристики SHUTDOWN_CURRENT_NEW: ")
                            }
                            if (characteristic.uuid.uuidString == sampleGattAttributes.SET_GESTURE_NEW_VM) {
                                print ("Получили данные из характеристики SET_GESTURE_NEW: ")
                            }
                            if (characteristic.uuid.uuidString == sampleGattAttributes.ROTATION_GESTURE_NEW_VM) {
                                self.dataForSensorsViewController["gesture_switching_by_sensors"] = String(Int(bytes[0]))
                                self.dataForSensorsViewController["time_at_rest"] = String(Int(bytes[2]))
                                print ("Получили данные из характеристики ROTATION_GESTURE_NEW_VM: gesture_switching_by_sensors=\(Int(bytes[0])) time_at_rest=\(Int(bytes[2]))")
                            }
                            if (characteristic.uuid.uuidString == sampleGattAttributes.CHANGE_GESTURE_NEW_VM) {
                                print ("Получили данные из характеристики CHANGE_GESTURE_NEW_VM ")
                                for i in 13...18 {
                                    saveDataString(key: "GESTURE_OPEN_DELAY_FINGER"+String(i-12), value: String(Int(bytes[i])))
                                }
                                for i in 19...24 {
                                    saveDataString(key: "GESTURE_CLOSE_DELAY_FINGER"+String(i-18), value: String(Int(bytes[i])))
                                }
                                NotificationCenter.default.post(name: .notificationReseiveBLEDataDelay, object: nil, userInfo: self.dataForDelayFingersViewController)
                            }
                            if (characteristic.uuid.uuidString == sampleGattAttributes.STATUS_CALIBRATION_NEW_VM) {
                                var chislo: Int = 5
                                chislo = chislo << 8
                                print ("Получили данные из характеристики STATUS_CALIBRATION_NEW_VM \(chislo)")
                                
                                
                                for i in 0...5 {
                                    var temp: String = ""
                                    if (Int(bytes[36+i]) == 6) { temp = "calibrated" }
                                    if (Int(bytes[36+i]) == 5) { temp = "screw pulled" }
                                    if (Int(bytes[36+i]) == 4) { temp = "motor scrolls" }
                                    if (Int(bytes[36+i]) == 3) { temp = "there is no encoder" }
                                    if (Int(bytes[36+i]) == 2) { temp = "there is no motor" }
                                    if (Int(bytes[36+i]) == 1) { temp = "calibration in progress" }
                                    if (Int(bytes[36+i]) == 0) { temp = "not calibrated" }
                                    saveDataString(key: "CALIBRATION_STATUS_FINGER"+String(i+1), value: String(temp))
                                }
                                for i in 0...5 {
                                    let temp = Int(bytes[(i*4)]) +
                                               (Int(bytes[1+(i*4)]) << 8) +
                                               (Int(bytes[2+(i*4)]) << 16) +
                                               (Int(bytes[3+(i*4)]) << 24)
                                    saveDataString(key: "CALIBRATION_STATUS_ENCODER_FINGER"+String(i+1), value: String(temp))
                                }
                                for i in 0...5 {
                                    let temp = Int(bytes[24+(i*2)]) +
                                               (Int(bytes[25+(i*2)]) << 8)
                                    saveDataString(key: "CALIBRATION_STATUS_CURRENT_FINGER"+String(i+1), value: String(temp))
                                }
                                NotificationCenter.default.post(name: .notificationReseiveBLEDataCalibrationStatus, object: nil, userInfo: self.dataForCalibrationStatusViewController)
                            }
                        } else {
                            self.dataForSensorsViewController["sens_1"] = String(Int(bytes[1]))
                            self.dataForSensorsViewController["sens_2"] = String(Int(bytes[2]))
                        }
                    }
                    //исправление бага с именем HRSTM прилетающем от Родиона вместо INDY
                    if (myDevice?.name == "HRSTM") {
                        self.dataForSensorsViewController["deviceName"] = "INDY"
                    } else {
                        self.dataForSensorsViewController["deviceName"] = myDevice?.name
                    }
                    NotificationCenter.default.post(name: .notificationReseiveBLEData, object: nil, userInfo: self.dataForSensorsViewController)
            })
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
//        print("PODKLUCHAEMSIA!! name: " + devicesMass[indexPath.row].name! + "    identifier: " + devicesMass[indexPath.row].identifier.uuidString)
        myDevice = devicesMass[indexPath.row]
        if (myDevice?.name == "HRSTM") {
            saveDataString(key: sampleGattAttributes.DEVICE_NAME, value: "INDY")
        } else {
            saveDataString(key: sampleGattAttributes.DEVICE_NAME, value: (myDevice?.name)!)
        }
        performSegue(withIdentifier: "goSensorsSettings", sender: nil)
    }
    @IBAction func tupTestButton(_ sender: UIButton) {
        print("tup test button")
//        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "TestViewController") as? TestViewController
//        vc?.modalPresentationStyle = .fullScreen
//
//        
//        self.present(vc!, animated: true, completion: nil)
//        let vc = TestViewController()
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
        let type = sendMassage["type"] as? String,
        let myCase = sendMassage["case"] as? String else { return }
//        print("readDataFromFestX 2 characteristic:\(characteristic)    type: \(type)")
//        print("sendDataToFestX 2 characteristic:\(characteristic)  type: \(type)")
        for characteristics in characteristicsMass {
//        print("характеристика в списке: \(characteristics.uuid.uuidString)  а мы ищем: \(characteristic)")
            if (characteristics.uuid.uuidString == characteristic) {
//                print("попытались отправить данные type: \(type)")
                if (type == sampleGattAttributes.WRITE_HC10) {
                    let preambul = Data([0xAA, 0xAA])
                    let length = Data([UInt8(data.hexDecodedData().count + 2)])
                    let numberComand = Data([UInt8(Int(myCase)!)])
                    let forCalcCrc = preambul + length + numberComand + data.hexDecodedData()
                    let finalMassage = forCalcCrc + Data([crcCalc(data: forCalcCrc)])
                    
                    myDevice?.writeValue(finalMassage, for: characteristics, type: .withoutResponse)
                    print("посылка для HC10")
                }
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

    func crcCalc(data: Data) -> UInt8 {
        var countLocal = data.count
        let crcTable = [UInt8](
            arrayLiteral: 0, 94, 188, 226, 97, 63, 221, 131, 194, 156, 126, 32, 163, 253, 31, 65,
               157, 195, 33, 127, 252, 162, 64, 30, 95, 1, 227, 189, 62, 96, 130, 220,
               35, 125, 159, 193, 66, 28, 254, 160, 225, 191, 93, 3, 128, 222, 60, 98,
               190, 224, 2, 92, 223, 129, 99, 61, 124, 34, 192, 158, 29, 67, 161, 255,
               70, 24, 250, 164, 39, 121, 155, 197, 132, 218, 56, 102, 229, 187, 89, 7,
               219, 133, 103, 57, 186, 228, 6, 88, 25, 71, 165, 251, 120, 38, 196, 154,
               101, 59, 217, 135, 4, 90, 184, 230, 167, 249, 27, 69, 198, 152, 122, 36,
               248, 166, 68, 26, 153, 199, 37, 123, 58, 100, 134, 216, 91, 5, 231, 185,
               140, 210, 48, 110, 237, 179, 81, 15, 78, 16, 242, 172, 47, 113, 147, 205,
               17, 79, 173, 243, 112, 46, 204, 146, 211, 141, 111, 49, 178, 236, 14, 80,
               175, 241, 19, 77, 206, 144, 114, 44, 109, 51, 209, 143, 12, 82, 176, 238,
               50, 108, 142, 208, 83, 13, 239, 177, 240, 174, 76, 18, 145, 207, 45, 115,
               202, 148, 118, 40, 171, 245, 23, 73, 8, 86, 180, 234, 105, 55, 213, 139,
               87, 9, 235, 181, 54, 104, 138, 212, 149, 203, 41, 119, 244, 170, 72, 22,
               233, 183, 85, 11, 136, 214, 52, 106, 43, 117, 151, 201, 74, 20, 246, 168,
               116, 42, 200, 150, 21, 75, 169, 247, 182, 232, 10, 84, 215, 137, 107, 53
           )
        var result: UInt8 = 0
        var i = 0
        while (countLocal != 0 ) {
            result = crcTable[Int(result ^ data[i])]
            i += 1
            countLocal -= 1
        }
        return result
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
