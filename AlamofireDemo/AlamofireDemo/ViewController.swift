//
//  ViewController.swift
//  AlamofireDemo
//
//  Created by Mr.LuDashi on 16/5/16.
//  Copyright © 2016年 ZeluLi. All rights reserved.
//

import UIKit

let kFileTempData = "FileTempData"

class ViewController: UIViewController, NSURLSessionDownloadDelegate{
    @IBOutlet var logTextView: UITextView!
    
    @IBOutlet var uploadImageView: UIImageView!
    
    @IBOutlet var downloadImageView: UIImageView!
    
    @IBOutlet var downloadProgressView: UIProgressView!
    
    var downloadTask: NSURLSessionDownloadTask? = nil
    var downloadSession: NSURLSession? = nil
    var downloadData: NSData? = nil
    


    override func viewDidLoad() {
        super.viewDidLoad()
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.downloadSession = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        self.downloadData = NSUserDefaults.standardUserDefaults().objectForKey(kFileTempData) as? NSData
    }
    
    
    
    
    
    /**
     通过NSURLSessionDataTask进行get请求
     
     - parameter sender:
     */
    @IBAction func tapSessionGetButton(sender: AnyObject) {
        
        let parameters = ["userId": "1"]
        showLog("正在GET请求数据")
        sessionDataTaskRequest("GET", parameters: parameters)
    }
    
    
    
    /**
     通过NSURLSessionDataTask进行Post请求
     
     - parameter sender:
     */
    @IBAction func tapSessionPostButton(sender: AnyObject) {
        showLog("正在POST请求数据")
        let parameters = ["userId": "1"]
        
        sessionDataTaskRequest("POST", parameters: parameters)
    }
    
    /**
     NSURLSessionDataTask
     
     - parameter method:     NSURLSessionDataTask
     - parameter parameters: 字典形式的参数
     */
    
