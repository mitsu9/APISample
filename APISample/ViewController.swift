//
//  ViewController.swift
//  APISample
//
//  Created by rayc5 on 2015/06/02.
//  Copyright (c) 2015年 rayc5. All rights reserved.
//

import UIKit

class ViewController: UIViewController, WunderlistAuthDelegate {
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if Wunderlist.sharedInstance.isLogin {
            getList()
        } else {
            // authorize Wunderlist
            if let vc = Wunderlist.sharedInstance.getAuthController(self) {
                self.presentViewController(vc, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: WunderlistAuthDelegate
    
    func didAuthrization(success: Bool) {
        if success {
            getList()
        }
    }
    
    // MARK: sample to get lists/tasks
    
    private var lists: [NSDictionary] = []
    private var tasks: [NSDictionary] = []
    
    func getList() {
        Wunderlist.sharedInstance.get(.List) {
            if let array = $0 {
                for listObj in array {
                    let list = listObj as! NSDictionary
                    let id = list["id"] as! NSNumber
                    let title = list["title"] as! String
                    println("list: id=\(id), title=\(title)")
                    self.getTasks(id.stringValue)
                    self.lists.append(list)
                }
            }
        }
    }
    
    func getTasks(listID: String) {
        Wunderlist.sharedInstance.get(.Task, parameters: ["list_id":listID]) {
            if let array = $0 {
                for taskObj in array {
                    let task = taskObj as! NSDictionary
                    let id = task["id"] as! NSNumber
                    let title = task["title"] as! String
                    let completed = task["completed"] as! NSNumber
                    let due = task["due_date"] as? String
                    println("    task: id=\(id), title=\(title), due=\(due), completed=\(completed.boolValue)")
                    self.tasks.append(task)
                }
            }
        }
    }

}

