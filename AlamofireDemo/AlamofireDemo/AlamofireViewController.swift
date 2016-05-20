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
    @IBOutlet var logTextView: UITextView!
    @IBOutlet var progressView: UIProgressView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Alamofire"

        // Do any additional setup after loading the view.
    }
    
    
    /**
     使用Alamofire进行GET请求
     */

    @IBAction func tapGetButton(sender: AnyObject) {
        
        showLog("正在使用Alamofire进行GET请求")
        
        let hostString = "https://httpbin.org/get"
        let parameters = ["userId": "1"]
        
        Alamofire.request(.GET, hostString, parameters: parameters)
            .responseJSON { (response) in
                if let json = response.result.value {
                    self.showLog("GET字典:\(json)")
                }
        }

    }
    
    /**
     使用Alamofire进行post请求
     
     - parameter sender:
     */
    @IBAction func tapPostButton(sender: AnyObject) {
        
        showLog("正在使用Alamofire进行post请求")
        
        let hostString = "https://httpbin.org/post"
        let parameters = ["post": "value01",
                          "arr": ["元素1", "元素2"],
                          "dic":["key1":"value1", "key2":"value2"]]
        
        Alamofire.request(.POST, hostString, parameters: parameters)
            .responseJSON { (response) in
                if let json = response.result.value {
                    self.showLog("POST字典:\(json)")
                }
        }
        
    }
    
    @IBAction func tapPUTButton(sender: AnyObject) {
        showLog("正在使用Alamofire进行put请求")
        
        let hostString = "https://httpbin.org/put"
        let parameters = ["post": "value01",
                          "arr": ["元素1", "元素2"],
                          "dic":["key1":"value1", "key2":"value2"]]
        
        Alamofire.request(.PUT, hostString, parameters: parameters)
            .responseJSON { (response) in
                if let json = response.result.value {
                    self.showLog("PUT字典:\(json)")
                }
        }

    }
    
    @IBAction func tapPatchButton(sender: AnyObject) {
        showLog("正在使用Alamofire进行Patch请求")
        
        let hostString = "https://httpbin.org/patch"
        let parameters = ["post": "value01",
                          "arr": ["元素1", "元素2"],
                          "dic":["key1":"value1", "key2":"value2"]]
        
        Alamofire.request(.PATCH, hostString, parameters: parameters)
            .responseJSON { (response) in
                if let json = response.result.value {
                    self.showLog("PATCH字典:\(json)")
                }
        }

    }
    
    @IBAction func tapParameterEncodingButton(sender: AnyObject) {
        let URL = NSURL(string: "https://httpbin.org/get")!
        var request = NSMutableURLRequest(URL: URL)
        
        
        let parameters = ["post": "value01",
                          "arr": ["元素1", "元素2"],
                          "dic":["key1":"value1", "key2":"value2"]]
        let encoding = Alamofire.ParameterEncoding.URL
        (request, _) = encoding.encode(request, parameters: parameters)
        
        let session = NSURLSession.sharedSession()
        let sessionTask = session.dataTaskWithRequest(request) { (data, response, error) in
            if data != nil {
                let dic = try? NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                self.showLog(dic!)
            }
        }
        sessionTask.resume()
    }
    
    
    @IBAction func tapUploadButton(sender: AnyObject) {
        self.progressView.progress = 0
        showLog("正在上传数据")
        
        //从网络获取图片
        let fileUrl = NSURL.init(string: "http://img.taopic.com/uploads/allimg/140326/235113-1403260I33562.jpg")
        var fileData: NSData? = nil
        
        let dispatchGroup = dispatch_group_create()
        dispatch_group_async(dispatchGroup, dispatch_get_global_queue(0, 0)) {
            fileData = NSData.init(contentsOfURL: fileUrl!)
        }
        
        dispatch_group_notify(dispatchGroup, dispatch_get_global_queue(0, 0)) {
            //将fileData上传到服务器
            self.uploadTask(fileData!)
        }
    }
    
    /**
     上传图片到服务器，Alamofire.upload的使用
     
     - parameter parameters: 上传到服务器的二进制文件
     */
    func uploadTask(parameters:NSData) {
        
        let uploadUrlString = "https://httpbin.org/post"
       // let uploadUrlString = "http://127.0.0.1/upload.php"
    
        Alamofire.upload(.POST, uploadUrlString, data: parameters)
        .progress { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
            
            self.showLog("\n本次上传：\(bytesWritten)B")
            self.showLog("已上传：\(totalBytesWritten)B")
            self.showLog("文件总量：\(totalBytesExpectedToWrite)B")
            
            //获取进度
            let written:Float = (Float)(totalBytesWritten)
            let total:Float = (Float)(totalBytesExpectedToWrite)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.progressView.progress = written/total
            })
        }
    }
    

    
    
    @IBAction func tapDownloadButton(sender: AnyObject) {
        
        self.progressView.progress = 0
        showLog("正在下载数据")
        
        let fileURLSting = "http://img3.91.com/uploads/allimg/140108/32-14010QK546.jpg"
        
        Alamofire.download(.GET, fileURLSting) { temporaryURL, response in
            let fileManager = NSFileManager.defaultManager()
            
            //文件存储路径
            let directoryURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
            
            //下载的文件名
            let pathComponent = response.suggestedFilename
            
            self.showLog(directoryURL.URLByAppendingPathComponent(pathComponent!))
            
            //返回文件的存储路径及名称
            return directoryURL.URLByAppendingPathComponent(pathComponent!)
            }.progress { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
                
                self.showLog("\n本次下载：\(bytesWritten)B")
                self.showLog("已下载：\(totalBytesWritten)B")
                self.showLog("文件总量：\(totalBytesExpectedToWrite)B")
                
                //获取进度
                let written:Float = (Float)(totalBytesWritten)
                let total:Float = (Float)(totalBytesExpectedToWrite)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.progressView.progress = written/total
            })
        }
    }
    
    
    func showLog(info: AnyObject) {
        
        let log = "\(info)"
        print(log)
        
        let logs = self.logTextView.text
        let newlogs = String((logs + "\n"+log)).stringByReplacingOccurrencesOfString("\\n", withString: "\n")
        
        dispatch_async(dispatch_get_main_queue()) {
            self.logTextView.text = newlogs
            
            let length = newlogs.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
            if length > 0 {
                let range: NSRange = NSMakeRange(length-1, 1)
                self.logTextView.scrollRangeToVisible(range)
            }
        }
        
    }


    @IBAction func tapClearLogButton(sender: AnyObject) {
        self.logTextView.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
