//
//  Gesture Settings View Controller.swift
//  MotoricaStart
//
//  Created by Motorica LLC on 29.06.2021.
//  Copyright © 2021 Brian Advent. All rights reserved.
//

import UIKit
            
@objc class GestureSettingsViewController: UIViewController {
    @IBOutlet var conteinerView: UIView!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var statusImage: UIImageView!
    @IBOutlet weak var gesture1: UIButton!
    @IBOutlet weak var gesture2: UIButton!
    @IBOutlet weak var gesture3: UIButton!
    @IBOutlet weak var gesture4: UIButton!
    @IBOutlet weak var gesture5: UIButton!
    @IBOutlet weak var gesture6: UIButton!
    @IBOutlet weak var gesture7: UIButton!
    @IBOutlet weak var gesture8: UIButton!
    @IBOutlet weak var gesture2settings: UIButton!
    @IBOutlet weak var gesture3settings: UIButton!
    @IBOutlet weak var gesture4settings: UIButton!
    @IBOutlet weak var gesture5settings: UIButton!
    @IBOutlet weak var gesture6settings: UIButton!
    @IBOutlet weak var gesture7settings: UIButton!
    @IBOutlet weak var gesture8settings: UIButton!
    
    @IBAction func unwindToThisGestureViewController (sender: UIStoryboardSegue){
//        loadData()
    }
    private let sampleGattAttributes = SampleGattAttributes()
//    private let sensorsVC = SensorsViewController()
    private var savingParametrsMassString:[SaveObjectString]!
    private var dataForAdvancedSettingsViewController = ["deviceName":"lol"]
    @objc public var savingDeviceName: String = "...."
    let settingsDefault = UIImage(named:"settings")!
    let settingsActive = UIImage(named:"settings_active")!
    private var dataForCommunicate = ["byteArray": "01020304", "characteristic":"1", "type":"READ", "case":"0"]
    let connectStatus = UIImage(named:"connect_status")!
    let disconnectStatus = UIImage(named:"disconnect_status")!
    private var typeMultigribNew: Bool = false
    private var typeMultigribNewVM: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadDataString()
        initUI()
        NotificationCenter.default.addObserver(self, selector: #selector(checkStateConnection), name: .notificationCheckStateConnection, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatingUINotification), name: .notificationReseiveBLEData, object: nil)
    }
    
