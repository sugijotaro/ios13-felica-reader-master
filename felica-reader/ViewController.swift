//
//  ViewController.swift
//  felica-reader
//
//  Created by treastrain on 2019/06/06.
//  Copyright © 2019 treastrain / Tanaka Ryoga. All rights reserved.
//

import UIKit
import CoreNFC
import AudioToolbox
import StoreKit

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
    
    @IBOutlet var dateLabel :UILabel!
    @IBOutlet var timeLabel :UILabel!
    
    var timer = Timer()
    
    var count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: UIFont.Weight.bold)
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: UIFont.Weight.bold)
        
        update()
        nowTime()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
            self.nowTime()
        })
    }
    
    @IBAction func beginScanning(_ sender: UIButton) {
        AudioServicesPlaySystemSound(1520)
        guard NFCTagReaderSession.readingAvailable else {
            let alertController = UIAlertController(
                title: "スキャンはサポートされていません",
                message: "このデバイスはICカードのスキャンをサポートしていません。",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }

        self.session = NFCTagReaderSession(pollingOption: .iso18092, delegate: self)
        self.session?.alertMessage = "ICカードをiPhoneの上部の背面にかざしてください。"
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
                    title: "セッションが無効化されました",
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
            session.alertMessage = "複数のICカードが検出されました。ICカードを一つにした上、もう一度やり直してください。"
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }

        let tag = tags.first!

        session.connect(to: tag) { (error) in
            if nil != error {
                session.invalidate(errorMessage: "接続エラーです。再度読み取り位置をご確認の上、もう一度やり直してください。")
                return
            }

            guard case .feliCa(let feliCaTag) = tag else {
                let retryInterval = DispatchTimeInterval.milliseconds(500)
                session.alertMessage = "FeliCaではないタグが検出されました。FeliCaで再試行してください。"
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
            if let userIndex = self.userArray.firstIndex(where: { $0[0] == idm }){    //idmとユーザーを照合
                if self.userArray[userIndex][2] == "1"{
                    session.alertMessage = "こんにちは！ \(self.userArray[userIndex][1])\n入室時間：\(f.string(from: now))"
                    var Array : [String] = ["","",""]
                    Array[0] = self.userArray[userIndex][1] //名前
                    Array[1] = f.string(from: now) //時間
                    Array[2] = "入室"
                    self.logArray += [Array]
                    print(self.logArray)
                    self.userDefaults.set(self.logArray, forKey: "logArray")
                    self.userArray[userIndex][2] = "2"
                    print(self.userArray)
                    self.userDefaults.set(self.userArray, forKey: "userArray")
                    print("入室完了")
                }else if self.userArray[userIndex][2] == "2"{       //退室
                    session.alertMessage = "さようなら！ \(self.userArray[userIndex][1])\n退室時間：\(f.string(from: now))"
                    var Array : [String] = ["","",""]
                    Array[0] = self.userArray[userIndex][1] //名前
                    Array[1] = f.string(from: now) //時間
                    Array[2] = "退室"
                    self.logArray += [Array]
                    print(self.logArray)
                    self.userDefaults.set(self.logArray, forKey: "logArray")
                    self.userArray[userIndex][2] = "1"
                    print(self.userArray)
                    self.userDefaults.set(self.userArray, forKey: "userArray")
                    print("退室完了")
                }
            } else {
                session.alertMessage = "はじめまして\nユーザー登録をしてください"
            }

            if self.userDefaults.integer(forKey: "count") != 0{
                self.count = self.userDefaults.integer(forKey: "count")
            }
            if self.count < 10{
                self.count = self.count + 1
                self.userDefaults.set(self.count, forKey: "count")
            } else {
                SKStoreReviewController.requestReview()
                self.count = 0
                self.userDefaults.set(self.count, forKey: "count")
            }
            print(self.count)
//            session.alertMessage = "Read success!\nIDm: \(idm)\nSystem Code: \(systemCode)"
            session.invalidate()
        }
    }
    
    func nowTime(){
        let d = DateFormatter()
        d.setTemplate(.date)
        
        let t = DateFormatter()
        t.setTemplate(.time)
        
        let now = Date()
        
        dateLabel.text = d.string(from: now)
        timeLabel.text = t.string(from: now)
    }
    
    func update(){
        if userDefaults.array(forKey: "userArray") != nil{
            userArray = userDefaults.array(forKey: "userArray") as! [[String]]
        }
        if userDefaults.array(forKey: "logArray") != nil{
            logArray = userDefaults.array(forKey: "logArray") as! [[String]]
        }
        if userDefaults.integer(forKey: "count") != 0{
            count = userDefaults.integer(forKey: "count")
        }
    }
}
