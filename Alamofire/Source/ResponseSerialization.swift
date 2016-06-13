//
//  ResponseSerialization.swift
//
//  Copyright (c) 2014-2016 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

// MARK: ResponseSerializer

/**
    The type in which all response serializers must conform to in order to serialize a response.
*/
public protocol ResponseSerializerType {
    /// The type of serialized object to be created by this `ResponseSerializerType`.
    associatedtype SerializedObject

    /// The type of error to be created by this `ResponseSerializer` if serialization fails.
    associatedtype ErrorObject: ErrorType

    /**
        A closure used by response handlers that takes a request, response, data and error and returns a result.
    */
    var serializeResponse: (NSURLRequest?, NSHTTPURLResponse?, NSData?, NSError?) -> Result<SerializedObject, ErrorObject> { get }
}

// MARK: -

/**
    A generic `ResponseSerializerType` used to serialize a request, response, and data into a serialized object.
*/
public struct ResponseSerializer<Value, Error: ErrorType>: ResponseSerializerType {
    
    
    /***
      *  下方这两个typealiast可以不写，但是为了代码良好的阅读性可以进行添加
      *   Value这个泛型等效于ResponseSerializerType协议中的SerializedObject
      *   Error 等效于ResponseSerializerType协议中的ErrorObject
      */
    /// The type of serialized object to be created by this `ResponseSerializer`.
    public typealias SerializedObject = Value

    /// The type of error to be created by this `ResponseSerializer` if serialization fails.
    public typealias ErrorObject = Error

    //====================================================================
    
    
    /**
        A closure used by response handlers that takes a request, response, data and error and returns a result.
    */
    public var serializeResponse: (NSURLRequest?, NSHTTPURLResponse?, NSData?, NSError?) -> Result<Value, Error>

    /**
        Initializes the `ResponseSerializer` instance with the given serialize response closure.

        - parameter serializeResponse: The closure used to serialize the response.

        - returns: The new generic response serializer instance.
    */
    public init(serializeResponse: (NSURLRequest?, NSHTTPURLResponse?, NSData?, NSError?) -> Result<Value, Error>) {
        self.serializeResponse = serializeResponse
    }
}

// MARK: - Default

extension Request {

    /**
        Adds a handler to be called once the request has finished.

        - parameter queue:             The queue on which the completion handler is dispatched.
        - parameter completionHandler: The code to be executed once the request has finished.

        - returns: The request.
    */
    //该方法负责将数据解析的Closure放到主线程中去执行
    public func response(
        queue queue: dispatch_queue_t? = nil,
        completionHandler: (NSURLRequest?, NSHTTPURLResponse?, NSData?, NSError?) -> Void)
        -> Self
    {
        delegate.queue.addOperationWithBlock {
            dispatch_async(queue ?? dispatch_get_main_queue()) {
                completionHandler(self.request, self.response, self.delegate.data, self.delegate.error)
            }
        }

        return self
    }
    
    

    /**
        Adds a handler to be called once the request has finished.

        - parameter queue:              The queue on which the completion handler is dispatched.
        - parameter responseSerializer: The response serializer responsible for serializing the request, response, 
                                        and data.
        - parameter completionHandler:  The code to be executed once the request has finished.

        - returns: The request.
    */
    /**
     根据传入的responseSerializer闭包来解析请求到的网络数据
     
     - parameter queue:              处理响应的线程队列，默认是主队列
     - parameter responseSerializer: 解析响应数据的闭包块，如果是JOSN解析就传入JOSN相应的解析块，支持Data，String，JSON等解析
     - parameter completionHandler:  将解析后的结果进一步进行组织，通过completionHandler闭包，回调给用户使用
     
     - returns: 返回当前对象，便于链式调用
     */
    public func response<T: ResponseSerializerType>(
        queue queue: dispatch_queue_t? = nil,
        responseSerializer: T,
        completionHandler: Response<T.SerializedObject, T.ErrorObject> -> Void)
        -> Self
    {
        delegate.queue.addOperationWithBlock {
            
            ///会执行相应解析的Closure, 将网络请求的数据进行解析，并返回解析结果(Result泛型对象)
            let result = responseSerializer.serializeResponse(
                self.request,
                self.response,
                self.delegate.data,
                self.delegate.error
            )

            //各种时间的计算
            let requestCompletedTime = self.endTime ?? CFAbsoluteTimeGetCurrent()
            let initialResponseTime = self.delegate.initialResponseTime ?? requestCompletedTime

            let timeline = Timeline(
                requestStartTime: self.startTime ?? CFAbsoluteTimeGetCurrent(),
                initialResponseTime: initialResponseTime,
                requestCompletedTime: requestCompletedTime,
                serializationCompletedTime: CFAbsoluteTimeGetCurrent()
            )

            
            //将上述已经解析的数据和时间与原来的相应报文进行重组，生成Response对象
            let response = Response<T.SerializedObject, T.ErrorObject>(
                request: self.request,
                response: self.response,
                data: self.delegate.data,
                result: result,
                timeline: timeline
            )

            //通过completionHandler回调闭包块，将response对象回传给用户
            dispatch_async(queue ?? dispatch_get_main_queue()) { completionHandler(response) }
        }

        return self
    }
}








