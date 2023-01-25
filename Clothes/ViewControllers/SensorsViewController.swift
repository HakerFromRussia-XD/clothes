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
    
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var statusImage: UIImageView!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var openThreshold: UISlider! {
        didSet {
            openThreshold.transform = CGAffineTransform(rotationAngle: CGFloat(-(Double.pi/2)))
        }
    }
    @IBOutlet weak var openThresholdView: UIView!
    @IBOutlet weak var closeThreshold: UISlider! {
        didSet {
            closeThreshold.transform = CGAffineTransform(rotationAngle: CGFloat(-(Double.pi/2)))
        }
    }
    @IBOutlet weak var closeThresholdView: UIView!
    @IBOutlet weak var openSensSlide: UISlider!
    @IBOutlet weak var openSensNum: UILabel!
    @IBOutlet weak var closeSensSlide: UISlider!
    @IBOutlet weak var closeSensNum: UILabel!
    @IBOutlet weak var swapSensText: UILabel!
    @IBOutlet weak var swapSensSwitch: UISwitch!
    @IBOutlet weak var blockSettingsSwitch: UISwitch!
    @IBOutlet weak var bloskSettingsText: UILabel!
    @IBOutlet weak var openBtn: UIButton!
    @IBOutlet weak var closeBtn: UIButton!
    @IBAction func unwindToThisAdvencedViewController (sender: UIStoryboardSegue){
        //тут выполняется код, при возвращении на это вью с помощью кнопок back от куда угодно
        loadDataString()
        initUI()
    }
    @IBOutlet weak var driverText: UILabel!
    @IBOutlet weak var bmsText: UILabel!
    @IBOutlet weak var sensersText: UILabel!
    @IBOutlet weak var gestureSettingsBtn: UIButton!
    @IBOutlet weak var advancedSettingsBtn: UIButton!
    @IBOutlet weak var unlockAdvancedSettings: UIButton!
    
    let connectStatus = UIImage(named:"connect_status")!
    let disconnectStatus = UIImage(named:"disconnect_status")!
    
    let values = (0..<1).map { (i) -> ChartDataEntry in
        let val = Double(arc4random_uniform(UInt32(1))+3)
        return ChartDataEntry(x: Double(i), y: val)
    }
    var firstInit: Bool = true

    var reseve_sensor_1_data: Int = 0
    var reseve_sensor_2_data: Int = 0
    
    var open_sens_slide: UInt8 = 0
    var close_sens_slide: UInt8 = 0
    

    var count: Int = 0
    var countTest: Int = 0
    static let sampleGattAttributes = SampleGattAttributes()
    static var dataForCommunicate = ["byteArray": "01020304", "characteristic":"1", "type":"READ", "case":"0"]
    private var savingParametrsMassString:[SaveObjectString]!
    private var blockChangeSettings: Bool = false
    private var lockAdvancedSettings: Bool = false
    private var startMoovSlide: Bool = true
    private var startValue: Float!
    private var swapButtonOpenClose: Bool = false
    static var flagReadData: Bool = true
    private var pauseReadData: Bool = true
    private var delayForReadData: UInt32 = 100000 //в микросекундах. Должно быть меньше, чем queueInterval. Чтобы не давать очереди
    static let queueInterval: UInt32 = 110000// большее количество команд, чем она отдаёт
    static let inactiveQueue = DispatchQueue(label: "My queue", attributes: [.concurrent, .initiallyInactive])
    static let semafore = DispatchSemaphore(value: 1)
    
    private var delayForReadData2: UInt32 = 1000000 //в микросекундах. Должно быть меньше, чем queueInterval. Чтобы не давать очереди
    static let queueInterval2: UInt32 = 1100000// большее количество команд, чем она отдаёт
    static let inactiveQueue2 = DispatchQueue(label: "My queue 2", attributes: [.concurrent, .initiallyInactive])
    static let semafore2 = DispatchSemaphore(value: 1)
    static var flagReadData2: Bool = true
    static var expectedReceiveConfirmation: Int = 0
    static var expectedIdCommand = "not set"
    var previosReceivedIdCommand = "not set"
    private static var oneAttempt = 0
    private static var twoAttempts = 0
    private static var threeAttempts = 0
    private static var fourAttempts = 0
    private static var fiveAttempts = 0
    private static var countAttempts = 0
    private static var versionDriverNum: Float = 0
    
    private var savingDeviceName: String = "...."
    private var typeMultigrib: Bool = false
    private var typeMultigribNew: Bool = false
    private var typeMultigribNewVM: Bool = false
    private var reseivedFirstNotifyDataBool: Bool = true
    
    deinit {
        print("SensorsViewController is being deinitialized")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.statusBarStyle = .lightContent
        saveDataString(key: SensorsViewController.sampleGattAttributes.READ_THREAD_START, value: String(0))
        saveDataString(key: SensorsViewController.sampleGattAttributes.USE_MULTIGRAB_FESTX, value: String(0))
        saveDataString(key: SensorsViewController.sampleGattAttributes.USE_MULTIGRAB_FESTH, value: String(0))
        initChart()
        loadDataString()
        initUI()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPerehod(gesture:)))
        unlockAdvancedSettings.addGestureRecognizer(longPress)
        
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { (_) in
            self.addEntry (sens1: self.reseve_sensor_1_data, sens2: self.reseve_sensor_2_data)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updatingUINotification), name: .notificationReseiveBLEData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkStateConnection), name: .notificationCheckStateConnection, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: .notificationDataDialogToSensorsView, object: nil)
        
        print("Выполнился viewDidLoad")
        if (typeMultigrib) {
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.FESTO_A_CHARACTERISTIC, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
        }
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
                    sendDataToINDY(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_SELECT_SCALE)
                }
            }
        }
    }
    @objc func updatingUINotification(notification: Notification) {
        guard let dataForWrite = notification.userInfo,
            let numderBytes = dataForWrite["numderBytes"] as? String,
            let driver_num = dataForWrite["driver_num"] as? String,
            let bms_num = dataForWrite["bms_num"] as? String,
            let sens_num = dataForWrite["sens_num"] as? String,
            let open_ch_num = dataForWrite["open_ch_num"] as? String,
            let close_ch_num = dataForWrite["close_ch_num"] as? String,
            let corellator_noise_threshold_1_num = dataForWrite["corellator_noise_threshold_1_num"] as? String,
            let corellator_noise_threshold_2_num = dataForWrite["corellator_noise_threshold_2_num"] as? String,
              
            let shutdown_current_num = dataForWrite["shutdown_current_num"] as? String,
            let scale_flags_and_revers_and_one_channel = dataForWrite["scale_flags_and_revers_and_one_channel"] as? String,
                
            let set_reverse = dataForWrite["set_reverse"] as? String,
            let set_one_channel = dataForWrite["set_one_channel"] as? String,
            let gesture_use_num = dataForWrite["gesture_use_num"] as? String,
            let gesture_switching_by_sensors = dataForWrite["gesture_switching_by_sensors"] as? String,
            let time_at_rest = dataForWrite["time_at_rest"] as? String,
            let sens_1 = dataForWrite["sens_1"] as? String,
            let sens_2 = dataForWrite["sens_2"] as? String,
            let reseivedFirstNotifyData = dataForWrite["reseivedFirstNotifyData"] as? String,
            let expected_id_command = dataForWrite["expected_id_command"] as? String
        else { return }
        if (Int(numderBytes) ?? 0 >= 10) {
            for item in savingParametrsMassString
            {
                if (item.key == SensorsViewController.sampleGattAttributes.DRIVER_NUM) {
                    if (Int(item.value) != Int(driver_num)) {
                        print("обновили версию драйвера")
                        saveDataString(key: item.key, value: String(Int(driver_num)!))
                        loadDataString()
                        initUI()
                    }
                }
                if (item.key == SensorsViewController.sampleGattAttributes.BMS_NUM) {
                    if (Int(item.value) != Int(bms_num)) {
                        print("обновили версию бмс")
                        saveDataString(key: item.key, value: String(Int(bms_num)!))
                        loadDataString()
                        initUI()
                    }
                }
                if (item.key == SensorsViewController.sampleGattAttributes.SENS_NUM) {
                    if (Int(item.value) != Int(sens_num)) {
                        print("обновили версию сенсоров")
                        saveDataString(key: item.key, value: String(Int(sens_num)!))
                        loadDataString()
                        initUI()
                    }
                }
                if (item.key == SensorsViewController.sampleGattAttributes.OPEN_THRESHOLD_HDLE) {
                    if (Int(item.value) != Int(open_ch_num)) {
                        print("обновили порог открытия")
                        saveDataString(key: item.key, value: String(Int(open_ch_num)!))
                        loadDataString()
                        initUI()
                    }
                }
                if (item.key == SensorsViewController.sampleGattAttributes.CLOSE_THRESHOLD_HDLE) {
                    if (Int(item.value) != Int(close_ch_num)) {
                        print("обновили порог закрытия")
                        saveDataString(key: item.key, value: String(Int(close_ch_num)!))
                        loadDataString()
                        initUI()
                    }
                }
                if (item.key == SensorsViewController.sampleGattAttributes.SENS_OPTIONS+"1") {
                    if (Int(item.value) != Int(corellator_noise_threshold_1_num)) {
                        print("обновили чувствительность открытия")
                        saveDataString(key: item.key, value: String(Int(corellator_noise_threshold_1_num)!))
                        loadDataString()
                        initUI()
                    }
                }
                if (item.key == SensorsViewController.sampleGattAttributes.SENS_OPTIONS+"2") {
                    if (Int(item.value) != Int(corellator_noise_threshold_2_num)) {
                        print("обновили чувствительность закрытия")
                        saveDataString(key: item.key, value: String(Int(corellator_noise_threshold_2_num)!))
                        loadDataString()
                        initUI()
                    }
                }
                if (item.key == SensorsViewController.sampleGattAttributes.SET_REVERSE) {
                    if (Int(item.value) != Int(set_reverse)) {
                        print("обновили реверс датчиков")
                        saveDataString(key: item.key, value: String(Int(set_reverse)!))
                        loadDataString()
                        initUI()
                    }
                }
            }
        }
        if (Int(numderBytes) ?? 0 >= 12) {
            for item in savingParametrsMassString
            {
                if (item.key == SensorsViewController.sampleGattAttributes.SHUTDOWN_CURRENT_HDLE) {
                    if (Int(item.value) != Int(shutdown_current_num)) {
                        print("обновили ток отсечки INDY")
                        saveDataString(key: item.key, value: String(Int(shutdown_current_num)!))
                        NotificationCenter.default.post(name: .notificationUpdateAdvancedSettings, object: nil, userInfo: nil)
                    }
                }
                if (item.key == SensorsViewController.sampleGattAttributes.SET_REVERSE) {
                    //флаг установки реверса сенсоров
                    if ((Int(item.value) != (Int(scale_flags_and_revers_and_one_channel) ?? 254) >> 0 & 0b00000001)) {
                        print("обновили реверс датчиков \((Int(scale_flags_and_revers_and_one_channel) ?? 254) >> 0 & 0b00000001)")
                        saveDataString(key: item.key, value: String((Int(scale_flags_and_revers_and_one_channel) ?? 254) >> 0 & 0b00000001))
                        loadDataString()
                        initUI()
                    }
                }
                if (item.key == SensorsViewController.sampleGattAttributes.SET_ONE_CHANNEL) {
                    //флаг одноканального режима
                    if ((Int(item.value) != (Int(scale_flags_and_revers_and_one_channel) ?? 254) >> 1 & 0b00000001)) {
                        print("обновили одноканальный режим \((Int(scale_flags_and_revers_and_one_channel) ?? 254) >> 1 & 0b00000001)")
                        saveDataString(key: item.key, value: String((Int(scale_flags_and_revers_and_one_channel) ?? 254) >> 1 & 0b00000001))
                        NotificationCenter.default.post(name: .notificationUpdateAdvancedSettings, object: nil, userInfo: nil)
                    }
                }
                if (item.key == SensorsViewController.sampleGattAttributes.SCALE) {
                    //номер размера 0-S 1-M 2-L 3XL
                    if (Int(item.value) != ((Int(scale_flags_and_revers_and_one_channel) ?? 254) >> 2 & 0b00000011)) {
                        print("обновили установку размера INDY \((Int(scale_flags_and_revers_and_one_channel) ?? 254) >> 2 & 0b00000011)")
                        saveDataString(key: item.key, value: String((Int(scale_flags_and_revers_and_one_channel) ?? 254) >> 2 & 0b00000011))
                        NotificationCenter.default.post(name: .notificationUpdateAdvancedSettings, object: nil, userInfo: nil)
                    }
                }
                if (item.key == SensorsViewController.sampleGattAttributes.SCALE_FIRST_SET) {
                    //если это число = 1, то устанговка размера уже производилась
                    if (Int(item.value) != ((Int(scale_flags_and_revers_and_one_channel) ?? 254) >> 7 & 0b00000001)) {
                        print("обновили первую установку размера INDY \((Int(scale_flags_and_revers_and_one_channel) ?? 254) >> 7 & 0b00000001)")
                        saveDataString(key: item.key, value: String((Int(scale_flags_and_revers_and_one_channel) ?? 254) >> 7 & 0b00000001))
                        loadDataString()
                        if ((Int(scale_flags_and_revers_and_one_channel) ?? 254) >> 7 & 0b00000001 == 0) {
                            print("показ диалогового окна с выбором размера")
                            performSegue(withIdentifier: "showSelectScaleVC", sender: nil)
                        }
                    }
                }
            }
        }
        
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
        
        self.reseve_sensor_1_data = Int(sens_1)!
        self.reseve_sensor_2_data = Int(sens_2)!
        
//        print("данные IdCommand: \(expected_id_command)  previosReceivedIdCommand: \(previosReceivedIdCommand)   expectedIdCommand:\(SensorsViewController.expectedIdCommand).")
        if (self.previosReceivedIdCommand != expected_id_command) {
            self.previosReceivedIdCommand = expected_id_command
//            print("данные предыдущей отправленной на протез команды совпали текущей командой previosReceivedIdCommand: \(expected_id_command)    expectedIdCommand:\(SensorsViewController.expectedIdCommand).")
            if (SensorsViewController.expectedIdCommand == expected_id_command) {
//                print("данные последней отправленной на протез команды совпали ожидаемой командой. новая очередь")
                SensorsViewController.expectedReceiveConfirmation = 2
                self.previosReceivedIdCommand = "FFFF"
            }
        }
        
        //MARK: - reseivedFirstNotifyData = "true" только если протез FEST-H или FEST-X
        if (reseivedFirstNotifyData == "true") {
            if (reseivedFirstNotifyDataBool){
                reseivedFirstNotifyDataBool = false
                requestStartParameters()
                print ("Обновляем начальные данные")
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
    @objc func longPerehod(gesture: UILongPressGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.began {
            print("Long Press")
        
            
            var titleDialog = ""
            if (lockAdvancedSettings) {
                titleDialog = "Do you want to unlock the advanced settings?"
            } else { titleDialog = "Do you want to block advanced settings?"}
            //1. Create the alert controller.
            let alert = UIAlertController(title: titleDialog, message: "", preferredStyle: .alert)
            

            // 2. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (_) in
            }))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                if (self.lockAdvancedSettings) {
                    self.saveDataString(key: SensorsViewController.sampleGattAttributes.OPEN_ADVANCED_SETTINGS, value: String(1))
                } else {
                    self.saveDataString(key: SensorsViewController.sampleGattAttributes.OPEN_ADVANCED_SETTINGS, value: String(0))
                }
                self.loadDataString()
                self.initUI()
            }))

            // 3. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - обработка взаимодействия с UI
    @IBAction func openThresholdSlide(_ sender: Any) {
        UIView.animate(withDuration: 0.06, animations: {
            self.openThresholdView.transform = CGAffineTransform.init(translationX: 0, y: -(CGFloat(self.openThreshold.value)/1.05))
        })
    }
    @IBAction func openThresholdSlideStop(_ sender: UISlider) {
        if (blockChangeSettings) {
            loadDataString()
            initUI()
        } else {
            let data = Data([UInt8(openThreshold.value)])
            if (typeMultigribNewVM) {
                SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.OPEN_THRESHOLD_NEW_VM, countRestart: 50)
                
            } else {
                if (typeMultigribNew){
                    SensorsViewController.myInteractiveQueueComand (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.OPEN_THRESHOLD_NEW, type: SensorsViewController.sampleGattAttributes.WRITE, myCase: "")
                } else {
                    if (typeMultigrib) {
                        SensorsViewController.sendDataToHC10 (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(4))
                    }
                    else {
                        sendDataToINDY(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.OPEN_THRESHOLD_HDLE)
                    }
                }
            }
            saveDataString(key: SensorsViewController.sampleGattAttributes.OPEN_THRESHOLD_HDLE, value: String(Int(openThreshold.value)))
        }
    }
    @IBAction func closeThresholdSlide(_ sender: Any) {
        UIView.animate(withDuration: 0.06, animations: {
            self.closeThresholdView.transform = CGAffineTransform.init(translationX: 0, y: -(CGFloat(self.closeThreshold.value)/1.05))
        })
    }
    @IBAction func closeThresholdSlideStop(_ sender: UISlider) {
        if (blockChangeSettings) {
            loadDataString()
            initUI()
        } else {
            let data = Data([UInt8(closeThreshold.value)])
            if (typeMultigribNewVM) {
                SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.CLOSE_THRESHOLD_NEW_VM, countRestart: 50)
            } else {
                if (typeMultigribNew){
                    SensorsViewController.myInteractiveQueueComand (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.CLOSE_THRESHOLD_NEW, type: SensorsViewController.sampleGattAttributes.WRITE, myCase: "")
                } else {
                    if (typeMultigrib) { SensorsViewController.sendDataToHC10 (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(5)) }
                    else { sendDataToINDY(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.CLOSE_THRESHOLD_HDLE) }
                }
            }
            saveDataString(key: SensorsViewController.sampleGattAttributes.CLOSE_THRESHOLD_HDLE, value: String(Int(closeThreshold.value)))
        }
    }
    @IBAction func openSensSlide(_ sender: UISlider) {
        openSensNum.text = String(Int(sender.value))
    }
    @IBAction func openSensSlideStop(_ sender: UISlider) {
        if (blockChangeSettings) {
            loadDataString()
            initUI()
        } else {
            let data = Data([0x01, (255 - UInt8(sender.value)), 0x01])
            open_sens_slide = (255 - UInt8(sender.value))
            print("Пишем число   open_sens_slide: " + String(open_sens_slide) + "   close_sens_slide: " + String(close_sens_slide))
            let data_new = Data([open_sens_slide, 6, 1, 0x10, 36, 18, 44, 52, 64, 72, 0x40, 5, 64, close_sens_slide, 6, 1, 0x10, 36, 18, 44, 52, 64, 72, 0x40, 5, 64])
            if (typeMultigribNewVM) {
                SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: data_new, characteristic: SensorsViewController.sampleGattAttributes.SENS_OPTIONS_NEW_VM, countRestart: 50)
            } else {
                if (typeMultigribNew){
                    SensorsViewController.myInteractiveQueueComand (dataForWrite: data_new, characteristic: SensorsViewController.sampleGattAttributes.SENS_OPTIONS_NEW, type: SensorsViewController.sampleGattAttributes.WRITE, myCase: "")
                } else {
                    if (typeMultigrib) { SensorsViewController.sendDataToHC10 (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(11)) }
                    else { sendDataToINDY(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SENS_OPTIONS) }
                }
            }
            saveDataString(key: SensorsViewController.sampleGattAttributes.SENS_OPTIONS + "1", value: String(Int(sender.value)))
        }
    }
    @IBAction func closeSensSlide(_ sender: UISlider) {
        closeSensNum.text = String(Int(sender.value))
    }
    @IBAction func closeSensSlideStop(_ sender: UISlider) {
        if (blockChangeSettings) {
            loadDataString()
            initUI()
        } else {
            let data = Data([0x01, (255 - UInt8(sender.value)), 0x02])
            close_sens_slide = (255 - UInt8(sender.value))
            print("Пишем число   close_sens_slide: " + String(close_sens_slide) + "   open_sens_slide: " + String(open_sens_slide))
            let data_new = Data([open_sens_slide, 6, 1, 0x10, 36, 18, 44, 52, 64, 72, 0x40, 5, 64, close_sens_slide, 6, 1, 0x10, 36, 18, 44, 52, 64, 72, 0x40, 5, 64])
            if (typeMultigribNewVM) {
                SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: data_new, characteristic: SensorsViewController.sampleGattAttributes.SENS_OPTIONS_NEW_VM, countRestart: 50)
            } else {
                if (typeMultigribNew){
                    SensorsViewController.myInteractiveQueueComand (dataForWrite: data_new, characteristic: SensorsViewController.sampleGattAttributes.SENS_OPTIONS_NEW, type: SensorsViewController.sampleGattAttributes.WRITE, myCase: "")
                } else {
                    if (typeMultigrib) { SensorsViewController.sendDataToHC10 (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(11)) }
                    else { sendDataToINDY(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SENS_OPTIONS) }
                }
            }
            saveDataString(key: SensorsViewController.sampleGattAttributes.SENS_OPTIONS + "2", value: String(Int(sender.value)))
        }
    }
    @IBAction func swapSensSwitch(_ sender: UISwitch) {
        if (blockChangeSettings) {
            loadDataString()
            initUI()
        } else {
            if (sender.isOn) {
                swapSensText.text = "on"
                let data = Data([0x01])
                if (typeMultigribNewVM) {
                    SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_REVERSE_NEW_VM, countRestart: 50)
                } else {
                    if (typeMultigribNew){
                        SensorsViewController.myInteractiveQueueComand (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_REVERSE_NEW, type: SensorsViewController.sampleGattAttributes.WRITE, myCase: "")
                    } else {
                        if (typeMultigrib) { SensorsViewController.sendDataToHC10 (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(14))}
                        else { sendDataToINDY(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_REVERSE) }
                    }
                }
                saveDataString(key: SensorsViewController.sampleGattAttributes.SET_REVERSE, value: String(1))
            } else {
                swapSensText.text = "off"
                let data = Data([0x00])
                if (typeMultigribNewVM) {
                    SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_REVERSE_NEW_VM, countRestart: 50)
                } else {
                    if (typeMultigribNew){
                        SensorsViewController.myInteractiveQueueComand (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_REVERSE_NEW, type: SensorsViewController.sampleGattAttributes.WRITE, myCase: "")
                    } else {
                        if (typeMultigrib) { SensorsViewController.sendDataToHC10 (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(14))}
                        else { sendDataToINDY(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_REVERSE) }
                    }
                }
                saveDataString(key: SensorsViewController.sampleGattAttributes.SET_REVERSE, value: String(0))
            }
        }
    }
    @IBAction func blockSettingsSwitch(_ sender: UISwitch) {
        if (sender.isOn) {
            bloskSettingsText.text = "on"
            blockChangeSettings = true
            saveDataString(key: SensorsViewController.sampleGattAttributes.SETTINGS_BLOKING, value: String(1))
        } else {
            bloskSettingsText.text = "off"
            blockChangeSettings = false
            saveDataString(key: SensorsViewController.sampleGattAttributes.SETTINGS_BLOKING, value: String(0))
        }
    }
    @IBAction func startOpen(_ sender: Any) {
        let data = Data([0x01, 0x00])
        if (swapButtonOpenClose) {
            if (typeMultigribNewVM) {
                print ("startClose")
                SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x01]), characteristic: SensorsViewController.sampleGattAttributes.CLOSE_MOTOR_NEW_VM, countRestart: 50)
            } else {
                if (typeMultigribNew){
                    SensorsViewController.myInteractiveQueueComand (dataForWrite: Data([0x01]), characteristic: SensorsViewController.sampleGattAttributes.CLOSE_MOTOR_NEW, type: SensorsViewController.sampleGattAttributes.WRITE, myCase: "")
                } else {
                    if (typeMultigrib) {
                        SensorsViewController.sendDataToHC10 (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(6))
                    }
                    else { sendDataToINDY(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.CLOSE_MOTOR_HDLE) }
                }
            }
        } else {
            if (typeMultigribNewVM) {
                print ("startOpen")
                SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x01]), characteristic: SensorsViewController.sampleGattAttributes.OPEN_MOTOR_NEW_VM, countRestart: 50)
            } else {
                if (typeMultigribNew){
                    SensorsViewController.myInteractiveQueueComand (dataForWrite: Data([0x01]), characteristic: SensorsViewController.sampleGattAttributes.OPEN_MOTOR_NEW, type: SensorsViewController.sampleGattAttributes.WRITE, myCase: "")
                } else {
                    if (typeMultigrib) {
                        SensorsViewController.sendDataToHC10 (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(6))
                    }
                    else { sendDataToINDY(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.OPEN_MOTOR_HDLE) }
                }
            }
        }
        
    }
    @IBAction func stopOpen(_ sender: Any) {
        let data = Data([0x00, 0x00])
        if (swapButtonOpenClose) {
            if (typeMultigribNewVM) {
                print ("stopClose")
                SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x00]), characteristic: SensorsViewController.sampleGattAttributes.CLOSE_MOTOR_NEW_VM, countRestart: 50)
            } else {
                if (typeMultigribNew){
                    SensorsViewController.myInteractiveQueueComand (dataForWrite: Data([0x00]), characteristic: SensorsViewController.sampleGattAttributes.CLOSE_MOTOR_NEW, type: SensorsViewController.sampleGattAttributes.WRITE, myCase: "")
                } else {
                    if (typeMultigrib) {
                        SensorsViewController.sendDataToHC10 (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(6))
                    }
                    else { sendDataToINDY(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.CLOSE_MOTOR_HDLE) }
                }
            }
        } else {
            if (typeMultigribNewVM) {
                print ("stopOpen")
                SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x00]), characteristic: SensorsViewController.sampleGattAttributes.OPEN_MOTOR_NEW_VM, countRestart: 50)
            } else {
                if (typeMultigribNew){
                    SensorsViewController.myInteractiveQueueComand (dataForWrite: Data([0x00]), characteristic: SensorsViewController.sampleGattAttributes.OPEN_MOTOR_NEW, type: SensorsViewController.sampleGattAttributes.WRITE, myCase: "")
                } else {
                    if (typeMultigrib) {
                        SensorsViewController.sendDataToHC10 (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(6))
                        
                    }
                    else { sendDataToINDY(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.OPEN_MOTOR_HDLE) }
                }
            }
        }
    }
    @IBAction func startClose(_ sender: Any) {
        let data = Data([0x01, 0x00])
        if (swapButtonOpenClose) {
            if (typeMultigribNewVM) {
                SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x01]), characteristic: SensorsViewController.sampleGattAttributes.OPEN_MOTOR_NEW_VM, countRestart: 50)
            } else {
                if (typeMultigribNew){
                    SensorsViewController.myInteractiveQueueComand (dataForWrite: Data([0x01]), characteristic: SensorsViewController.sampleGattAttributes.OPEN_MOTOR_NEW, type: SensorsViewController.sampleGattAttributes.WRITE, myCase: "")
                } else {
                    if (typeMultigrib) { SensorsViewController.sendDataToHC10 (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(7)) }
                    else { sendDataToINDY(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.OPEN_MOTOR_HDLE) }
                }
            }
        } else {
            if (typeMultigribNewVM) {
                SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x01]), characteristic: SensorsViewController.sampleGattAttributes.CLOSE_MOTOR_NEW_VM, countRestart: 50)
            } else {
                if (typeMultigribNew){
                    SensorsViewController.myInteractiveQueueComand (dataForWrite: Data([0x01]), characteristic: SensorsViewController.sampleGattAttributes.CLOSE_MOTOR_NEW, type: SensorsViewController.sampleGattAttributes.WRITE, myCase: "")
                } else {
                    if (typeMultigrib) { SensorsViewController.sendDataToHC10 (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(7)) }
                    else { sendDataToINDY(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.CLOSE_MOTOR_HDLE) }
                }
            }
        }
    }
    @IBAction func stopClose(_ sender: Any) {
        let data = Data([0x00, 0x00])
        if (swapButtonOpenClose) {
            if (typeMultigribNewVM) {
                SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x00]), characteristic: SensorsViewController.sampleGattAttributes.OPEN_MOTOR_NEW_VM, countRestart: 50)
            } else {
                if (typeMultigribNew){
                    SensorsViewController.myInteractiveQueueComand (dataForWrite: Data([0x00]), characteristic: SensorsViewController.sampleGattAttributes.OPEN_MOTOR_NEW, type: SensorsViewController.sampleGattAttributes.WRITE, myCase: "")
                } else {
                    if (typeMultigrib) { SensorsViewController.sendDataToHC10 (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(7)) }
                    else {sendDataToINDY(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.OPEN_MOTOR_HDLE)  }
                }
            }
        } else {
            if (typeMultigribNewVM) {
                SensorsViewController.myInteractiveQueueComandWithConfirmation(dataForWrite: Data([0x00]), characteristic: SensorsViewController.sampleGattAttributes.CLOSE_MOTOR_NEW_VM, countRestart: 50)
            } else {
                if (typeMultigribNew){
                    SensorsViewController.myInteractiveQueueComand (dataForWrite: Data([0x00]), characteristic: SensorsViewController.sampleGattAttributes.CLOSE_MOTOR_NEW, type: SensorsViewController.sampleGattAttributes.WRITE, myCase: "")
                } else {
                    if (typeMultigrib) { SensorsViewController.sendDataToHC10 (dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.FESTO_A_CHARACTERISTIC, myCase: String(7)) }
                    else { sendDataToINDY(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.CLOSE_MOTOR_HDLE) }
                }
            }
        }
    }
    @IBAction func perehod(_ sender: Any) {
        print("выключили поток запросов")
        if (typeMultigribNew || typeMultigribNewVM) {
//            requestStartParameters()
            print("правда deviceName.text: ", deviceName.text ?? 0)
            performSegue(withIdentifier: "goToAdvencesSettingsFesth", sender: nil)
        } else {
            performSegue(withIdentifier: "goToAdvencesSettings", sender: nil)
        }
        pauseReadData = false
        saveDataString(key: SensorsViewController.sampleGattAttributes.READ_THREAD_START, value: String(0))
    }
    @IBAction func perehod2(_ sender: Any) {
        print("выключили поток запросов")
        requestStartParameters()
        pauseReadData = false
        saveDataString(key: SensorsViewController.sampleGattAttributes.READ_THREAD_START, value: String(0))
    }
    
    
    static func sendDataToHC10 (dataForWrite: Data, characteristic: String, myCase: String) {
        SensorsViewController.dataForCommunicate["byteArray"] = dataForWrite.hexEncodedString()
        SensorsViewController.dataForCommunicate["characteristic"] = characteristic
        SensorsViewController.dataForCommunicate["type"] = SensorsViewController.sampleGattAttributes.WRITE_HC10
        SensorsViewController.dataForCommunicate["case"] = myCase
        NotificationCenter.default.post(name: .notificationFromSensorsViewController, object: nil, userInfo: SensorsViewController.dataForCommunicate)
    }
    static func sendDataToFESTH (dataForWrite: Data, characteristic: String) {
        self.dataForCommunicate["byteArray"] = dataForWrite.hexEncodedString()
        self.dataForCommunicate["characteristic"] = characteristic
        self.dataForCommunicate["type"] = SensorsViewController.sampleGattAttributes.WRITE
        NotificationCenter.default.post(name: .notificationFromSensorsViewController, object: nil, userInfo: self.dataForCommunicate)
    }
    private func readDataFromFESTH (characteristic: String) {
        SensorsViewController.dataForCommunicate["characteristic"] = characteristic
        SensorsViewController.dataForCommunicate["type"] = SensorsViewController.sampleGattAttributes.READ
        NotificationCenter.default.post(name: .notificationFromSensorsViewController, object: nil, userInfo: SensorsViewController.dataForCommunicate)
    }
    private func sendDataToINDY (dataForWrite: Data, characteristic: String) {
        SensorsViewController.dataForCommunicate["byteArray"] = dataForWrite.hexEncodedString()
        SensorsViewController.dataForCommunicate["characteristic"] = characteristic
        SensorsViewController.dataForCommunicate["type"] = SensorsViewController.sampleGattAttributes.WRITE
        NotificationCenter.default.post(name: .notificationFromSensorsViewController, object: nil, userInfo: SensorsViewController.dataForCommunicate)
    }
    static func readDataFrom (characteristic: String) {
        SensorsViewController.dataForCommunicate["characteristic"] = characteristic
        SensorsViewController.dataForCommunicate["type"] = SensorsViewController.sampleGattAttributes.READ
        NotificationCenter.default.post(name: .notificationFromSensorsViewController, object: nil, userInfo: SensorsViewController.dataForCommunicate)
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
        gradientLayer.frame = containerView.bounds
        containerView.layer.insertSublayer(gradientLayer, at: 0)
    }
    // MARK: - UI stule
    private func setupeButton (button: UIButton) {
        button.layer.cornerRadius = 21
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
    }
    // MARK: - работа с графиком
    func addEntry (sens1: Int, sens2: Int) {
        let data: ChartData = self.lineChartView.data!
        
        var set1 = data.getDataSetByIndex(1)
        var set2 = data.getDataSetByIndex(2)
        
        if (firstInit) {
            set1 = createSet1(values: values)
            set2 = createSet2(values: values)
            data.addDataSet(set1)
            data.addDataSet(set2)
            firstInit = false
        }
//        print("set1!.entryCount: \(set1!.entryCount)")
        if (set1!.entryCount >= 300) {
            zaglushka(bool1: (set1?.removeFirst())!)
            zaglushka(bool1: (set2?.removeFirst())!)
        }
        
        data.addEntry(ChartDataEntry(x: Double(self.count), y: Double(sens1)), dataSetIndex: 1)
        data.addEntry(ChartDataEntry(x: Double(self.count), y: Double(sens2)), dataSetIndex: 2)
        data.notifyDataChanged()
        self.lineChartView.notifyDataSetChanged()
        self.lineChartView.setVisibleXRangeMaximum(300)
        self.lineChartView.moveViewToX(Double(set2!.entryCount - 300))
        self.count += 1
    }
    func initChart() {
        var data = self.lineChartView.data
        let set1 = LineChartDataSet(values: [], label: "")
        data = LineChartData(dataSet: set1)
        var data2 = self.lineChartView.data
        let set2 = LineChartDataSet(values: [], label: "")
        data2 = LineChartData(dataSet: set2)
        self.lineChartView.data = data
        self.lineChartView.data = data2
        
        self.lineChartView.isExclusiveTouch = false
        self.lineChartView.isMultipleTouchEnabled = false
        self.lineChartView.dragEnabled = false
        self.lineChartView.dragDecelerationEnabled = false
        self.lineChartView.setScaleEnabled(false)
        self.lineChartView.drawGridBackgroundEnabled = false
        self.lineChartView.pinchZoomEnabled = false
        self.lineChartView.backgroundColor = UIColor(named: "transparent")
        self.lineChartView.legend.enabled = false
        self.lineChartView.animate(yAxisDuration: 0.7)
        
        let x: XAxis = self.lineChartView.xAxis
        x.labelTextColor = UIColor(named: "transparent")!
        x.drawGridLinesEnabled = false
        x.axisMaximum = 4000000
        x.avoidFirstLastClippingEnabled = true
        
        let y: YAxis = self.lineChartView.leftAxis
        y.axisMaximum = 255
        y.axisMinimum = 0
        y.labelTextColor = UIColor(named: "transparent")!
        y.drawGridLinesEnabled = true
        y.drawAxisLineEnabled = false
        y.gridColor = UIColor(named: "transparent")!
        self.lineChartView.rightAxis.axisLineColor = UIColor(named: "transparent")!
        self.lineChartView.rightAxis.labelTextColor = UIColor(named: "transparent")!
    }
    func createSet1(values: [ChartDataEntry]) -> LineChartDataSet {
        let set1 = LineChartDataSet(values: values, label: "")
        set1.axisDependency = YAxis.AxisDependency.left
        set1.lineWidth = 2
        set1.setColor(UIColor(named: "lineColor_open")!)
        set1.mode = LineChartDataSet.Mode.horizontalBezier
        set1.drawCirclesEnabled = false
        set1.drawValuesEnabled = false
        
        return set1
    }
    func createSet2(values: [ChartDataEntry]) -> LineChartDataSet {
        let set2 = LineChartDataSet(values: values, label: "")
        set2.axisDependency = YAxis.AxisDependency.left
        set2.lineWidth = 2
        set2.setColor(UIColor(named: "lineColor_close")!)
        set2.mode = LineChartDataSet.Mode.horizontalBezier
        set2.drawCirclesEnabled = false
        set2.drawValuesEnabled = false
        
        return set2
    }
    private func zaglushka(bool1: Bool) {    }

    private func requestStartParameters() {
        if (typeMultigribNew) {
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.DRIVER_VERSION_NEW, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.SENS_VERSION_NEW, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.OPEN_THRESHOLD_NEW, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.CLOSE_THRESHOLD_NEW, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.SENS_OPTIONS_NEW, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.SET_REVERSE_NEW, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.SET_ONE_CHANNEL_NEW, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.ADD_GESTURE_NEW, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.CALIBRATION_NEW, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.SHUTDOWN_CURRENT_NEW, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.SET_GESTURE_NEW, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
        }
        if (typeMultigribNewVM) {
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.DRIVER_VERSION_NEW_VM, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.SENS_VERSION_NEW_VM, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.OPEN_THRESHOLD_NEW_VM, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.CLOSE_THRESHOLD_NEW_VM, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.SENS_OPTIONS_NEW_VM, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.SET_REVERSE_NEW_VM, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.SET_ONE_CHANNEL_NEW_VM, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.ADD_GESTURE_NEW_VM, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.CALIBRATION_NEW_VM, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.SHUTDOWN_CURRENT_NEW_VM, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.SET_GESTURE_NEW_VM, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
            SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.ROTATION_GESTURE_NEW_VM, type: SensorsViewController.sampleGattAttributes.READ, myCase: "")
        }
    }
    private func initUI() {
        setupeButton(button: openBtn)
        setupeButton(button: closeBtn)
        var driverOn: Bool = false
        var bmsOn: Bool = false
        var sensorsOn: Bool = false
        var openThresholdOn: Bool = false
        var closeThresholdOn: Bool = false
        var sensOptions1On: Bool = false
        var sensOptions2On: Bool = false
        var lockAdvancedSettingsOn: Bool = false
        var shutdownCurrentOn: Bool = false
        var reverseOn: Bool = false
        var oneChannelOn: Bool = false
        var scaleOn: Bool = false
        var scaleFirstSetOn: Bool = false
        
        // проверка, есть ли значения переменных в памяти
        for item in savingParametrsMassString
        {
            if (item.key == SensorsViewController.sampleGattAttributes.DRIVER_NUM) {
                driverOn = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.BMS_NUM) {
                bmsOn = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SENS_NUM) {
                sensorsOn = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.OPEN_THRESHOLD_HDLE) {
                openThresholdOn = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.CLOSE_THRESHOLD_HDLE) {
                closeThresholdOn = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SENS_OPTIONS+"1") {
                sensOptions1On = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SENS_OPTIONS+"2") {
                sensOptions2On = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.OPEN_ADVANCED_SETTINGS) {
                lockAdvancedSettingsOn = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SHUTDOWN_CURRENT_HDLE) {
                shutdownCurrentOn = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SET_REVERSE) {
                reverseOn = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SET_ONE_CHANNEL) {
                oneChannelOn = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SCALE) {
                scaleOn = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SCALE_FIRST_SET) {
                scaleFirstSetOn = true
            }
        }
        
        // если переменная false, то её значения небыло в памяти телефона раньше и она
        // инициализируется дефолтным, заготовленным значением
        if (!driverOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.DRIVER_NUM, value: String(1))
            loadDataString()
        }
        if (!bmsOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.BMS_NUM, value: String(1))
            loadDataString()
        }
        if (!sensorsOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.SENS_NUM, value: String(1))
            loadDataString()
        }
        if (!openThresholdOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.OPEN_THRESHOLD_HDLE, value: String(30))
            loadDataString()
        }
        if (!closeThresholdOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.CLOSE_THRESHOLD_HDLE, value: String(30))
            loadDataString()
        }
        if (!sensOptions1On) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.SENS_OPTIONS+"1", value: String(22))
            loadDataString()
        }
        if (!sensOptions2On) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.SENS_OPTIONS+"2", value: String(22))
            loadDataString()
        }
        if (!lockAdvancedSettingsOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.OPEN_ADVANCED_SETTINGS, value: String(0))
            loadDataString()
        }
        if (!shutdownCurrentOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.SHUTDOWN_CURRENT_HDLE, value: String(1))
            loadDataString()
        }
        if (!reverseOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.SET_REVERSE, value: String(2))
            loadDataString()
        }
        if (!oneChannelOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.SET_ONE_CHANNEL, value: String(2))
            loadDataString()
        }
        if (!scaleOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.SCALE, value: String(4))
            loadDataString()
        }
        if (!scaleFirstSetOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.SCALE_FIRST_SET, value: String(2))
            loadDataString()
        }
        
        // чтение переменных из памяти
        for item in savingParametrsMassString
        {
            if (item.key == SensorsViewController.sampleGattAttributes.DRIVER_NUM) {
                driverText.text = "Driver  v " + String(Float(item.value)!/100)
                SensorsViewController.versionDriverNum = Float(item.value)!/100
            }
            if (item.key == SensorsViewController.sampleGattAttributes.BMS_NUM) {
                bmsText.text = "Bms       v " + String(Float(item.value)!/100)
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SENS_NUM) {
                sensersText.text = "Sensors v " + String(Float(item.value)!/100)
            }
            if (item.key == SensorsViewController.sampleGattAttributes.OPEN_THRESHOLD_HDLE) {
                openThreshold.setValue(Float(item.value)!, animated: true)
            }
            if (item.key == SensorsViewController.sampleGattAttributes.CLOSE_THRESHOLD_HDLE) {
                closeThreshold.setValue(Float(item.value)!, animated: true)
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SENS_OPTIONS+"1") {
                openSensNum.text = String(255 - Int(item.value)!)
                openSensSlide.setValue(255 - Float(item.value)!, animated: true)
                open_sens_slide = UInt8(Int(item.value)!)
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SENS_OPTIONS+"2") {
                closeSensNum.text = String(255 - Int(item.value)!)
                closeSensSlide.setValue(255 - Float(item.value)!, animated: true)
                close_sens_slide = UInt8(Int(item.value)!)
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SET_REVERSE) {
                if (Int(item.value) == 1) {
                    swapSensText.text = "on"
                    swapSensSwitch.setOn(true, animated: true)
                } else {
                    swapSensText.text = "off"
                    swapSensSwitch.setOn(false, animated: true)
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SETTINGS_BLOKING) {
                if (Int(item.value) == 1) {
                    bloskSettingsText.text = "on"
                    blockChangeSettings = true
                    blockSettingsSwitch.setOn(true, animated: true)
                } else {
                    bloskSettingsText.text = "off"
                    blockChangeSettings = false
                    blockSettingsSwitch.setOn(false, animated: true)
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SWAP_BUTTONS_OPEN_CLOSE) {
                if (Int(item.value) == 1) {
                    swapButtonOpenClose = true
                } else {
                    swapButtonOpenClose = false
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.READ_THREAD_START) {
                if (Int(item.value) == 1) {
                    pauseReadData = true
//                    print("запуск потока чтения initUI")
                } else {
                    pauseReadData = false
//                    print("остановка потока чтения initUI")
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.DEVICE_NAME){
                if (savingDeviceName != item.value) {
                    deviceName.text = item.value
                    savingDeviceName = item.value
                    deviceName.text = savingDeviceName
                    if ( savingDeviceName == "FEST-A" || savingDeviceName == "BT05" || savingDeviceName == "Redmi" ||
                            savingDeviceName == "FEST-F" || savingDeviceName == SensorsViewController.sampleGattAttributes.FESTH_NAME || savingDeviceName == SensorsViewController.sampleGattAttributes.FESTX_NAME) {
                        typeMultigrib = true
                        if (savingDeviceName == SensorsViewController.sampleGattAttributes.FESTX_NAME) {
                            print("FEST-X activated")
                            typeMultigribNewVM = true
                            saveDataString(key: SensorsViewController.sampleGattAttributes.USE_MULTIGRAB_FESTX, value: String(1))
                        }
                        if (savingDeviceName == SensorsViewController.sampleGattAttributes.FESTH_NAME) {
                            typeMultigribNew = true
                            saveDataString(key: SensorsViewController.sampleGattAttributes.USE_MULTIGRAB_FESTH, value: String(1))
                        }
                        saveDataString(key: SensorsViewController.sampleGattAttributes.USE_MULTIGRAB, value: SensorsViewController.sampleGattAttributes.USE)
                        print("Multigrib mode activated!")
                    } else {
                        saveDataString(key: SensorsViewController.sampleGattAttributes.USE_MULTIGRAB, value: String(0))
                        gestureSettingsBtn.isHidden = true
                    }
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.OPEN_ADVANCED_SETTINGS) {
                if (Int(item.value) != 1) {
                    lockAdvancedSettings = true
//                    advancedSettingsBtn.isHidden = true
                } else {
                    lockAdvancedSettings = false
//                    advancedSettingsBtn.isHidden = false
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SCALE_FIRST_SET) {
                
            }
        }
        
        openThresholdView.transform = CGAffineTransform.init(translationX: 0, y: -(CGFloat(openThreshold.value)/1.05))
        closeThresholdView.transform = CGAffineTransform.init(translationX: 0, y: -(CGFloat(closeThreshold.value)/1.05))
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
                if (!typeMultigribNew) {
                    if (!typeMultigribNewVM) {
                        SensorsViewController.myInteractiveQueueComand(dataForWrite: dataForWrite, characteristic: characteristic, type: type, myCase: myCase)
                    }
                }
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
                print("write to FEST-H or FEST-X")
                sendDataToFESTH(dataForWrite: dataForWrite, characteristic: characteristic)
            }
            if (type == sampleGattAttributes.WRITE_HC10) {
                print("write to HC10")
                sendDataToHC10 (dataForWrite: dataForWrite, characteristic: characteristic, myCase: myCase)
            } else if (type == sampleGattAttributes.READ) {
                print("read")
                readDataFrom(characteristic: characteristic)
            }
        }
        operation1.completionBlock = { [self] in
            if (!flagReadData) {
                flagReadData = true
            }
        }
        operationQueue.addOperations([operation1], waitUntilFinished: true)
    }
    
    
    // MARK: - отправка команд с проверкой
    @objc static func myInteractiveQueueComandWithConfirmation(dataForWrite: Data, characteristic: String, countRestart: Int) {
        inactiveQueue2.async {
            self.semafore2.wait()
            self.comandQueue2(dataForWrite: dataForWrite, characteristic: characteristic, countRestart: countRestart)
            self.semafore2.signal()
        }
        inactiveQueue2.activate()
    }
    // MARK:  функция при вызове начинает генерировать команды
    // MARK:  на чтение данных и дбавлять их в очередь команд
    static let operationQueue2 = OperationQueue()
    static func comandQueue2(dataForWrite: Data, characteristic: String, countRestart: Int) {
        let operation1 = BlockOperation() { [self] in
            //TODO код запроса информационных данных
            self.expectedReceiveConfirmation = 1
            let formedId = characteristic.prefix(8).suffix(4)
            var countRestartLocal = countRestart
            var countAttempt = 0
            self.expectedIdCommand = String(formedId)
            
            while(self.expectedReceiveConfirmation != 2) {
                if (countRestartLocal > 0) {
                    
                    sendDataToFESTH(dataForWrite: dataForWrite, characteristic: characteristic)
                    usleep(100000)
                    countRestartLocal -= 1
                    countAttempt += 1
                    countAttempts = countAttempt
                    
                    if (countAttempt == 1) { oneAttempt += 1 }
                    if (countAttempt == 2) {
                        oneAttempt -= 1
                        twoAttempts += 1
                    }
                    if (countAttempt == 3) {
                        twoAttempts -= 1
                        threeAttempts += 1
                    }
                    if (countAttempt == 4) {
                        threeAttempts -= 1
                        fourAttempts += 1
                    }
                    if (countAttempt == 5) {
                        fourAttempts -= 1
                        fiveAttempts += 1
                    }
                    
                    //если протокол старый, то после отправки команды не ждём подтверждения
                    if (versionDriverNum < 2.34) {
                        countRestartLocal = 0
                    }
                } else {
                    return
                }
            }
        }
        operation1.completionBlock = {
            self.expectedReceiveConfirmation = 0
            print("==============================================================================")
            print("    one attempt = \(SensorsViewController.oneAttempt) \n",
                  "    two attempts = \(SensorsViewController.twoAttempts) \n",
                  "    three attempts = \(SensorsViewController.threeAttempts) \n",
                  "    four attempts = \(SensorsViewController.fourAttempts) \n",
                  "    five attempts = \(SensorsViewController.fiveAttempts) \n",
                  "    real attempts = \(SensorsViewController.countAttempts)")
            print("==============================================================================")
        }
        operationQueue2.addOperations([operation1], waitUntilFinished: true)
    }
}

extension Notification.Name {
    static let notificationReseiveBLEData = Notification.Name(rawValue: "notificationReseiveBLEData")
}

extension Notification.Name {
    static let notificationCheckStateConnection = Notification.Name(rawValue: "notificationCheckStateConnection")
}

extension Notification.Name {
    static let notificationUpdateAdvancedSettings = Notification.Name(rawValue: "notificationUpdateAdvancedSettings")
}

extension Notification.Name {
    static let notificationDataDialogToSensorsView = Notification.Name(rawValue: "notificationDataDialogToSensorsView")
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

