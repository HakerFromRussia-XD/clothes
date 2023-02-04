//
//  testController.swift
//  MotoricaStart
//
//  Created by macbook on 14.04.2021.
//  Copyright © 2021 Brian Advent. All rights reserved.
//

import UIKit
import Charts


@objc class SensorsViewController: UIViewController {
    
    @IBOutlet weak var statusImage: UIImageView!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var breastStack: UIStackView!
    @IBOutlet weak var realValueBreast: UIButton!
    @IBOutlet weak var targetValueBreast: UIButton!
//    @IBOutlet weak var onOffButton: UIButton!
    @IBOutlet weak var onOffSwitchBreast: UISwitch!
    
    let connectStatus = UIImage(named:"connect_status")!
    let disconnectStatus = UIImage(named:"disconnect_status")!

    var firstInit: Bool = true


    var count: Int = 0
    var countTest: Int = 0
    static let sampleGattAttributes = SampleGattAttributes()
    static var dataForCommunicate = ["byteArray": "01020304", "characteristic":"1", "type":"READ", "case":"0"]
    private var savingParametrsMassString:[SaveObjectString]!
    private var startMoovSlide: Bool = true
    private var startValue: Float!
    private var swapButtonOpenClose: Bool = false
    static var flagReadData: Bool = true
    private var pauseReadData: Bool = true
    private var delayForReadData: UInt32 = 100000 //в микросекундах. Должно быть меньше, чем queueInterval. Чтобы не давать очереди
    static let queueInterval: UInt32 = 110000// большее количество команд, чем она отдаёт
    static let inactiveQueue = DispatchQueue(label: "My queue", attributes: [.concurrent, .initiallyInactive])
    static let semafore = DispatchSemaphore(value: 1)

 
    
    private var savingDeviceName: String = "...."
    
