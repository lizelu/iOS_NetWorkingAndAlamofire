//: Playground - noun: a place where people can play

import UIKit

//使用协议扩展进行数据类型的转换
protocol BaseNumberStringConvertible {
    var intValue: Int? { get }
    var doubleValue: Double? { get }
    var floatValue: Float? { get }
}

extension String: BaseNumberStringConvertible {
    public var intValue: Int? {
        if let floatValue = self.floatValue {
            return Int(floatValue)
        }
        return nil
    }
    
    public var floatValue: Float? {
        return Float(self)
    }
    
    public var doubleValue: Double? {
        return Double(self)
    }
}


var numberString = "1.22"
numberString.intValue
numberString.floatValue
numberString.doubleValue




//尾随闭包初始化

class TestClass1 {
    var closure: (p1: String, p2: String, p3: String) -> String
    init(myClosure: (p1: String, p2: String, p3: String) -> String) {
        self.closure = myClosure
    }
}

let testObj01 = TestClass1{(p1, p2, p3) in
    return (p1 + p2 + p3)
}
testObj01.closure(p1: "a", p2: "b", p3: "c")



let testObj02 = TestClass1 { (p1, p2, p3) -> String in
    return (p1 + p2 + p3)
}
testObj02.closure(p1: "a", p2: "b", p3: "c")


let testObj03 = TestClass1(myClosure: {(p1, p2, p3) -> String in
        return (p1 + p2 + p3)
    }
)
testObj03.closure(p1: "a", p2: "b", p3: "c")






/// 另一种使用方式=======-------========-------========---------==========
typealias MyClosureType = (p1: String, p2: String, p3: String) -> String

class TestClass2 {
    var closure: MyClosureType
    
    init(myClosure: MyClosureType) {
        self.closure = myClosure
    }
    
}

let testObj04 = TestClass2 { (p1, p2, p3) -> String in
    return (p1 + p2 + p3)
}
testObj04.closure(p1: "A", p2: "B", p3: "C")

