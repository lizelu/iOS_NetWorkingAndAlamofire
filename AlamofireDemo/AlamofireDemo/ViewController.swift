//
//  ViewController.swift
//  AlamofireDemo
//
//  Created by Mr.LuDashi on 16/5/16.
//  Copyright © 2016年 ZeluLi. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {
    
    @IBOutlet var uploadImageView: UIImageView!
    var hostString = "http://127.0.0.1/test.php"
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    @IBAction func tapGetButton(sender: AnyObject) {
        requestWithGet()
    }
    
    func requestWithGet() {
        
        let parameters = ["key1": "value1", "key2": "value2", "key3": "value3"]
        
        Alamofire.request(.GET, hostString, parameters: parameters)
        .responseJSON { (response) in
            if let json = response.result.value {
                print("GET字典:\(json)")
            }
        }
    }

    func tapPostButton(sender: AnyObject) {
        let parameters = ["key01": "value01", "key02": "value02", "key03": "value03"]
        Alamofire.request(.POST, hostString, parameters: parameters)
            .responseJSON { (response) in
                if let json = response.result.value {
                    print("POST字典:\(json)")
                }
        }

    }
    
    
    @IBAction func tapSessionGetButton(sender: AnyObject) {
        let parameters = ["get": "value01",
                          "arr": ["元素1", "元素2"],
                          "dic":["key1":"value1", "key2":"value2"]]

        sessionDataTaskRequest("GET", parameters: parameters)
    }
    
    @IBAction func tapSessionPostButton(sender: AnyObject) {
        let parameters = ["post": "value01",
                          "arr": ["元素1", "元素2"],
                          "dic":["key1":"value1", "key2":"value2"]]
        
        sessionDataTaskRequest("POST", parameters: parameters)
    }
    
    
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
            
            self.uploadTask(fileData!)
        }
    }
    
    
    func uploadTask(parameters:NSData) {
        let uploadUrlString = "http://127.0.0.1/upload.php"
        let url: NSURL = NSURL.init(string: uploadUrlString)!
        
        let request = NSMutableURLRequest.init(URL: url)
        request.HTTPMethod = "POST"
        
        let session: NSURLSession = NSURLSession.sharedSession()
        let uploadTask = session.uploadTaskWithRequest(request, fromData: parameters) {
            (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            if error != nil{
                print(error?.code)
                print(error?.description)
            }else{
                print("上传成功")
            }
        }
        //使用resume方法启动任务
        uploadTask.resume()

        
    }
    
    /**
     NSURLSessionDataTask
     
     - parameter method:     NSURLSessionDataTask
     - parameter parameters: 字典形式的参数
     */
    
    func sessionDataTaskRequest(method: String, parameters:[String:AnyObject]){
        
        let escapeQueryString = query(parameters)
        
        print("转义后的url字符串：" + escapeQueryString)
        
        if method == "GET" {
            hostString += "?" + escapeQueryString
        }

        let url: NSURL = NSURL.init(string: hostString)!
        let request: NSMutableURLRequest = NSMutableURLRequest.init(URL: url)
        request.HTTPMethod = method
        
        if method == "POST" {
            request.HTTPBody = escapeQueryString.dataUsingEncoding(NSUTF8StringEncoding)
        }
        

        
        let session: NSURLSession = NSURLSession.sharedSession()
        
        let sessionTask: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
            if error != nil {
                print(error)
                return
            }
            if data != nil {
                print(data)
                let json = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                print(json)
            }
        });
        
        sessionTask.resume()
    }
    
    
    
    

    
    
    
    
    
    // - MARK - Alamofire中的三个方法该方法将字典转换成json串
    func query(parameters: [String: AnyObject]) -> String {
        var components: [(String, String)] = []
        
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
     对加入到URL中的字符进行编码，因为字符串中有些字符会引起歧义，URL采用ASCII码，而非Unicode编码
     RFC3986文档规定，Url中只允许包含英文字母（a-zA-Z）、数字（0-9）、-_.~4个特殊字符以及所有保留字符
     http://www.cnblogs.com/greatverve/archive/2011/12/12/URL-Encoding-Decoding.html
     
     foo://example.com:8042/over/there?name=ferret#nose
     
     \_/ \______________/ \________/\_________/ \__/
     
     |         |              |         |        |
     
     scheme     authority        path     query   fragment
     
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
            let batchSize = 50
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


    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