    deinit {
        print("SensorsViewController is being deinitialized")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.statusBarStyle = .lightContent
        
        loadDataString()
        initUI()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(updatingUINotification), name: .notificationReseiveBLEData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkStateConnection), name: .notificationCheckStateConnection, object: nil)
    }
    
    
    @objc func updateUI(notification: Notification) {
        guard let dataState = notification.userInfo,
              let resultDialog = dataState["resultDialog"] as? String
        else {
            print("selectScaleResult else return")
            return
        }
        if (resultDialog == "selectScaleAccept") {
            performSegue(withIdentifier: "showSceleAcceptVC", sender: nil)
        }
        if (resultDialog == "acceptSelectScaleCancel") {
            performSegue(withIdentifier: "showSelectScaleVC", sender: nil)
        }
        if (resultDialog == "acceptSelectScaleAccept") {
            //отправка команды с размером протеза
            loadDataString()
            for item in savingParametrsMassString
            {
                if (item.key == SensorsViewController.sampleGattAttributes.SCALE) {
                    let scale: UInt8 = UInt8(item.value) ?? 0x04
                    let data = Data([scale])
                }
            }
        }
    }
    @objc func updatingUINotification(notification: Notification) {
        guard let dataForWrite = notification.userInfo,
            let set_one_channel = dataForWrite["set_one_channel"] as? String,
            let gesture_use_num = dataForWrite["gesture_use_num"] as? String,
            let gesture_switching_by_sensors = dataForWrite["gesture_switching_by_sensors"] as? String,
            let time_at_rest = dataForWrite["time_at_rest"] as? String,
            let reseivedFirstNotifyData = dataForWrite["reseivedFirstNotifyData"] as? String
        else { return }

        
        for item in savingParametrsMassString
        {
            if (item.key == SensorsViewController.sampleGattAttributes.SET_ONE_CHANNEL_NEW) {
                if (Int(item.value) != Int(set_one_channel)) {
                    print("обновили данные одноканального управления")
                    saveDataString(key: item.key, value: String(Int(set_one_channel)!))
                    loadDataString()
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.GESTURE_USE_NUM) {
                if (Int(item.value) != Int(gesture_use_num)) {
                    print("обновили данные активного жеста")
                    saveDataString(key: item.key, value: String(Int(gesture_use_num)!))
                    loadDataString()
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SWITCH_BY_SENSORS) {
                if (Int(item.value) != Int(gesture_switching_by_sensors)) {
                    print("Int(item.value)=\(String(describing: Int(item.value)))   Int(gesture_switching_by_sensors)=\(String(describing: Int(gesture_switching_by_sensors)))")
                    print("обновили данные переключения жестов датчиками (включение/отключение режима)")
                    saveDataString(key: item.key, value: String(Int(gesture_switching_by_sensors)!))
                    loadDataString()
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.TIME_AT_REST) {
                if (Int(item.value) != Int(time_at_rest)) {
                    print("обновили данные переключения жестов датчиками (время зажима датчика открытия)")
                    saveDataString(key: item.key, value: String(Int(time_at_rest)!))
                    loadDataString()
                }
            }
        }
    }
    @objc func checkStateConnection(notification: Notification) {
        guard let dataState = notification.userInfo,
            let state = dataState["state"] as? String
        else { return }
        print("peredan state: \(state)")
        if (state == "did Connect") {
            statusImage.image = connectStatus
            saveDataString(key: SensorsViewController.sampleGattAttributes.STATUS_CONNECTION, value: String(1))
        }
        if (state == "did DISConnect") {
            statusImage.image = disconnectStatus
            saveDataString(key: SensorsViewController.sampleGattAttributes.STATUS_CONNECTION, value: String(0))
        }
    }

    
    // MARK: - обработка взаимодействия с UI
    
    
    // MARK: - работа с фоном
    override func viewDidLayoutSubviews() {}
    // MARK: - UI stule
    private func setupeButton (button: UIButton) {
        button.layer.cornerRadius = 15
        button.titleLabel?.text = "100"
        button.titleLabel?.font =  UIFont(name: "OpenSans-Bold", size: 12)
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.black.cgColor
    }
    private func setupeSwitch (mySwitch: UISwitch) {
        mySwitch.layer.cornerRadius = 15
        mySwitch.layer.borderWidth = 2
        mySwitch.layer.borderColor = UIColor.black.cgColor
    }
    private func setupeStakeView (stack: UIStackView) {
        stack.layer.cornerRadius = 21
        stack.layer.borderWidth = 2
        stack.layer.borderColor = UIColor.black.cgColor
    }
    // MARK: -
    private func initUI() {
        setupeButton(button: realValueBreast)
        setupeButton(button: targetValueBreast)
//        setupeSwitch(mySwitch: onOffSwitch)
        setupeStakeView (stack: breastStack)
        for item in savingParametrsMassString
        {
            if (item.key == SensorsViewController.sampleGattAttributes.DEVICE_NAME){
            if (savingDeviceName != item.value) {
                deviceName.text = item.value
                savingDeviceName = item.value
                deviceName.text = savingDeviceName
                if ( savingDeviceName == "FEST-A" || savingDeviceName == "BT05" || savingDeviceName == "Redmi" ||
                        savingDeviceName == "FEST-F" || savingDeviceName == SensorsViewController.sampleGattAttributes.FESTH_NAME || savingDeviceName == SensorsViewController.sampleGattAttributes.FESTX_NAME) {
                    if (savingDeviceName == SensorsViewController.sampleGattAttributes.FESTX_NAME) {
                        print("FEST-X activated")
                        saveDataString(key: SensorsViewController.sampleGattAttributes.USE_MULTIGRAB_FESTX, value: String(1))
                    }
                    if (savingDeviceName == SensorsViewController.sampleGattAttributes.FESTH_NAME) {
                        saveDataString(key: SensorsViewController.sampleGattAttributes.USE_MULTIGRAB_FESTH, value: String(1))
                    }
                    saveDataString(key: SensorsViewController.sampleGattAttributes.USE_MULTIGRAB, value: SensorsViewController.sampleGattAttributes.USE)
                    print("Multigrib mode activated!")
                } else {
                    saveDataString(key: SensorsViewController.sampleGattAttributes.USE_MULTIGRAB, value: String(0))
                }
            }
        }
        }
    }
    
    private func loadDataString() {
        savingParametrsMassString = [SaveObjectString]()
        savingParametrsMassString = DataManager.loadAll(SaveObjectString.self)
//        for item in savingParametrsMassString {
//            print("load   key: \(item.key) value: \(item.value)")
//        }
    }
    private func saveDataString(key: String, value: String) {
        let saveObjectString = SaveObjectString(key: key, value: value)
        print("save   key: \(key) value: \(value)")
        DataManager.save(saveObjectString, with: key)
    }
    
    
    // MARK: - очередь команд
    @objc static func myInteractiveQueueComand(dataForWrite: Data, characteristic: String, type: String, myCase: String) {
        inactiveQueue.async {
            self.semafore.wait()
            self.flagReadData = false
            self.comandQueue(dataForWrite: dataForWrite, characteristic: characteristic, type: type, myCase: myCase)
            self.semafore.signal()
        }
        inactiveQueue.activate()
    }
    // MARK:  функция при вызове начинает генерировать команды
    // MARK:  на чтение данных и дбавлять их в очередь команд
    func myInteractiveQueueReadData(dataForWrite: Data, characteristic: String, type: String, myCase: String) {
        SensorsViewController.inactiveQueue.async { [self] in
            while (SensorsViewController.flagReadData && pauseReadData) {
                usleep(delayForReadData)
            }
        }
        SensorsViewController.inactiveQueue.activate()
    }
    static let operationQueue = OperationQueue()
    static func comandQueue(dataForWrite: Data, characteristic: String, type: String, myCase: String) {
        let operation1 = BlockOperation() { [self] in
            usleep(queueInterval)
            //TODO код запроса информационных данных
            if (type == sampleGattAttributes.WRITE) {
                
            } else if (type == sampleGattAttributes.READ) {
                print("read")
            }
        }
        operation1.completionBlock = { [self] in
            if (!flagReadData) {
                flagReadData = true
            }
        }
        operationQueue.addOperations([operation1], waitUntilFinished: true)
    }
}

extension Notification.Name {
    static let notificationReseiveBLEData = Notification.Name(rawValue: "notificationReseiveBLEData")
}

extension Notification.Name {
    static let notificationCheckStateConnection = Notification.Name(rawValue: "notificationCheckStateConnection")
}


extension Data {
    /// A hexadecimal string representation of the bytes.
    func hexEncodedString() -> String {
        let hexDigits = Array("0123456789abcdef".utf16)
        var hexChars = [UTF16.CodeUnit]()
        hexChars.reserveCapacity(count * 2)
        
        for byte in self {
            let (index1, index2) = Int(byte).quotientAndRemainder(dividingBy: 16)
            hexChars.append(hexDigits[index1])
            hexChars.append(hexDigits[index2])
        }
        
        return String(utf16CodeUnits: hexChars, count: hexChars.count)
    }
}

