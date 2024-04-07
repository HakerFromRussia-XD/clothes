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
    
    @IBOutlet weak var titleBreast: UILabel!
    @IBOutlet weak var breastStack: UIStackView!
    @IBOutlet weak var realValueBreast: UIButton!
    @IBOutlet weak var targetValueBreast: UIButton!
    @IBOutlet weak var onOffSwitchBreast: UISwitch!
    @IBOutlet weak var sliderBreast: UISlider!
    @IBOutlet weak var activationStatusBreast: UILabel!
    
    @IBOutlet weak var titleBack: UILabel!
    @IBOutlet weak var backStack: UIStackView!
    @IBOutlet weak var realValueBack: UIButton!
    @IBOutlet weak var targetValueBack: UIButton!
    @IBOutlet weak var onOffSwitchBack: UISwitch!
    @IBOutlet weak var sliderBack: UISlider!
    @IBOutlet weak var activationStatusBack: UILabel!
    
    @IBOutlet weak var titleShoulders: UILabel!
    @IBOutlet weak var shouldersStack: UIStackView!
    @IBOutlet weak var realValueShoulders: UIButton!
    @IBOutlet weak var targetValueShoulders: UIButton!
    @IBOutlet weak var onOffSwitchShoulders: UISwitch!
    @IBOutlet weak var sliderShoulders: UISlider!
    @IBOutlet weak var activationStatusShoulders: UILabel!
    
    @IBOutlet weak var titleBelt: UILabel!
    @IBOutlet weak var beltStack: UIStackView!
    @IBOutlet weak var realValueBelt: UIButton!
    @IBOutlet weak var targetValueBelt: UIButton!
    @IBOutlet weak var onOffSwitchBelt: UISwitch!
    @IBOutlet weak var sliderBelt: UISlider!
    @IBOutlet weak var activationStatusBelt: UILabel!
    
    @IBOutlet weak var voiceStack: UIStackView!
    @IBOutlet weak var voiceSwitch: UISwitch!

    @IBOutlet weak var batteryStack: UIStackView!
    @IBOutlet weak var batteryPercent: UILabel!
    @IBOutlet weak var batterySlider: CustomSlider!
    
    
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
    
    
    var realTemperature = ""
    var targetTemperature = ""
    var operationMode = ""
    var statusModules = ""
    var batteryCharge = ""
    var voice = ""
    
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
    
    //тут дописать приём остальных данных
    @objc func updatingUINotification(notification: Notification) {
        guard let dataForWrite = notification.userInfo,
              let real_temperature = dataForWrite["real_temperature"] as? String,
              let target_temperature = dataForWrite["target_temperature"] as? String,
              let operation_mode = dataForWrite["operation_mode"] as? String,
              let status_modules = dataForWrite["status_modules"] as? String,
              let battery_charge = dataForWrite["battery_charge"] as? String,
              let voice = dataForWrite["voice"] as? String
        else { return }

        
        for item in savingParametrsMassString {
            if (item.key == SensorsViewController.sampleGattAttributes.GET_REAL_TEMPERATURE_USE) {
                if (item.value != real_temperature){
                    print("обновили данные реальной температуры: "+real_temperature)
                    saveDataString(key: item.key, value: String(real_temperature))
                    loadDataString()
                    initUI()
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE) {
                if (item.value != target_temperature){
                    print("обновили данные целевой температуры: "+target_temperature)
                    saveDataString(key: item.key, value: String(target_temperature))
                    loadDataString()
                    initUI()
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SET_OPERATION_MODE_USE ) {
                if (item.value != operation_mode){
                    print("обновили данные режима работы: "+operation_mode)
                    saveDataString(key: item.key, value: String(operation_mode))
                    loadDataString()
                    initUI()
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.GET_STATUS_MODULES_USE ) {
                if (item.value != status_modules){
                    print("обновили данные статуса модулей: "+status_modules)
                    saveDataString(key: item.key, value: String(status_modules))
                    loadDataString()
                    initUI()
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.GET_BATTERY_CHARGE_USE ) {
                if (item.value != battery_charge){
                    print("обновили данные заряда батареи: "+battery_charge)
                    saveDataString(key: item.key, value: String(battery_charge))
                    loadDataString()
                    initUI()
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SET_VOICE_USE ) {
                if (item.value != voice){
                    print("обновили данные голоса: "+voice)
                    saveDataString(key: item.key, value: String(voice))
                    loadDataString()
                    initUI()
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
    @IBAction func activateBreast(_ sender: UISwitch) {
        var separatedString = operationMode.components(separatedBy: " ")
        
        if (separatedString.count >= SensorsViewController.sampleGattAttributes.NUMBER_MODULES) {
            var data = Data([])
            if (sender.isOn) {
                separatedString[0] = "1"
            } else {
                separatedString[0] = "0"
            }
            for i in 0...(SensorsViewController.sampleGattAttributes.NUMBER_MODULES-1) {
                data.append(UInt8(separatedString[i])!)
            }
            SensorsViewController.myInteractiveQueueComand(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_OPERATION_MODE_USE, type: SensorsViewController.sampleGattAttributes.WRITE)
            saveDataString(key: SensorsViewController.sampleGattAttributes.SET_OPERATION_MODE_USE,
                           value: separatedString[0]+" "+separatedString[1]+" "+separatedString[2]+" "+separatedString[3])
            loadDataString()
            readAllData ()
        }
    }
    @IBAction func activateBack(_ sender: UISwitch) {
        var separatedString = operationMode.components(separatedBy: " ")
    
        if (separatedString.count >= SensorsViewController.sampleGattAttributes.NUMBER_MODULES) {
            var data = Data([])
            if (sender.isOn) {
                separatedString[1] = "1"
            } else {
                separatedString[1] = "0"
            }
            for i in 0...(SensorsViewController.sampleGattAttributes.NUMBER_MODULES-1) {
                data.append(UInt8(separatedString[i])!)
            }
            SensorsViewController.myInteractiveQueueComand(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_OPERATION_MODE_USE, type: SensorsViewController.sampleGattAttributes.WRITE)
            saveDataString(key: SensorsViewController.sampleGattAttributes.SET_OPERATION_MODE_USE,
                           value: separatedString[0]+" "+separatedString[1]+" "+separatedString[2]+" "+separatedString[3])
            loadDataString()
            readAllData ()
        }
    }
    @IBAction func activateShoulders(_ sender: UISwitch) {
        var separatedString = operationMode.components(separatedBy: " ")
        
        if (separatedString.count >= SensorsViewController.sampleGattAttributes.NUMBER_MODULES) {
            var data = Data([])
            if (sender.isOn) {
                separatedString[2] = "1"
            } else {
                separatedString[2] = "0"
            }
            for i in 0...(SensorsViewController.sampleGattAttributes.NUMBER_MODULES-1) {
                data.append(UInt8(separatedString[i])!)
            }
            SensorsViewController.myInteractiveQueueComand(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_OPERATION_MODE_USE, type: SensorsViewController.sampleGattAttributes.WRITE)
            saveDataString(key: SensorsViewController.sampleGattAttributes.SET_OPERATION_MODE_USE,
                           value: separatedString[0]+" "+separatedString[1]+" "+separatedString[2]+" "+separatedString[3])
            loadDataString()
            readAllData ()
        }
    }
    @IBAction func activateBelt(_ sender: UISwitch) {
        var separatedString = operationMode.components(separatedBy: " ")
        
        if (separatedString.count >= SensorsViewController.sampleGattAttributes.NUMBER_MODULES) {
            var data = Data([])
            if (sender.isOn) {
                separatedString[3] = "1"
            } else {
                separatedString[3] = "0"
            }
            for i in 0...(SensorsViewController.sampleGattAttributes.NUMBER_MODULES-1) {
                data.append(UInt8(separatedString[i])!)
            }
            SensorsViewController.myInteractiveQueueComand(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_OPERATION_MODE_USE, type: SensorsViewController.sampleGattAttributes.WRITE)
            saveDataString(key: SensorsViewController.sampleGattAttributes.SET_OPERATION_MODE_USE,
                           value: separatedString[0]+" "+separatedString[1]+" "+separatedString[2]+" "+separatedString[3])
            loadDataString()
            readAllData ()
        }
    }
    @IBAction func activateVoice(_ sender: UISwitch) {
        var data = Data([])
        if (sender.isOn) {
            data = Data([1])
        } else {
            data = Data([0])
        }
        SensorsViewController.myInteractiveQueueComand(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_VOICE_USE, type: SensorsViewController.sampleGattAttributes.WRITE)
        readAllData ()
    }
    
    @IBAction func breastSlide(_ sender: UISlider) {
        targetValueBreast.titleLabel?.text = String(Int(sender.value))
        var separatedString = targetTemperature.components(separatedBy: " ")
        
        separatedString[0] = String(Int(sender.value))
        saveDataString(key: SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE,
                       value: separatedString[0]+" "+separatedString[1]+" "+separatedString[2]+" "+separatedString[3])
        loadDataString()
        initUI()
    }
    @IBAction func backSlide(_ sender: UISlider) {
        targetValueBack.titleLabel?.text = String(Int(sender.value))
        var separatedString = targetTemperature.components(separatedBy: " ")
        
        separatedString[1] = String(Int(sender.value))
        saveDataString(key: SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE,
                       value: separatedString[0]+" "+separatedString[1]+" "+separatedString[2]+" "+separatedString[3])
        loadDataString()
        initUI()
    }
    @IBAction func shouldersSlide(_ sender: UISlider) {
        targetValueShoulders.titleLabel?.text = String(Int(sender.value))
        var separatedString = targetTemperature.components(separatedBy: " ")
        
        separatedString[2] = String(Int(sender.value))
        saveDataString(key: SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE,
                       value: separatedString[0]+" "+separatedString[1]+" "+separatedString[2]+" "+separatedString[3])
        loadDataString()
        initUI()
    }
    @IBAction func beltSlide(_ sender: UISlider) {
        targetValueBelt.titleLabel?.text = String(Int(sender.value))
        var separatedString = targetTemperature.components(separatedBy: " ")
        
        separatedString[3] = String(Int(sender.value))
        saveDataString(key: SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE,
                       value: separatedString[0]+" "+separatedString[1]+" "+separatedString[2]+" "+separatedString[3])
        loadDataString()
        initUI()
    }
    
    
    @IBAction func breastSlideStop(_ sender: UISlider) {
        var separatedString = targetTemperature.components(separatedBy: " ")
        
        if (separatedString.count >= SensorsViewController.sampleGattAttributes.NUMBER_MODULES) {
            //изменение загруженных данных
            separatedString[0] = String(Int(sender.value))
            
            
            //формирование и отправка массива байт для отправки
            var data = Data([])
            for i in 0...(SensorsViewController.sampleGattAttributes.NUMBER_MODULES-1) {
                data.append(UInt8(separatedString[i])!)
            }
            SensorsViewController.myInteractiveQueueComand(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE, type: SensorsViewController.sampleGattAttributes.WRITE)
            
            //сохранение изменённых нами данных
            saveDataString(key: SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE,
                                       value: separatedString[0]+" "+separatedString[1]+" "+separatedString[2]+" "+separatedString[3])
            loadDataString()

            //запрос обновления всех данных
            readAllData ()
        }
    }
    @IBAction func backSlideStop(_ sender: UISlider) {
        var separatedString = targetTemperature.components(separatedBy: " ")
        
        if (separatedString.count >= SensorsViewController.sampleGattAttributes.NUMBER_MODULES) {
            //изменение загруженных данных
            separatedString[1] = String(Int(sender.value))
            
            
            //формирование и отправка массива байт для отправки
            var data = Data([])
            for i in 0...(SensorsViewController.sampleGattAttributes.NUMBER_MODULES-1) {
                data.append(UInt8(separatedString[i])!)
            }
            SensorsViewController.myInteractiveQueueComand(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE, type: SensorsViewController.sampleGattAttributes.WRITE)
            
            //сохранение изменённых нами данных
            saveDataString(key: SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE,
                                       value: separatedString[0]+" "+separatedString[1]+" "+separatedString[2]+" "+separatedString[3])
            loadDataString()

            //запрос обновления всех данных
            readAllData ()
        }
    }
    @IBAction func shouldersSlideStop(_ sender: UISlider) {
        var separatedString = targetTemperature.components(separatedBy: " ")
        
        if (separatedString.count >= SensorsViewController.sampleGattAttributes.NUMBER_MODULES) {
            //изменение загруженных данных
            separatedString[2] = String(Int(sender.value))
            
            
            //формирование и отправка массива байт для отправки
            var data = Data([])
            for i in 0...(SensorsViewController.sampleGattAttributes.NUMBER_MODULES-1) {
                data.append(UInt8(separatedString[i])!)
            }
            SensorsViewController.myInteractiveQueueComand(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE, type: SensorsViewController.sampleGattAttributes.WRITE)
            
            //сохранение изменённых нами данных
            saveDataString(key: SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE,
                                       value: separatedString[0]+" "+separatedString[1]+" "+separatedString[2]+" "+separatedString[3])
            loadDataString()

            //запрос обновления всех данных
            readAllData ()
        }
    }
    @IBAction func beltSlideStop(_ sender: UISlider) {
        var separatedString = targetTemperature.components(separatedBy: " ")
        
        if (separatedString.count >= SensorsViewController.sampleGattAttributes.NUMBER_MODULES) {
            //изменение загруженных данных
            separatedString[3] = String(Int(sender.value))
            
            
            //формирование и отправка массива байт для отправки
            var data = Data([])
            for i in 0...(SensorsViewController.sampleGattAttributes.NUMBER_MODULES-1) {
                data.append(UInt8(separatedString[i])!)
            }
            SensorsViewController.myInteractiveQueueComand(dataForWrite: data, characteristic: SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE, type: SensorsViewController.sampleGattAttributes.WRITE)
            
            //сохранение изменённых нами данных
            saveDataString(key: SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE,
                                       value: separatedString[0]+" "+separatedString[1]+" "+separatedString[2]+" "+separatedString[3])
            loadDataString()

            //запрос обновления всех данных
            readAllData ()
        }
    }
    
    
    
    
    
    
    private func readAllData () {
        SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE, type: SensorsViewController.sampleGattAttributes.READ)
        SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.GET_REAL_TEMPERATURE_USE, type: SensorsViewController.sampleGattAttributes.READ)
        SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.SET_OPERATION_MODE_USE, type: SensorsViewController.sampleGattAttributes.READ)
        SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.GET_STATUS_MODULES_USE, type: SensorsViewController.sampleGattAttributes.READ)
        
        SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.GET_BATTERY_CHARGE_USE, type: SensorsViewController.sampleGattAttributes.READ)
        SensorsViewController.myInteractiveQueueComand(dataForWrite: Data([]), characteristic: SensorsViewController.sampleGattAttributes.SET_VOICE_USE, type: SensorsViewController.sampleGattAttributes.READ)
    }
    
    // MARK: - UI stule
    private func setupeButton (button: UIButton) {
        button.layer.cornerRadius = 15
        button.titleLabel?.font =  UIFont(name: "OpenSans-Bold", size: 12)
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.black.cgColor
    }
    private func setupeSwitch (mySwitch: UISwitch, colorBorder: CGColor?) {
        mySwitch.layer.cornerRadius = 15
        mySwitch.layer.borderWidth = 2
        mySwitch.layer.borderColor = colorBorder
    }
    private func setupeStakeView (stack: UIStackView) {
        stack.layer.cornerRadius = 21
        stack.layer.borderWidth = 2
        stack.layer.borderColor = UIColor.black.cgColor
    }
    // MARK: - инициализация UI
    private func initUI() {
        setupeButton(button: realValueBreast)
        setupeButton(button: targetValueBreast)
        setupeStakeView (stack: breastStack)
        
        setupeButton(button: realValueBack)
        setupeButton(button: targetValueBack)
        setupeStakeView (stack: backStack)
        
        setupeButton(button: realValueShoulders)
        setupeButton(button: targetValueShoulders)
        setupeStakeView (stack: shouldersStack)
        
        setupeButton(button: realValueBelt)
        setupeButton(button: targetValueBelt)
        setupeStakeView (stack: beltStack)
        
        setupeStakeView(stack: voiceStack)
        
        setupeStakeView(stack: batteryStack)
        
        var realTemperatureOn: Bool = false
        var targetTemperatureOn: Bool = false
        var operationModeOn: Bool = false
        var statusOn: Bool = false
        var batteryChargeOn: Bool = false
        var voiceOn: Bool = false
        // проверка, есть ли значения переменных в памяти
        for item in savingParametrsMassString
        {
            if (item.key == SensorsViewController.sampleGattAttributes.GET_REAL_TEMPERATURE_USE) {
                realTemperatureOn = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE) {
                targetTemperatureOn = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SET_OPERATION_MODE_USE) {
                operationModeOn = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.GET_STATUS_MODULES_USE) {
                statusOn = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.GET_BATTERY_CHARGE_USE) {
                batteryChargeOn = true
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SET_VOICE_USE) {
                voiceOn = true
            }
        }
        
        if (!realTemperatureOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.GET_REAL_TEMPERATURE_USE, value: String("1 2 3 4"))
            loadDataString()
        }
        if (!targetTemperatureOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE, value: String("0 1 2 3"))
            loadDataString()
        }
        if (!operationModeOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.SET_OPERATION_MODE_USE, value: String("0 1 2 0"))
            loadDataString()
        }
        if (!statusOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.GET_STATUS_MODULES_USE, value: String("0 1 0 1"))
            loadDataString()
        }
        if (!batteryChargeOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.GET_BATTERY_CHARGE_USE, value: String("50"))
            loadDataString()
        }
        if (!voiceOn) {
            saveDataString(key: SensorsViewController.sampleGattAttributes.SET_VOICE_USE, value: String("0"))
            loadDataString()
        }
        
        
        for item in savingParametrsMassString
        {
            if (item.key == SensorsViewController.sampleGattAttributes.DEVICE_NAME){
                if (savingDeviceName != item.value) {
                    savingDeviceName = item.value
                    deviceName.text = savingDeviceName
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.GET_REAL_TEMPERATURE_USE) {
                realTemperature = item.value
                let separatedString = item.value.components(separatedBy: " ")
                print("separatedString "+separatedString[0])
                
                if (separatedString.count >= 4){
                    realValueBreast.setTitle(separatedString[0] , for: .normal)
                    realValueBack.setTitle(separatedString[1] , for: .normal)
                    realValueShoulders.setTitle(separatedString[2] , for: .normal)
                    realValueBelt.setTitle(separatedString[3] , for: .normal)
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SET_TARGET_TEMPERATURE_USE) {
                targetTemperature = item.value
                let separatedString = item.value.components(separatedBy: " ")
                print("separatedString "+separatedString[0])
                
                if (separatedString.count >= 4){
                    targetValueBreast.setTitle(separatedString[0] , for: .normal)
                    targetValueBack.setTitle(separatedString[1] , for: .normal)
                    targetValueShoulders.setTitle(separatedString[2] , for: .normal)
                    targetValueBelt.setTitle(separatedString[3] , for: .normal)
                    
                    sliderBreast.value = Float(separatedString[0]) ?? 0
                    sliderBack.value = Float(separatedString[1]) ?? 0
                    sliderShoulders.value = Float(separatedString[2]) ?? 0
                    sliderBelt.value = Float(separatedString[3]) ?? 0
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SET_OPERATION_MODE_USE) {
                operationMode = item.value
                let separatedString = item.value.components(separatedBy: " ")
                print("separatedString "+separatedString[0])
      
                if (separatedString.count >= 4){
                    setOperationMode(lable: activationStatusBreast, mySwitch: onOffSwitchBreast, mode: separatedString[0])
                    setOperationMode(lable: activationStatusBack, mySwitch: onOffSwitchBack, mode: separatedString[1])
                    setOperationMode(lable: activationStatusShoulders, mySwitch: onOffSwitchShoulders, mode: separatedString[2])
                    setOperationMode(lable: activationStatusBelt, mySwitch: onOffSwitchBelt, mode: separatedString[3])
                }
            }
            if (item.key == SensorsViewController.sampleGattAttributes.GET_STATUS_MODULES_USE) {
                statusModules = item.value
                let separatedString = item.value.components(separatedBy: " ")
                print("separatedString "+separatedString[0])
                
                if (separatedString.count >= 4){
                    setStatus(lable: titleBreast, mySwitch: onOffSwitchBreast, mode: separatedString[0] )
                    setStatus(lable: titleBack, mySwitch: onOffSwitchBack, mode: separatedString[1])
                    setStatus(lable: titleShoulders, mySwitch: onOffSwitchShoulders, mode: separatedString[2])
                    setStatus(lable: titleBelt, mySwitch: onOffSwitchBelt, mode: separatedString[3])
                }
            }
            
            if (item.key == SensorsViewController.sampleGattAttributes.GET_BATTERY_CHARGE_USE) {
                batterySlider.value = Float(item.value) ?? 50
                batteryPercent.text = item.value+"%"
            }
            if (item.key == SensorsViewController.sampleGattAttributes.SET_VOICE_USE) {
                switch item.value {
                case "0":
                    print("SET_VOICE_USE: "+item.value)
                    voiceSwitch.isOn = false
                case "1":
                    print("SET_VOICE_USE: "+item.value)
                    voiceSwitch.isOn = true
                default:
                    print("SET_VOICE_USE: default "+item.value)
                    return
                }
            }
        }
    }
    private func setStatus(lable: UILabel, mySwitch: UISwitch, mode: String) {
        switch mode {
        case "0":
            if (lable.text?.components(separatedBy: " ").count ?? 2 > 1){
                lable.text = lable.text?.components(separatedBy: " ")[0]
            }
            lable.textColor = .black
            mySwitch.isEnabled = true
        case "1":
            if (lable.text?.components(separatedBy: " ").count ?? 2 < 2){
                lable.text! = (lable.text ?? "Блок")+" (неисправен)"
            }
            lable.textColor = .red
            mySwitch.isEnabled = false
        default:
            return
        }
    }
    private func setOperationMode(lable: UILabel, mySwitch: UISwitch, mode: String) {
        switch mode {
        case "0":
            lable.text = ""
            mySwitch.isOn = false
            mySwitch.onTintColor = .black
        case "1":
            lable.text = "включён"
            mySwitch.isOn = true
            mySwitch.onTintColor = .black
        case "2":
            lable.text = "ожидание"
            mySwitch.isOn = true
            mySwitch.onTintColor = UIColor(named: "dark_yellow")
        default:
            return
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
    @objc static func myInteractiveQueueComand(dataForWrite: Data, characteristic: String, type: String) {
        inactiveQueue.async {
            self.semafore.wait()
            self.flagReadData = false
            self.comandQueue(dataForWrite: dataForWrite, characteristic: characteristic, type: type)
            self.semafore.signal()
        }
        inactiveQueue.activate()
    }
    // MARK:  функция при вызове начинает генерировать команды
    // MARK:  на чтение данных и дбавлять их в очередь команд
    func myInteractiveQueueReadData(dataForWrite: Data, characteristic: String, type: String) {
        SensorsViewController.inactiveQueue.async { [self] in
            while (SensorsViewController.flagReadData && pauseReadData) {
                usleep(delayForReadData)
            }
        }
        SensorsViewController.inactiveQueue.activate()
    }
    static let operationQueue = OperationQueue()
    static func comandQueue(dataForWrite: Data, characteristic: String, type: String) {
        let operation1 = BlockOperation() { [self] in
            usleep(queueInterval)
            //TODO код запроса информационных данных
            if (type == sampleGattAttributes.WRITE) {
                print("write")
                writeDataTo(dataForWrite: dataForWrite, characteristic: characteristic)
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
    static func writeDataTo (dataForWrite: Data, characteristic: String) {
        self.dataForCommunicate["byteArray"] = dataForWrite.hexEncodedString()
        self.dataForCommunicate["characteristic"] = characteristic
        self.dataForCommunicate["type"] = SensorsViewController.sampleGattAttributes.WRITE
        NotificationCenter.default.post(name: .notificationFromSensorsViewController, object: nil, userInfo: self.dataForCommunicate)
    }
    static func readDataFrom (characteristic: String) {
        SensorsViewController.dataForCommunicate["characteristic"] = characteristic
        SensorsViewController.dataForCommunicate["type"] = SensorsViewController.sampleGattAttributes.READ
        NotificationCenter.default.post(name: .notificationFromSensorsViewController, object: nil, userInfo: SensorsViewController.dataForCommunicate)
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

