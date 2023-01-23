//
//  DialogCalibrationStatusViewController.swift
//  MotoricaStart
//
//  Created by Motorica LLC on 14.07.2022.
//  Copyright © 2022 Brian Advent. All rights reserved.
//

import UIKit


class DialogCalibrationStatusViewController: UIViewController {
    @IBOutlet weak var backgraudView: UIVisualEffectView!
    @IBOutlet weak var statusFinger1: UILabel!
    @IBOutlet weak var encoderSteps1: UILabel!
    @IBOutlet weak var current1: UILabel!
    @IBOutlet weak var statusFinger2: UILabel!
    @IBOutlet weak var encoderSteps2: UILabel!
    @IBOutlet weak var current2: UILabel!
    @IBOutlet weak var statusFinger3: UILabel!
    @IBOutlet weak var encoderSteps3: UILabel!
    @IBOutlet weak var current3: UILabel!
    @IBOutlet weak var statusFinger4: UILabel!
    @IBOutlet weak var encoderSteps4: UILabel!
    @IBOutlet weak var current4: UILabel!
    @IBOutlet weak var statusFinger5: UILabel!
    @IBOutlet weak var encoderSteps5: UILabel!
    @IBOutlet weak var current5: UILabel!
    @IBOutlet weak var statusFinger6: UILabel!
    @IBOutlet weak var encoderSteps6: UILabel!
    @IBOutlet weak var current6: UILabel!
    
    
    private var savingParametrsMassString:[SaveObjectString]!
    let sampleGattAttributes = SampleGattAttributes()
    private var dataForCommunicateRead = ["byteArray": "01020304", "characteristic":"1", "type":"READ"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgraudView.layer.cornerRadius = 10;
        backgraudView.layer.masksToBounds = true;

        readDataFromFestX(characteristic: sampleGattAttributes.STATUS_CALIBRATION_NEW_VM)
        initUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updatingUI), name: .notificationReseiveBLEDataCalibrationStatus, object: nil)
    }
    @IBAction func tapClose(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

    private func readDataFromFestX (characteristic: String) {
        self.dataForCommunicateRead["characteristic"] = characteristic
        self.dataForCommunicateRead["type"] = sampleGattAttributes.READ
        self.dataForCommunicateRead["case"] = "0"
        NotificationCenter.default.post(name: .notificationFromSensorsViewController, object: nil, userInfo: self.dataForCommunicateRead)
    }
    
    
    private func initUI() {
        loadDataString()
        for item in savingParametrsMassString
        {
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_FINGER+"1")) {
                statusFinger1.text = "status finger 1: " + item.value
            }
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_FINGER+"2")) {
                statusFinger2.text = "status finger 2: " + item.value
            }
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_FINGER+"3")) {
                statusFinger3.text = "status finger 3: " + item.value
            }
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_FINGER+"4")) {
                statusFinger4.text = "status finger 4: " + item.value
            }
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_FINGER+"5")) {
                statusFinger5.text = "status finger 5: " + item.value
            }
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_FINGER+"6")) {
                statusFinger6.text = "status finger 6: " + item.value
            }
            
            
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_ENCODER_FINGER+"1")) {
                encoderSteps1.text = "encoder steps: " + item.value
            }
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_ENCODER_FINGER+"2")) {
                encoderSteps2.text = "encoder steps: " + item.value
            }
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_ENCODER_FINGER+"3")) {
                encoderSteps3.text = "encoder steps: " + item.value
            }
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_ENCODER_FINGER+"4")) {
                encoderSteps4.text = "encoder steps: " + item.value
            }
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_ENCODER_FINGER+"5")) {
                encoderSteps5.text = "encoder steps: " + item.value
            }
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_ENCODER_FINGER+"6")) {
                encoderSteps6.text = "encoder steps: " + item.value
            }
            
            
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_CURRENT_FINGER+"1")) {
                current1.text = "current: " + item.value
            }
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_CURRENT_FINGER+"2")) {
                current2.text = "current: " + item.value
            }
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_CURRENT_FINGER+"3")) {
                current3.text = "current: " + item.value
            }
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_CURRENT_FINGER+"4")) {
                current4.text = "current: " + item.value
            }
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_CURRENT_FINGER+"5")) {
                current5.text = "current: " + item.value
            }
            if (item.key == (sampleGattAttributes.CALIBRATION_STATUS_CURRENT_FINGER+"6")) {
                current6.text = "current: " + item.value
            }
        }
    }
    private func loadDataString() {
        savingParametrsMassString = [SaveObjectString]()
        savingParametrsMassString = DataManager.loadAll(SaveObjectString.self)
    }
    private func saveDataString(key: String, value: String) {
        let saveObjectString = SaveObjectString(key: key, value: value)
        print("save   key: \(key) value: \(value)")
        DataManager.save(saveObjectString, with: key)
    }
    @objc func updatingUI(notification: Notification) {
        //обновление задержек пальцев после чтения с протеза
            initUI()
    }
}

extension Notification.Name {
        static let notificationReseiveBLEDataCalibrationStatus = Notification.Name(rawValue: "notificationReseiveBLEDataCalibrationStatus")
    }