    @objc private func checkStateConnection(notification: Notification) {
        guard let dataState = notification.userInfo,
            let state = dataState["state"] as? String
        else { return }
        print("peredan state: \(state)")
        if (state == "did Connect") {
            statusImage.image = connectStatus
        }
        if (state == "did DISConnect") {
            statusImage.image = disconnectStatus
        }
    }
    

    
    // MARK: - обработка взаимодействия с UI
    @IBAction func goToGripperSettings(_ sender: UIButton) {
        switch sender {
            case gesture2settings:
                saveDataString(key: sampleGattAttributes.GESTURE_EDITING_NUM, value: String(2))
            case gesture3settings:
                saveDataString(key: sampleGattAttributes.GESTURE_EDITING_NUM, value: String(3))
            case gesture4settings:
                saveDataString(key: sampleGattAttributes.GESTURE_EDITING_NUM, value: String(4))
            case gesture5settings:
                saveDataString(key: sampleGattAttributes.GESTURE_EDITING_NUM, value: String(5))
            case gesture6settings:
                saveDataString(key: sampleGattAttributes.GESTURE_EDITING_NUM, value: String(6))
            case gesture7settings:
                saveDataString(key: sampleGattAttributes.GESTURE_EDITING_NUM, value: String(7))
            case gesture8settings:
                saveDataString(key: sampleGattAttributes.GESTURE_EDITING_NUM, value: String(8))
            default:
                saveDataString(key: sampleGattAttributes.GESTURE_EDITING_NUM, value: String(1))
        }
        if (deviceName.text == sampleGattAttributes.FESTH_NAME || deviceName.text == sampleGattAttributes.FESTX_NAME) {
            print("правда deviceName.text: ", deviceName.text ?? 0)
            // останавливаем работу протеза от датчиков
            if (typeMultigribNew) {
                SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([0x00]), characteristic: sampleGattAttributes.SENS_ENABLED_NEW, type: sampleGattAttributes.WRITE, myCase: "") }
            if (typeMultigribNewVM) {
                SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x00]), characteristic: sampleGattAttributes.SENS_ENABLED_NEW_VM, countRestart: 50)
            }
            performSegue(withIdentifier: "go3DGripperSettings", sender: nil)
        } else {
            print("ложь deviceName.text: ", deviceName.text!)
            performSegue(withIdentifier: "goGripperSettings", sender: nil)
        }
        
    }
    @IBAction func perehod(_ sender: Any) {
        saveDataString(key: sampleGattAttributes.READ_THREAD_START, value: String(1))
    }
    @IBAction func selectGesture(_ sender: UIButton) {
        
        switch sender {
            case gesture1:
//                    setupeButtonActiveWithoutSettings(button: gesture1)
                if (typeMultigribNewVM) {
                    SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x00]), characteristic: sampleGattAttributes.SET_GESTURE_NEW_VM, countRestart: 50)
                } else {
                    if (typeMultigribNew) {
                        SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([0x00]), characteristic: sampleGattAttributes.SET_GESTURE_NEW, type: sampleGattAttributes.WRITE, myCase: "")
                    } else {
                        sendDataToHC10(dataForWrite: Data([0x00]), characteristic: sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(13))
                    }
                }
                saveDataString(key: sampleGattAttributes.GESTURE_USE_NUM, value: String(1))
            case gesture2:
                if (typeMultigribNewVM) {
                    SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x01]), characteristic: sampleGattAttributes.SET_GESTURE_NEW_VM, countRestart: 50)
                } else {
                    if (typeMultigribNew) {
                        SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([0x01]), characteristic: sampleGattAttributes.SET_GESTURE_NEW, type: sampleGattAttributes.WRITE, myCase: "")
                    } else {
                        sendDataToHC10(dataForWrite: Data([0x01]), characteristic: sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(13))
                    }
                }
                saveDataString(key: sampleGattAttributes.GESTURE_USE_NUM, value: String(2))
            case gesture3:
                if (typeMultigribNewVM) {
                    SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x02]), characteristic: sampleGattAttributes.SET_GESTURE_NEW_VM, countRestart: 50)
                } else {
                    if (typeMultigribNew) {
                        SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([0x02]), characteristic: sampleGattAttributes.SET_GESTURE_NEW, type: sampleGattAttributes.WRITE, myCase: "")
                    } else {
                        sendDataToHC10(dataForWrite: Data([0x02]), characteristic: sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(13))
                    }
                }
                saveDataString(key: sampleGattAttributes.GESTURE_USE_NUM, value: String(3))
            case gesture4:
                if (typeMultigribNewVM) {
                    SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x03]), characteristic: sampleGattAttributes.SET_GESTURE_NEW_VM, countRestart: 50)
                } else {
                    if (typeMultigribNew) {
                        SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([0x03]), characteristic: sampleGattAttributes.SET_GESTURE_NEW, type: sampleGattAttributes.WRITE, myCase: "")
                    } else {
                        sendDataToHC10(dataForWrite: Data([0x03]), characteristic: sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(13))
                    }
                }
                saveDataString(key: sampleGattAttributes.GESTURE_USE_NUM, value: String(4))
            case gesture5:
                if (typeMultigribNewVM) {
                    SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x04]), characteristic: sampleGattAttributes.SET_GESTURE_NEW_VM, countRestart: 50)
                } else {
                    if (typeMultigribNew) {
                        SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([0x04]), characteristic: sampleGattAttributes.SET_GESTURE_NEW, type: sampleGattAttributes.WRITE, myCase: "")
                    } else {
                        sendDataToHC10(dataForWrite: Data([0x04]), characteristic: sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(13))
                    }
                }
                saveDataString(key: sampleGattAttributes.GESTURE_USE_NUM, value: String(5))
            case gesture6:
                if (typeMultigribNewVM) {
                    SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x05]), characteristic: sampleGattAttributes.SET_GESTURE_NEW_VM, countRestart: 50)
                } else {
                    if (typeMultigribNew) {
                        SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([0x05]), characteristic: sampleGattAttributes.SET_GESTURE_NEW, type: sampleGattAttributes.WRITE, myCase: "")
                    } else {
                        sendDataToHC10(dataForWrite: Data([0x05]), characteristic: sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(13))
                    }
                }
                saveDataString(key: sampleGattAttributes.GESTURE_USE_NUM, value: String(6))
            case gesture7:
                if (typeMultigribNewVM) {
                    SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x06]), characteristic: sampleGattAttributes.SET_GESTURE_NEW_VM, countRestart: 50)
                } else {
                    if (typeMultigribNew) {
                        SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([0x06]), characteristic: sampleGattAttributes.SET_GESTURE_NEW, type: sampleGattAttributes.WRITE, myCase: "")
                    } else {
                        sendDataToHC10(dataForWrite: Data([0x06]), characteristic: sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(13))
                    }
                }
                saveDataString(key: sampleGattAttributes.GESTURE_USE_NUM, value: String(7))
            case gesture8:
                if (typeMultigribNewVM) {
                    SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x07]), characteristic: sampleGattAttributes.SET_GESTURE_NEW_VM, countRestart: 50)
                } else {
                    if (typeMultigribNew) {
                        SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([0x07]), characteristic: sampleGattAttributes.SET_GESTURE_NEW, type: sampleGattAttributes.WRITE, myCase: "")
                    } else {
                        sendDataToHC10(dataForWrite: Data([0x07]), characteristic: sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(13))
                    }
                }
                saveDataString(key: sampleGattAttributes.GESTURE_USE_NUM, value: String(8))
            default:
                saveDataString(key: sampleGattAttributes.GESTURE_EDITING_NUM, value: String(0))
        }
        loadDataString()
        initUI()
    }
    private func sendDataToHC10 (dataForWrite: Data, characteristic: String, myCase: String) {
        self.dataForCommunicate["byteArray"] = dataForWrite.hexEncodedString()
        self.dataForCommunicate["characteristic"] = characteristic
        self.dataForCommunicate["type"] = sampleGattAttributes.WRITE_HC10
        self.dataForCommunicate["case"] = myCase
        NotificationCenter.default.post(name: .notificationFromSensorsViewController, object: nil, userInfo: self.dataForCommunicate)
    }
    @objc public func sendDataToFest (dataForWrite: Data, characteristic: String, typeFestX: Bool) {
        //определить FEST-H или FEST-X подключён
        print("Вызвана функция sendDataToFest  typeFestX = \(typeFestX)")
        if (typeFestX) {
            SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: dataForWrite, characteristic: characteristic, countRestart: 50)
        } else {
            SensorsViewController.myInteractiveQueueComand(dataForWrite: dataForWrite, characteristic: characteristic, type: sampleGattAttributes.WRITE, myCase: "")
        }
    }
    
    @objc public func getDeviceName() -> String {
        var textName: String = "";
        savingParametrsMassString = [SaveObjectString]()
        savingParametrsMassString = DataManager.loadAll(SaveObjectString.self)
        for item in savingParametrsMassString {
            if (item.key == sampleGattAttributes.DEVICE_NAME) {
                textName = item.value
            }
        }
        return textName;
    }
    @objc public func getStatusConnection() -> Int {
        savingParametrsMassString = [SaveObjectString]()
        savingParametrsMassString = DataManager.loadAll(SaveObjectString.self)
        for item in savingParametrsMassString {
            if (item.key == sampleGattAttributes.STATUS_CONNECTION) {
                return Int(item.value)!;
            }
        }
        return 0;
    }
    @objc public func getGestureNum() -> Int {
        savingParametrsMassString = [SaveObjectString]()
        savingParametrsMassString = DataManager.loadAll(SaveObjectString.self)
        for item in savingParametrsMassString {
            if (item.key == sampleGattAttributes.GESTURE_EDITING_NUM) {
                return Int(item.value)!;
            }
        }
        return 0;
    }
    @objc public func getUseFestX() -> Int {
        savingParametrsMassString = [SaveObjectString]()
        savingParametrsMassString = DataManager.loadAll(SaveObjectString.self)
        for item in savingParametrsMassString {
            if (item.key == sampleGattAttributes.USE_MULTIGRAB_FESTX) {
                return Int(item.value)!;
            }
        }
        return 0;
    }
    @objc public func getHandSide() -> Int {
        savingParametrsMassString = [SaveObjectString]()
        savingParametrsMassString = DataManager.loadAll(SaveObjectString.self)
        for item in savingParametrsMassString {
            if (item.key == sampleGattAttributes.HAND_SIDE) {
                return Int(item.value)!;
            }
        }
        return 0;
    }
    @objc public func getGestureTable() -> String {
        savingParametrsMassString = [SaveObjectString]()
        savingParametrsMassString = DataManager.loadAll(SaveObjectString.self)
        for item in savingParametrsMassString {
            if (item.key == sampleGattAttributes.ADD_GESTURE_NEW) {
                return item.value;
            }
        }
        return ""
    }
    @objc public func getFingersDelay() -> String {
        savingParametrsMassString = [SaveObjectString]()
        savingParametrsMassString = DataManager.loadAll(SaveObjectString.self)
        var figersDelay = [String] (repeating: "", count: 12)
        for item in savingParametrsMassString {
            if (item.key == (sampleGattAttributes.GESTURE_OPEN_DELAY_FINGER+"1")) {
                figersDelay[0] = item.value
            }
            if (item.key == (sampleGattAttributes.GESTURE_OPEN_DELAY_FINGER+"2")) {
                figersDelay[1] = item.value
            }
            if (item.key == (sampleGattAttributes.GESTURE_OPEN_DELAY_FINGER+"3")) {
                figersDelay[2] = item.value
            }
            if (item.key == (sampleGattAttributes.GESTURE_OPEN_DELAY_FINGER+"4")) {
                figersDelay[3] = item.value
            }
            if (item.key == (sampleGattAttributes.GESTURE_OPEN_DELAY_FINGER+"5")) {
                figersDelay[4] = item.value
            }
            if (item.key == (sampleGattAttributes.GESTURE_OPEN_DELAY_FINGER+"6")) {
                figersDelay[5] = item.value
            }
            if (item.key == (sampleGattAttributes.GESTURE_CLOSE_DELAY_FINGER+"1")) {
                figersDelay[6] = item.value
            }
            if (item.key == (sampleGattAttributes.GESTURE_CLOSE_DELAY_FINGER+"2")) {
                figersDelay[7] = item.value
            }
            if (item.key == (sampleGattAttributes.GESTURE_CLOSE_DELAY_FINGER+"3")) {
                figersDelay[8] = item.value
            }
            if (item.key == (sampleGattAttributes.GESTURE_CLOSE_DELAY_FINGER+"4")) {
                figersDelay[9] = item.value
            }
            if (item.key == (sampleGattAttributes.GESTURE_CLOSE_DELAY_FINGER+"5")) {
                figersDelay[10] = item.value
            }
            if (item.key == (sampleGattAttributes.GESTURE_CLOSE_DELAY_FINGER+"6")) {
                figersDelay[11] = item.value
            }
        }
        var data: String = ""
        for i in 0...11 {
            data += figersDelay[i]+" "
        }
        return data
    }
    @objc public func getFingersDelaySwitch() -> Int {
        savingParametrsMassString = [SaveObjectString]()
        savingParametrsMassString = DataManager.loadAll(SaveObjectString.self)
        for item in savingParametrsMassString {
            if (item.key == sampleGattAttributes.FINGERS_DELAY_SWITCH) {
                return Int(item.value)!;
            }
        }
        return 0;
    }
    
    
    // MARK: - работа с фоном
    override func viewDidLayoutSubviews() {
        let topColor: UIColor = #colorLiteral(red: 0, green: 0.4745098039, blue: 0.568627451, alpha: 1)
        let bottomColor: UIColor = #colorLiteral(red: 0.2823529412, green: 0.6941176471, blue: 0.7490196078, alpha: 1)
        
        let startPointX: CGFloat = 0.5
        let startPointY: CGFloat = 0
        let endPointX: CGFloat = 0.5
        let endPointY: CGFloat = 1
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: startPointX, y: startPointY)
        gradientLayer.endPoint = CGPoint(x: endPointX, y: endPointY)
        gradientLayer.frame = conteinerView.bounds
        conteinerView.layer.insertSublayer(gradientLayer, at: 0)
    }
    private func setupeButton (button: UIButton, buttonSettings: UIButton) {
        button.layer.cornerRadius = 21
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        button.setTitleColor(UIColor.white, for: UIControlState.normal)
        button.layer.backgroundColor = UIColor(named: "lineColor_open")?.cgColor
        buttonSettings.setImage(settingsDefault, for: .normal)
    }
    private func setupeButtonActive (button: UIButton, buttonSettings: UIButton) {
        button.layer.cornerRadius = 21
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor(named: "lineColor_open")?.cgColor
        button.setTitleColor(UIColor(named: "lineColor_open"), for: UIControlState.normal)
        button.layer.backgroundColor = UIColor.white.cgColor
        buttonSettings.setImage(settingsActive, for: .normal)
    }
    private func setupeButtonActiveWithoutSettings (button: UIButton) {
        button.layer.cornerRadius = 21
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor(named: "lineColor_open")?.cgColor
        button.setTitleColor(UIColor(named: "lineColor_open"), for: UIControlState.normal)
        button.layer.backgroundColor = UIColor.white.cgColor
    }
    
    private func initUI() {
        setupeButton(button: gesture1, buttonSettings: gesture2settings)
        setupeButton(button: gesture2, buttonSettings: gesture2settings)
        setupeButton(button: gesture3, buttonSettings: gesture3settings)
        setupeButton(button: gesture4, buttonSettings: gesture4settings)
        setupeButton(button: gesture5, buttonSettings: gesture5settings)
        setupeButton(button: gesture6, buttonSettings: gesture6settings)
        setupeButton(button: gesture7, buttonSettings: gesture7settings)
        setupeButton(button: gesture8, buttonSettings: gesture8settings)
        for item in savingParametrsMassString
        {
            if (item.key == sampleGattAttributes.DEVICE_NAME) {
                deviceName.text = item.value
            }
            if (item.key == sampleGattAttributes.STATUS_CONNECTION) {
                            if (Int(item.value) == 1) {
                                statusImage.image = connectStatus
                            } else {
                                statusImage.image = disconnectStatus
                            }
                        }
            if (item.key == sampleGattAttributes.GESTURE_USE_NUM) {
                if (Int(item.value) == 1) { setupeButtonActiveWithoutSettings(button: gesture1) }
                if (Int(item.value) == 2) { setupeButtonActive(button: gesture2, buttonSettings: gesture2settings) }
                if (Int(item.value) == 3) { setupeButtonActive(button: gesture3, buttonSettings: gesture3settings) }
                if (Int(item.value) == 4) { setupeButtonActive(button: gesture4, buttonSettings: gesture4settings) }
                if (Int(item.value) == 5) { setupeButtonActive(button: gesture5, buttonSettings: gesture5settings) }
                if (Int(item.value) == 6) { setupeButtonActive(button: gesture6, buttonSettings: gesture6settings) }
                if (Int(item.value) == 7) { setupeButtonActive(button: gesture7, buttonSettings: gesture7settings) }
                if (Int(item.value) == 8) { setupeButtonActive(button: gesture8, buttonSettings: gesture8settings) }
            }
            if (item.key == sampleGattAttributes.USE_MULTIGRAB_FESTH) {
                if (Int(item.value) == 1) {
                    typeMultigribNew = true
                }
            }
            if (item.key == sampleGattAttributes.USE_MULTIGRAB_FESTX) {
                if (Int(item.value) == 1) {
                    typeMultigribNewVM = true
//                    print("FEST-X activated")
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
    @objc func saveDataString(key: String, value: String) {
        let saveObjectString = SaveObjectString(key: key, value: value)
        print("save   key: \(key) value: \(value)")
        DataManager.save(saveObjectString, with: key)
    }
    @objc func updatingUINotification(notification: Notification) {
        //переключение активного жеста в мгновение6 когда он меняется в нотификации
        guard let dataForWrite = notification.userInfo,
            let gesture_use_num = dataForWrite["gesture_use_num"] as? String
        else { return }
        for item in savingParametrsMassString
        {
            if (item.key == SensorsViewController.sampleGattAttributes.GESTURE_USE_NUM) {
                if (Int(item.value) != Int(gesture_use_num)) {
                    loadDataString()
                    initUI()
                }
            }
        }
    }
}

