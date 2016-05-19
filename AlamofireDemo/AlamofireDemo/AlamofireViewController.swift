//
//  AlamofireViewController.swift
//  AlamofireDemo
//
//  Created by Mr.LuDashi on 16/5/19.
//  Copyright © 2016年 ZeluLi. All rights reserved.
//

import UIKit

import Alamofire

//网络测试地址http://jsonplaceholder.typicode.com/


class AlamofireViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Alamofire"

        // Do any additional setup after loading the view.
    }
    
    
    /**
     使用Alamofire进行GET请求
     */

    @IBAction func tapGetButton(sender: AnyObject) {
        let hostString = "http://jsonplaceholder.typicode.com/posts"
        let parameters = ["userId": "1"]
        
        Alamofire.request(.GET, hostString, parameters: parameters)
            .responseJSON { (response) in
                if let json = response.result.value {
                    print("GET字典:\(json)")
                }
        }

    }
    
    /**
     使用Alamofire进行post请求
     
     - parameter sender:
     */
    @IBAction func tapPostButton(sender: AnyObject) {
        let hostString = "http://jsonplaceholder.typicode.com/posts"
        let parameters = ["userId": "1"]
        Alamofire.request(.POST, hostString, parameters: parameters)
            .responseJSON { (response) in
                if let json = response.result.value {
                    print("POST字典:\(json)")
                }
        }
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