// MARK: - 各种解析方案，便于扩展，每一个Request的延展就是一种解析方案
//只要遵循ResponseSerializer协议，就可以扩充解析方案

// MARK: - Data---二进制解析

extension Request {

    /**
        Creates a response serializer that returns the associated data as-is.

        - returns: A data response serializer.
    */
    public static func dataResponseSerializer() -> ResponseSerializer<NSData, NSError> {
        return ResponseSerializer { _, response, data, error in
            guard error == nil else { return .Failure(error!) }

            if let response = response where response.statusCode == 204 { return .Success(NSData()) }

            guard let validData = data else {
                let failureReason = "Data could not be serialized. Input data was nil."
                let error = Error.error(code: .DataSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }

            return .Success(validData)
        }
    }

    /**
        Adds a handler to be called once the request has finished.

        - parameter completionHandler: The code to be executed once the request has finished.

        - returns: The request.
    */
    public func responseData(
        queue queue: dispatch_queue_t? = nil,
        completionHandler: Response<NSData, NSError> -> Void)
        -> Self
    {
        return response(queue: queue, responseSerializer: Request.dataResponseSerializer(), completionHandler: completionHandler)
    }
}








// MARK: - String--字符串解析

extension Request {

    /**
        Creates a response serializer that returns a string initialized from the response data with the specified 
        string encoding.

        - parameter encoding: The string encoding. If `nil`, the string encoding will be determined from the server 
                              response, falling back to the default HTTP default character set, ISO-8859-1.

        - returns: A string response serializer.
    */
    public static func stringResponseSerializer(
        encoding encoding: NSStringEncoding? = nil)
        -> ResponseSerializer<String, NSError>
    {
        return ResponseSerializer { _, response, data, error in
            guard error == nil else { return .Failure(error!) }

            if let response = response where response.statusCode == 204 { return .Success("") }

            guard let validData = data else {
                let failureReason = "String could not be serialized. Input data was nil."
                let error = Error.error(code: .StringSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }
            
            var convertedEncoding = encoding
            
            if let encodingName = response?.textEncodingName where convertedEncoding == nil {
                convertedEncoding = CFStringConvertEncodingToNSStringEncoding(
                    CFStringConvertIANACharSetNameToEncoding(encodingName)
                )
            }

            let actualEncoding = convertedEncoding ?? NSISOLatin1StringEncoding

            if let string = String(data: validData, encoding: actualEncoding) {
                return .Success(string)
            } else {
                let failureReason = "String could not be serialized with encoding: \(actualEncoding)"
                let error = Error.error(code: .StringSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }
        }
    }

    /**
        Adds a handler to be called once the request has finished.

        - parameter encoding:          The string encoding. If `nil`, the string encoding will be determined from the 
                                       server response, falling back to the default HTTP default character set, 
                                       ISO-8859-1.
        - parameter completionHandler: A closure to be executed once the request has finished.

        - returns: The request.
    */
    public func responseString(
        queue queue: dispatch_queue_t? = nil,
        encoding: NSStringEncoding? = nil,
        completionHandler: Response<String, NSError> -> Void)
        -> Self
    {
        return response(
            queue: queue,
            responseSerializer: Request.stringResponseSerializer(encoding: encoding),
            completionHandler: completionHandler
        )
    }
}











// MARK: - JSON---JSON解析

extension Request {

    /**
        Creates a response serializer that returns a JSON object constructed from the response data using 
        `NSJSONSerialization` with the specified reading options.

        - parameter options: The JSON serialization reading options. `.AllowFragments` by default.

        - returns: A JSON object response serializer.
    */
    public static func JSONResponseSerializer(
        options options: NSJSONReadingOptions = .AllowFragments)
        -> ResponseSerializer<AnyObject, NSError>
    {
        
        /**
         *  实例化 ResponseSerializer 对象，参数serializeResponse就是后边的闭包
         *  将解析后的数据存入Result枚举中并返回枚举值
         */
        return ResponseSerializer { _, response, data, error in
            guard error == nil else { return .Failure(error!) }

            if let response = response where response.statusCode == 204 { return .Success(NSNull()) }

            guard let validData = data where validData.length > 0 else {
                let failureReason = "JSON could not be serialized. Input data was nil or zero length."
                let error = Error.error(code: .JSONSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }

            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(validData, options: options)
                return .Success(JSON)
            } catch {
                return .Failure(error as NSError)
            }
        }
        
        
        
        
        //上方代码与下方代码等价
//        let responseSerializer: ResponseSerializer<AnyObject, NSError> =
//            ResponseSerializer<AnyObject, NSError>(serializeResponse:
//            {(request, respons, data, error) in
//                //对数据进行JSON解析
//            })
//        return responseSerializer
    }

    /**
        Adds a handler to be called once the request has finished.

        - parameter options:           The JSON serialization reading options. `.AllowFragments` by default.
        - parameter completionHandler: A closure to be executed once the request has finished.

        - returns: The request.
    */
    public func responseJSON(
        queue queue: dispatch_queue_t? = nil,
        options: NSJSONReadingOptions = .AllowFragments,
        completionHandler: Response<AnyObject, NSError> -> Void)
        -> Self
    {
        return response(
            queue: queue,
            responseSerializer: Request.JSONResponseSerializer(options: options),
            completionHandler: completionHandler
        )
    }
}

// MARK: - Property List

extension Request {

    /**
        Creates a response serializer that returns an object constructed from the response data using 
        `NSPropertyListSerialization` with the specified reading options.

        - parameter options: The property list reading options. `NSPropertyListReadOptions()` by default.

        - returns: A property list object response serializer.
    */
    public static func propertyListResponseSerializer(
        options options: NSPropertyListReadOptions = NSPropertyListReadOptions())
        -> ResponseSerializer<AnyObject, NSError>
    {
        return ResponseSerializer { _, response, data, error in
            guard error == nil else { return .Failure(error!) }

            if let response = response where response.statusCode == 204 { return .Success(NSNull()) }

            guard let validData = data where validData.length > 0 else {
                let failureReason = "Property list could not be serialized. Input data was nil or zero length."
                let error = Error.error(code: .PropertyListSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }

            do {
                let plist = try NSPropertyListSerialization.propertyListWithData(validData, options: options, format: nil)
                return .Success(plist)
            } catch {
                return .Failure(error as NSError)
            }
        }
    }

    /**
        Adds a handler to be called once the request has finished.

        - parameter options:           The property list reading options. `0` by default.
        - parameter completionHandler: A closure to be executed once the request has finished. The closure takes 3
                                       arguments: the URL request, the URL response, the server data and the result 
                                       produced while creating the property list.

        - returns: The request.
    */
    public func responsePropertyList(
        queue queue: dispatch_queue_t? = nil,
        options: NSPropertyListReadOptions = NSPropertyListReadOptions(),
        completionHandler: Response<AnyObject, NSError> -> Void)
        -> Self
    {
        return response(
            queue: queue,
            responseSerializer: Request.propertyListResponseSerializer(options: options),
            completionHandler: completionHandler
        )
    }
}
