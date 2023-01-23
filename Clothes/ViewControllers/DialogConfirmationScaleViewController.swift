//
//  DialogConfirmationScaleViewController.swift
//  MotoricaStart
//
//  Created by Motorica LLC on 17.11.2022.
//  Copyright © 2022 Brian Advent. All rights reserved.
//

import UIKit


class DialogConfirmationScaleViewController: UIViewController {
    @IBOutlet weak var backgraudView: UIVisualEffectView!
    @IBOutlet weak var massage: UILabel!
    private var scaleInt: UInt8 = 0x00

    private let sampleGattAttributes = SampleGattAttributes()
    private var savingParametrsMassString:[SaveObjectString]!
    var dataForSensorsViewController = ["":""]


    override func viewDidLoad() {
        super.viewDidLoad()
        backgraudView.layer.cornerRadius = 10;
        backgraudView.layer.masksToBounds = true;
    
        loadDataString()
        initUI()
    }


    @IBAction func cancelAcceptedScaleDialog(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        dataForSensorsViewController["resultDialog"] = String("acceptSelectScaleCancel")
        NotificationCenter.default.post(name: .notificationDataDialogToSensorsView, object: nil, userInfo: self.dataForSensorsViewController)
    }
    @IBAction func acceptAcceptedScaleDialog(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        dataForSensorsViewController["resultDialog"] = String("acceptSelectScaleAccept")
        NotificationCenter.default.post(name: .notificationDataDialogToSensorsView, object: nil, userInfo: self.dataForSensorsViewController)
    }
    
    private func initUI() {
        for item in savingParametrsMassString
        {
            if (item.key == sampleGattAttributes.SCALE) {
                switch Int(item.value) {
                case 0:
                    massage.text = "The size of yuor prosthesis \"S\"?"
                case 1:
                    massage.text = "The size of yuor prosthesis \"M\"?"
                case 2:
                    massage.text = "The size of yuor prosthesis \"L\"?"
                case 3:
                    massage.text = "The size of yuor prosthesis \"XL\"?"
                default:
                    massage.text = "The size of yuor prosthesis \"S\"?"
                }
            }
        }
    }
    
    
    // MARK: - работа с памятью
    private func loadDataString() {
        savingParametrsMassString = [SaveObjectString]()
        savingParametrsMassString = DataManager.loadAll(SaveObjectString.self)
        for item in savingParametrsMassString {
            print("load   key: \(item.key) value: \(item.value)")
        }
    }
}
