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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if userDefaults.array(forKey: "logArray") != nil{
            logArray = userDefaults.array(forKey: "logArray") as! [[String]]
        }
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
    
    @IBAction func clearButton(){
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

}
