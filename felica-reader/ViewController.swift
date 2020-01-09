//
//  ViewController.swift
//  felica-reader
//
//  Created by treastrain on 2019/06/06.
//  Copyright © 2019 treastrain / Tanaka Ryoga. All rights reserved.
//

import UIKit
import CoreNFC

extension DateFormatter {
    // テンプレートの定義(例)
    enum Template: String {
        case date = "yMd"     // 2017/1/1
        case time = "Hms"     // 12:39:22
        case full = "yMdkHms" // 2017/1/1 12:39:22
        case onlyHour = "k"   // 17時
        case era = "GG"       // "西暦" (default) or "平成" (本体設定で和暦を指定している場合)
        case weekDay = "EEEE" // 日曜日
    }

    func setTemplate(_ template: Template) {
        // optionsは拡張用の引数だが使用されていないため常に0
        dateFormat = DateFormatter.dateFormat(fromTemplate: template.rawValue, options: 0, locale: .current)
    }
}

class ViewController: UIViewController, NFCTagReaderSessionDelegate {

    var session: NFCTagReaderSession?
    
    var userDefaults = UserDefaults.standard
    var userArray:[[String]] = []
    var logArray:[[String]] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        update()
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

            let f = DateFormatter()
            f.setTemplate(.full)
            let now = Date()
            if let user = self.userArray.filter({ $0[0] == idm }).first{
//            if self.userArray[0][0] == idm{
                if self.userArray[0][2] == "2"{//退出
                    session.alertMessage = "さようなら！ \(user[1])\n退室時間：\(f.string(from: now))"
                    var Array : [String] = ["","",""]
                    Array[0] = self.userArray[0][1] //名前
                    Array[1] = f.string(from: now) //時間
                    Array[2] = "退室"
                    self.logArray += [Array]
                    print(self.logArray)
                    self.userDefaults.set(self.logArray, forKey: "logArray")
                    self.userArray[0][2] = "1"
                    self.userDefaults.set(self.userArray, forKey: "userArray")
                }else{//入室
                    session.alertMessage = "こんにちは！ \(user[1])\n入室時間：\(f.string(from: now))"
                    var Array : [String] = ["","",""]
                    Array[0] = self.userArray[0][1] //名前
                    Array[1] = f.string(from: now) //時間
                    Array[2] = "入室"
                    self.logArray += [Array]
                    print(self.logArray)
                    self.userDefaults.set(self.logArray, forKey: "logArray")
                    self.userArray[0][2] = "2"
                    self.userDefaults.set(self.userArray, forKey: "userArray")
                }
            } else {
                session.alertMessage = "はじめまして\nユーザー登録をしてください"
            }

//            session.alertMessage = "Read success!\nIDm: \(idm)\nSystem Code: \(systemCode)"
            session.invalidate()
        }
    }
    
    func update(){
        if userDefaults.array(forKey: "userArray") != nil{
            userArray = userDefaults.array(forKey: "userArray") as! [[String]]
        }
        if userDefaults.array(forKey: "logArray") != nil{
            logArray = userDefaults.array(forKey: "logArray") as! [[String]]
        }
    }
}

