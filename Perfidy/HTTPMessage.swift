import Foundation


class HTTPMessage{
  let message:CFHTTPMessageRef
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
  
  
  init(){
    message = CFHTTPMessageCreateEmpty(nil, 1).takeRetainedValue() //1 == "true"
  }
  
  
  func append(data:NSData){
    CFHTTPMessageAppendBytes(message, unsafeBitCast(data.bytes, UnsafePointer<UInt8>.self), data.length)
  }
  
  
//  func statusCode()->Int{
//    return CFHTTPMessageGetResponseStatusCode(message)
//  }

//  func
//  
//
//  - (NSString *)headerField:(NSString *)headerField
//  {
//  return (__bridge_transfer NSString *)CFHTTPMessageCopyHeaderFieldValue(message, (__bridge CFStringRef)headerField);
//  }
}


extension String{
  func contains(substring:String)->Bool{
    return self.rangeOfString(substring) != nil
  }
}