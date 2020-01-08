//
//  ViewController.swift
//  felica-reader
//
//  Created by treastrain on 2019/06/06.
//  Copyright © 2019 treastrain / Tanaka Ryoga. All rights reserved.
//

import UIKit
import CoreNFC

class SettingViewController: UIViewController, NFCTagReaderSessionDelegate {

    var session: NFCTagReaderSession?
    
    @IBOutlet var ICNumber: UILabel!
    @IBOutlet var nameTextField: UITextField!
    
    var userDefaults = UserDefaults.standard
    var userArray:[[String]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if userDefaults.array(forKey: "userArray") != nil{
            userArray = userDefaults.array(forKey: "userArray") as! [[String]]
        }
    }
    
    @IBAction func beginScanning(_ sender: UIButton) {
        guard NFCTagReaderSession.readingAvailable else {
            let alertController = UIAlertController(
                title: "Scanning Not Supported",
                message: "This device doesn't support tag scanning.",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        self.session = NFCTagReaderSession(pollingOption: .iso18092, delegate: self)
        self.session?.alertMessage = "Hold your iPhone near the item to learn more about it."
        self.session?.begin()
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("tagReaderSessionDidBecomeActive(_:)")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError {
            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                let alertController = UIAlertController(
                    title: "Session Invalidated",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        
        self.session = nil
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        print("tagReaderSession(_:didDetect:)")
        
        if tags.count > 1 {
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "More than 1 tag is detected, please remove all tags and try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
        
        let tag = tags.first!
        
        session.connect(to: tag) { (error) in
            if nil != error {
                session.invalidate(errorMessage: "Connection error. Please try again.")
                return
            }
            
            guard case .feliCa(let feliCaTag) = tag else {
                let retryInterval = DispatchTimeInterval.milliseconds(500)
                session.alertMessage = "A tag that is not FeliCa is detected, please try again with tag FeliCa."
                DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                    session.restartPolling()
                })
                return
            }
            
            print(feliCaTag)
            
            let idm = feliCaTag.currentIDm.map { String(format: "%.2hhx", $0) }.joined()
            let systemCode = feliCaTag.currentSystemCode.map { String(format: "%.2hhx", $0) }.joined()
            
            print("IDm: \(idm)")
            print("System Code: \(systemCode)")
            DispatchQueue.main.async {
                self.ICNumber.text = String(idm)
            }
            session.alertMessage = "成功"
            session.invalidate()
        }
    }

    @IBAction func setName(){
        var Array : [String] = ["",""]
        Array[0] = ICNumber.text!
        Array[1] = nameTextField.text!
        userArray += [Array]
        print(userArray)
        userDefaults.set(userArray, forKey: "userArray")
        self.dismiss(animated: true, completion: nil)
    }

}

