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

class SettingViewController: UIViewController, NFCTagReaderSessionDelegate, UITableViewDelegate, UITableViewDataSource {

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
            
            print("IDm: \(idm)")
            print("System Code: \(systemCode)")
            DispatchQueue.main.async {
                self.ICNumber.text = String(idm)
            }
            session.alertMessage = "成功"
            session.invalidate()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userArray.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool{
        return true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得する
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        // セルに表示する値を設定する
        cell.textLabel!.text = String(userArray[indexPath.row][0] + "," + userArray[indexPath.row][1])
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            userArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
            userDefaults.set(userArray, forKey: "userArray")
        }
    }
    
    @IBAction func backButton(){
        let parentVC = presentingViewController as! ViewController
        parentVC.update()
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func setName(){
        if ICNumber.text! != "" && nameTextField.text! != ""{
            if let userIndex = self.userArray.firstIndex(where: { $0[0] == ICNumber.text! }){
                AudioServicesPlaySystemSound(1102)
                let alert: UIAlertController = UIAlertController(title: "エラー", message: "このICカードは既に登録されています。", preferredStyle:  UIAlertController.Style.alert)
                let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
                    // ボタンが押された時の処理を書く（クロージャ実装）
                    (action: UIAlertAction!) -> Void in
                })
                alert.addAction(defaultAction)
                present(alert, animated: true, completion: nil)
                print("もう設定してあるやん")
            } else {
                AudioServicesPlaySystemSound(1520)
                var Array : [String] = ["","",""]
                Array[0] = ICNumber.text!
                Array[1] = nameTextField.text!
                Array[2] = "1"  //1は外出中・2は出席中
                userArray += [Array]
                print(userArray)
                print("記入完了")
                userDefaults.set(userArray, forKey: "userArray")
                let parentVC = presentingViewController as! ViewController
                parentVC.update()
                self.dismiss(animated: true, completion: nil)
            }
        }else{
            AudioServicesPlaySystemSound(1102)
            let alert: UIAlertController = UIAlertController(title: "エラー", message: "必要事項を全て入力してください。", preferredStyle:  UIAlertController.Style.alert)
            let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
                // ボタンが押された時の処理を書く（クロージャ実装）
                (action: UIAlertAction!) -> Void in
            })
            alert.addAction(defaultAction)
            present(alert, animated: true, completion: nil)
            print("ダメじゃん")
        }
    }
}