    func sessionDataTaskRequest(method: String, parameters:[String:AnyObject]){
        
        var hostString = "http://jsonplaceholder.typicode.com/posts"
        
        let escapeQueryString = query(parameters)
        /**
         *  Get方式就将参数拼接到url上
         */
        if method == "GET" {
            hostString += "?" + escapeQueryString
        }
        
        let url: NSURL = NSURL.init(string: hostString)!
        let request: NSMutableURLRequest = NSMutableURLRequest.init(URL: url)
        request.HTTPMethod = method
        
        /**
         *  POST方法就将参数放到HTTPBody中
         */
        if method == "POST" {
            request.HTTPBody = escapeQueryString.dataUsingEncoding(NSUTF8StringEncoding)
        }
        
        
        let session: NSURLSession = NSURLSession.sharedSession()
        
        let sessionTask: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
            if error != nil {
                self.showLog(error!)
                return
            }
            if data != nil {
                let json = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                self.showLog(json!)
            }
        });
        
        sessionTask.resume()
    }
    
    
    
    
    /**
     测试URL编码
     
     - parameter sender: 
     */
    @IBAction func tapURLEncodeButton(sender: AnyObject) {
        let parameters = ["post": "value01",
                          "arr": ["元素1", "元素2"],
                          "dic":["key1":"value1", "key2":"value2"]]
        showLog(query(parameters))
    }
    
    
    // - MARK - Alamofire中的三个方法该方法将字典转换成json串
    func query(parameters: [String: AnyObject]) -> String {
        
        var components: [(String, String)] = []     //存有元组的数组，元组由ULR中的(key, value)组成
        
        //遍历参数字典
        for key in parameters.keys.sort(<) {
            let value = parameters[key]!
            components += queryComponents(key, value)
        }
        
        return (components.map { "\($0)=\($1)" } as [String]).joinWithSeparator("&")
    }
    
    
    func queryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
        var components: [(String, String)] = []
        
        
        if let dictionary = value as? [String: AnyObject] {         //value为字典的情况, 递归调用
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        } else if let array = value as? [AnyObject] {               //value为数组的情况, 递归调用
            for value in array {
                components += queryComponents("\(key)[]", value)
            }
        } else {
            components.append((escape(key), escape("\(value)")))    //vlalue为字符串的情况，进行转义，上面两种情况最终会递归到此情况而结束
        }
        
        return components
    }
    
    /**
     
     - parameter string: 要转义的字符串
     
     - returns: 转义后的字符串
     */
    func escape(string: String) -> String {
        /*
         :用于分隔协议和主机，/用于分隔主机和路径，?用于分隔路径和查询参数, #用于分隔查询与碎片
         */
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        
        //组件中的分隔符：如=用于表示查询参数中的键值对，&符号用于分隔查询多个键值对
        let subDelimitersToEncode = "!$&'()*+,;="
        
        let allowedCharacterSet = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        allowedCharacterSet.removeCharactersInString(generalDelimitersToEncode + subDelimitersToEncode)
        
        
        var escaped = ""
        
        //==========================================================================================================
        //
        //  Batching is required for escaping due to an internal bug in iOS 8.1 and 8.2. Encoding more than a few
        //  hundred Chinese characters causes various malloc error crashes. To avoid this issue until iOS 8 is no
        //  longer supported, batching MUST be used for encoding. This introduces roughly a 20% overhead. For more
        //  info, please refer to:
        //
        //      - https://github.com/Alamofire/Alamofire/issues/206
        //
        //==========================================================================================================
        
        if #available(iOS 8.3, OSX 10.10, *) {
            escaped = string.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? string
        } else {
            let batchSize = 50      //一次转义的字符数
            var index = string.startIndex
            
            while index != string.endIndex {
                let startIndex = index
                let endIndex = index.advancedBy(batchSize, limit: string.endIndex)
                let range = startIndex..<endIndex
                
                let substring = string.substringWithRange(range)
                
                escaped += substring.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? substring
                
                index = endIndex
            }
        }
        
        return escaped
    }
    

    
    
    
    
    
    
    
    
    
    
    
   
    
    
    
    
    
    /**
     通过NSURLSessionUploadTask进行数据上传
     
     - parameter sender:
     */
    @IBAction func tapSessionUploadFileButton(sender: AnyObject) {
        
        //从网络获取图片
        let fileUrl = NSURL.init(string: "http://img.taopic.com/uploads/allimg/140326/235113-1403260I33562.jpg")
        var fileData: NSData? = nil
        
        let dispatchGroup = dispatch_group_create()
        dispatch_group_async(dispatchGroup, dispatch_get_global_queue(0, 0)) {
            fileData = NSData.init(contentsOfURL: fileUrl!)
        }
    
        dispatch_group_notify(dispatchGroup, dispatch_get_global_queue(0, 0)) {
            //更新主线程
            dispatch_async(dispatch_get_main_queue(), {
                self.uploadImageView.image = UIImage.init(data: fileData!)
            })
            
            //将fileData上传到服务器
            self.uploadTask(fileData!)
        }
    }
    
    /**
     上传图片到服务器，NSURLSessionUploadTask的使用
     
     - parameter parameters: 上传到服务器的二进制文件
     */
    func uploadTask(parameters:NSData) {
        let uploadUrlString = "http://127.0.0.1/upload.php"
        let url: NSURL = NSURL.init(string: uploadUrlString)!
        
        let request = NSMutableURLRequest.init(URL: url)
        request.HTTPMethod = "POST"
        
        let session: NSURLSession = NSURLSession.sharedSession()
        let uploadTask: NSURLSessionUploadTask = session.uploadTaskWithRequest(request, fromData: parameters) {
            (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            if error != nil{
                self.showLog((error?.code)!)
                self.showLog((error?.description)!)
            }else{
                self.showLog("上传成功")
            }
        }
        //使用resume方法启动任务
        uploadTask.resume()
    }

    
    
    
    
    
    
    
    
    
    /**
     图片开始的下载
     
     - parameter sender:
     */
    
    @IBAction func tapDownloadTaskButton(sender: AnyObject) {
        //从网络下载图片
        let fileUrl: NSURL? = NSURL(string: "http://img3.91.com/uploads/allimg/140108/32-14010QK546.jpg")
        let request: NSURLRequest = NSURLRequest(URL: fileUrl!)

        
        if (self.downloadData != nil) {
            self.downloadTask = self.downloadSession?.downloadTaskWithResumeData(self.downloadData!)
        }else{
             self.downloadTask = self.downloadSession?.downloadTaskWithRequest(request)
        }
        
        // 开始任务
        downloadTask?.resume()
    }
    
    
    /**
     暂停下载
     
     - parameter sender:
     */
    @IBAction func tapPauseButton(sender: AnyObject) {
        downloadTask?.cancelByProducingResumeData({ (data) in
            if data != nil {
                NSUserDefaults.standardUserDefaults().setObject(data, forKey: kFileTempData)
                self.downloadData = data
                self.showLog((data?.length)!)
            }
        })
    }
    

    // MARK --NSURLSessionDownloadDelegate
    /**
     下载完成后执行的代理
     
     - parameter session:      session对象
     - parameter downloadTask: downloadTask对象
     - parameter location:     本地URL
     */
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey(kFileTempData)
        self.downloadData = nil
        
        showLog("下载的临时文件路径:\(location)")                //输出下载文件临时目录
       
        guard let tempFilePath: String = location.path else {
            return
        }
       
        //创建文件存储路径
        let newFileName = String(UInt(NSDate().timeIntervalSince1970))
        let newFilePath: String = NSHomeDirectory() + "/Documents/\(newFileName).png"
        
        //创建文件管理器
        let fileManager:NSFileManager = NSFileManager.defaultManager()
        
        try! fileManager.moveItemAtPath(tempFilePath, toPath: newFilePath)
        showLog("将临时文件进行存储，路径为:\(newFilePath)")
        
        //将下载后的图片进行显示
        let imageData = NSData(contentsOfFile: newFilePath)
        dispatch_async(dispatch_get_main_queue()) { 
            self.downloadImageView.image = UIImage.init(data: imageData!)
        }
    }
    
    /**
     实时监听下载任务回调
     
     - parameter session:                   session对象
     - parameter downloadTask:              下载任务
     - parameter bytesWritten:              本次接收
     - parameter totalBytesWritten:         总共接收
     - parameter totalBytesExpectedToWrite: 总量
     */
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        showLog("\n本次接收：\(bytesWritten)")
        showLog("已下载：\(totalBytesWritten)")
        showLog("文件总量：\(totalBytesExpectedToWrite)")
        
        //获取进度
        let written:Float = (Float)(totalBytesWritten)
        let total:Float = (Float)(totalBytesExpectedToWrite)
        dispatch_async(dispatch_get_main_queue()) { 
            self.downloadProgressView.progress = written/total
        }
        
    }
    
    /**
     下载偏移，主要用于暂停续传
     
     - parameter session:
     - parameter downloadTask:
     - parameter fileOffset:
     - parameter expectedTotalBytes:
     */
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {

    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    /**
     缓存策略：
        UseProtocolCachePolicy -- 缓存存在就读缓存，若不存在就请求服务器
        ReloadIgnoringLocalCacheData -- 忽略缓存，直接请求服务器数据
        ReturnCacheDataElseLoad -- 本地如有缓存就使用，忽略其有效性，无则请求服务器
        ReturnCacheDataDontLoad -- 直接加载本地缓存，没有也不请求网络
        ReloadIgnoringLocalAndRemoteCacheData -- 未实现
        ReloadRevalidatingCacheData -- 未实现
     
     - parameter sender:
     */
    
    
     //1.使用NSMutableURLRequest指定缓存策略
    @IBAction func tapRequestCacheButton(sender: AnyObject) {
        let fileUrl: NSURL? = NSURL(string: "http://www.baidu.com")
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: fileUrl!)
        
        request.cachePolicy = .ReturnCacheDataElseLoad
        let session: NSURLSession = NSURLSession.sharedSession()
        
        let dataTask: NSURLSessionDataTask = session.dataTaskWithRequest(request) { (data, response, error) in
            if data != nil {
                self.showLog(String.init(data: data!, encoding: NSUTF8StringEncoding)!)
            }
        }
        dataTask.resume()
    }
    
    
    //2.使用NSURLSessionConfiguration指定缓存策略
    @IBAction func tapConfigurationCacheButton(sender: AnyObject) {
        let fileUrl: NSURL? = NSURL(string: "http://www.baidu.com")
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: fileUrl!)
        
        let sessionConfig: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.requestCachePolicy = .ReturnCacheDataElseLoad
        let session: NSURLSession = NSURLSession(configuration: sessionConfig)

        
        let dataTask: NSURLSessionDataTask = session.dataTaskWithRequest(request) { (data, response, error) in
            if data != nil {
                self.showLog(String.init(data: data!, encoding: NSUTF8StringEncoding)!)
            }
        }
        dataTask.resume()

    }

    //3.使用URLCache + request进行缓存
    @IBAction func tapRequestURLCacheButton(sender: AnyObject) {
        let fileUrl: NSURL? = NSURL(string: "http://www.baidu.com")
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: fileUrl!)
        
        
        let memoryCapacity = 4 * 1024 * 1024    //内存容量
        let diskCapacity = 10 * 1024 * 1024     //磁盘容量
        let cacheFilePath: String = "MyCache/"   //缓存路径
        
        let urlCache: NSURLCache = NSURLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: cacheFilePath)
        NSURLCache.setSharedURLCache(urlCache)
        request.cachePolicy = .ReturnCacheDataElseLoad
        let session: NSURLSession = NSURLSession.sharedSession()
        

        let dataTask: NSURLSessionDataTask = session.dataTaskWithRequest(request) { (data, response, error) in
            if data != nil {
                self.showLog(String.init(data: data!, encoding: NSUTF8StringEncoding)!)
            }
        }
        dataTask.resume()

    }
    
    //4.使用URLCache + NSURLSessionConfiguration进行缓存
    @IBAction func tapConfigNSURLCacheButton(sender: AnyObject) {
        let fileUrl: NSURL? = NSURL(string: "http://www.baidu.com")
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: fileUrl!)
        
        let memoryCapacity = 4 * 1024 * 1024    //内存容量
        let diskCapacity = 10 * 1024 * 1024     //磁盘容量
        let cacheFilePath: String = "MyCache/"   //缓存路径

        let urlCache: NSURLCache = NSURLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: cacheFilePath)
        
        let sessionConfig: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.requestCachePolicy = .ReturnCacheDataElseLoad
        sessionConfig.URLCache = urlCache
        
        let session: NSURLSession = NSURLSession(configuration: sessionConfig)
        
        
        let dataTask: NSURLSessionDataTask = session.dataTaskWithRequest(request) { (data, response, error) in
            if data != nil {
                self.showLog(String.init(data: data!, encoding: NSUTF8StringEncoding)!)
            }
        }
        
        dataTask.resume()
    }
    
    
    
    @IBAction func tapClearLogButton(sender: AnyObject) {
        self.logTextView.text = ""
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
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

