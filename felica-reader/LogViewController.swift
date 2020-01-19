//
//  LogViewController.swift
//  felica-reader
//
//  Created by JotaroSugiyama on 2020/01/09.
//  Copyright © 2020 treastrain / Tanaka Ryoga. All rights reserved.
//

import UIKit

class LogViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var userDefaults = UserDefaults.standard
    var logArray:[[String]] = []
    var logString = "logData"
    
    @IBOutlet var buttonA : UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if userDefaults.array(forKey: "logArray") != nil{
            logArray = userDefaults.array(forKey: "logArray") as! [[String]]
        }
        buttonA.setTitle("...", for: .normal)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得する
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        // セルに表示する値を設定する
        cell.textLabel!.text = String(logArray[indexPath.row][0] + "," + logArray[indexPath.row][1] + "," + logArray[indexPath.row][2])
        return cell
    }
    
    @IBAction func backButton(){
        let parentVC = presentingViewController as! ViewController
        parentVC.update()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func button(){
        let alert: UIAlertController = UIAlertController(title: "", message: "ログをどうしますか？", preferredStyle:  UIAlertController.Style.actionSheet)
        let defaultAction: UIAlertAction = UIAlertAction(title: "ログを全て削除", style: UIAlertAction.Style.destructive, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            self.clearButton()
        })
        
        let defaultAction2: UIAlertAction = UIAlertAction(title: "CSV書き出し(UTF8)", style: UIAlertAction.Style.default, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            self.shareButton()
        })
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
        })
        
        alert.addAction(defaultAction)
        alert.addAction(defaultAction2)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }
    
    func clearButton(){
        let alert: UIAlertController = UIAlertController(title: "", message: "ログは全て削除されます。この操作は取り消せません。", preferredStyle:  UIAlertController.Style.actionSheet)
        let defaultAction: UIAlertAction = UIAlertAction(title: "ログを全て削除", style: UIAlertAction.Style.destructive, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            self.clear()
        })
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
        })
        
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)

        present(alert, animated: true, completion: nil)
    }
    
    func clear(){
        logArray = []
        userDefaults.set(self.logArray, forKey: "logArray")
        let parentVC = presentingViewController as! ViewController
        parentVC.update()
        self.dismiss(animated: true, completion: nil)
    }
    
    func shareButton(){
        createFile(fileName: logString, fileArrData: logArray)
        
        let filePath = NSHomeDirectory() + "/Documents/" + logString + ".csv"
        let shareFile = NSURL(fileURLWithPath: filePath)
        
        let activityItems = [shareFile]
        
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        self.present(activityVC, animated: true, completion: nil)
    }
    
    func createFile(fileName : String, fileArrData : [[String]]){
        let filePath = NSHomeDirectory() + "/Documents/" + fileName + ".csv"
        print(filePath)
        var fileStrData:String = ""
        
        //StringのCSV用データを準備
        for singleArray in fileArrData{
            for singleString in singleArray{
                fileStrData += "\"" + singleString + "\""
                if singleString != singleArray[singleArray.count-1]{
                    fileStrData += ","
                }
            }
            fileStrData += "\n"
        }
        print(fileStrData)
        
        do{
            try fileStrData.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
            print("Success to Wite the File")
        }catch let error as NSError{
            print("Failure to Write File\n\(error)")
        }
    }
}
