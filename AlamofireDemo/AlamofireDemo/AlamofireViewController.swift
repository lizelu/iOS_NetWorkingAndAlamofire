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

public enum MethodTest: String {
    case OPTIONS, GET, HEAD, POST, PUT, PATCH, DELETE, TRACE, CONNECT
}

class AlamofireViewController: UIViewController {
    @IBOutlet var logTextView: UITextView!
    @IBOutlet var progressView: UIProgressView!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Alamofire"
        
        
        print(MethodTest.POST.rawValue)
        
        
        //获取Manager的单例对象，并输出对象地址
        print(unsafeAddressOf(Alamofire.Manager.sharedInstance))
        print(unsafeAddressOf(Alamofire.Manager.sharedInstance))
        print(unsafeAddressOf(Alamofire.Manager.sharedInstance))
        
        
        print(publicKeysInBundle())
    }
    
    func publicKeysInBundle(bundle: NSBundle = NSBundle.mainBundle()) -> [SecKey] {
        var publicKeys: [SecKey] = []
        
        for certificate in certificatesInBundle(bundle) {
            if let publicKey = publicKeyForCertificate(certificate) {
                publicKeys.append(publicKey)
            }
        }
        
        return publicKeys
    }

    
    
    func certificatesInBundle(bundle: NSBundle = NSBundle.mainBundle()) -> [SecCertificate] {
        var certificates: [SecCertificate] = []
        
        let paths = Set([".cer", ".CER", ".crt", ".CRT", ".der", ".DER"].map { fileExtension in
            bundle.pathsForResourcesOfType(fileExtension, inDirectory: nil)
            }.flatten())
        
        for path in paths {
            if let
                certificateData = NSData(contentsOfFile: path),
                certificate = SecCertificateCreateWithData(nil, certificateData)
            {
                certificates.append(certificate)
            }
        }
        
        return certificates
    }
    
    
    func publicKeyForCertificate(certificate: SecCertificate) -> SecKey? {
        var publicKey: SecKey?
        
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        let trustCreationStatus = SecTrustCreateWithCertificates(certificate, policy, &trust)
        
        if let trust = trust where trustCreationStatus == errSecSuccess {
            publicKey = SecTrustCopyPublicKey(trust)
        }
        
        return publicKey
    }



    
    /**
     使用Alamofire进行GET请求
     */

    @IBAction func tapGetButton(sender: AnyObject) {
        
        showLog("正在使用Alamofire进行GET请求")
        
        //let hostString = "http://www.baidu.com"
        let hostString = "https://httpbin.org/get"
        let parameters = ["userId": "1"]
        
        Alamofire.request(.GET, hostString, parameters: parameters)
            .progress({ (current, total, exp) in
                print(current)
            })
            .responseJSON { (response) in
            
                debugPrint(response)
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
    
    /**
     使用PUT请求
     
     - parameter sender:
     */
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
    
    
    /**
     Patch请求
     
     - parameter sender:
     */
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
    
    /**
     URL编码
     
     - parameter sender:
     */
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
    
    
    /**
     上传图片
     
     - parameter sender:
     */
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
    

    
    /**
     下载数据
     
     - parameter sender:
     */
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
            }
            
            .progress { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
                
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
    
    
    /**
     使用Manager进行请求
     
     - parameter sender: <#sender description#>
     */
    @IBAction func tapManagerButton(sender: AnyObject) {
        
        showLog("正在使用Manager进行post请求")
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let manager = Alamofire.Manager(configuration: configuration)
        
        let hostString = "https://httpbin.org/post"
        let parameters = ["post": "value01",
                          "arr": ["元素1", "元素2"],
                          "dic":["key1":"value1", "key2":"value2"]]
        
        
        manager.request(.POST, hostString, parameters: parameters, encoding: .URL, headers: [:])
        
        manager.request(.POST, hostString, parameters: parameters)
            .responseJSON { (response) in
                if let json = response.result.value {
                    self.showLog("post字典:\(json)")
                }
        }
    }
    
    
    let manager = NetworkReachabilityManager(host: "www.apple.com")
    @IBAction func tapReachabilityButton(sender: AnyObject) {
        manager?.listener = { status in
            print("网络状态: \(status)")
            switch status {
            case .NotReachable:
                print("网络不可达")
            case .Unknown:
                print("未知状态")
            case .Reachable(let connectType):
                switch connectType {
                case .EthernetOrWiFi:
                    print("Wifi网络")
                case .WWAN:
                    print("蜂窝数据")
                }
            }
        }
        manager?.startListening()
    }
    
    
    
    /**
     输出日志
     
     - parameter info: 日志内容
     */
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
