import Foundation


struct HTTPMessage{
  private let message:CFHTTPMessageRef
  var needsMoreHeader:Bool{
    return CFHTTPMessageIsHeaderComplete(message) == 0 //Converts int-based "Boolean" type to Bool.
  }
  var needsBody:Bool{
    var hasFormType = false
    var hasJSONType = false
    if let contentType = headers?["Content-Type"]{
      hasFormType = contentType.contains("application/x-www-form-urlencoded")
      hasJSONType = contentType.contains("application/json")
    }
    return (hasFormType || hasJSONType) && contentLength > 0
  }
  var method:String?{
    return CFHTTPMessageCopyRequestMethod(message).takeRetainedValue() as String?
  }
  var url:NSURL?{
    return CFHTTPMessageCopyRequestURL(message).takeRetainedValue() as NSURL?
  }
  var headers:[String:String]?{
    return CFHTTPMessageCopyAllHeaderFields(message).takeRetainedValue() as? [String : String]
  }
  var data:NSData?{
    return CFHTTPMessageCopySerializedMessage(message).takeRetainedValue()
  }
  var contentLength:Int{
    return headers?["Content-Length"]?.toInt() ?? 0
  }
  var body:NSData?{
    return CFHTTPMessageCopyBody(message).takeRetainedValue() as NSData?
  }
  var bodyString:String?{
    switch body{
    case .Some(let data):
      return NSString(data:data , encoding:NSUTF8StringEncoding) as? String
    case .None:
      return nil
    }
  }
  var request:NSURLRequest{
    return NSURLRequest.requestWithMessage(message)
  }
  
  
  init(){
    message = CFHTTPMessageCreateEmpty(nil, 1).takeRetainedValue() //1 == "true"
  }
  
  
  init(response:BodyResponse){
    message = CFHTTPMessageCreateResponse(nil, response.statusCode, nil, kCFHTTPVersion1_1).takeRetainedValue()
    for (key, value) in response.allHeaderFields{
      CFHTTPMessageSetHeaderFieldValue(message, key as! CFString, value as! CFString)
    }
    CFHTTPMessageSetBody(message, response.data)
  }
  
  
  func append(data:NSData){
    CFHTTPMessageAppendBytes(message, unsafeBitCast(data.bytes, UnsafePointer<UInt8>.self), data.length)
  }
}


extension String{
  func contains(substring:String)->Bool{
    return self.rangeOfString(substring) != nil
  }
}