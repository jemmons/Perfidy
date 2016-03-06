import Foundation
import Rebar


struct HTTPMessage{
  private let message:CFHTTPMessageRef
  var needsMoreHeader:Bool{
    return CFHTTPMessageIsHeaderComplete(message)
  }
  var needsBody:Bool{
    var hasFormType = false
    var hasJSONType = false
    if let contentType = headers?["Content-Type"]{
      hasFormType = contentType.containsString("application/x-www-form-urlencoded")
      hasJSONType = contentType.containsString("application/json")
    }
    return (hasFormType || hasJSONType) && contentLength > 0
  }
  var method:String?{
    return CFHTTPMessageCopyRequestMethod(message)?.takeRetainedValue() as String?
  }
  var url:NSURL?{
    return CFHTTPMessageCopyRequestURL(message)?.takeRetainedValue() as NSURL?
  }
  var headers:[String:String]?{
    return CFHTTPMessageCopyAllHeaderFields(message)?.takeRetainedValue() as? [String : String]
  }
  var data:NSData?{
    return CFHTTPMessageCopySerializedMessage(message)?.takeRetainedValue()
  }
  var contentLength:Int{
    guard let
      _lengthString = headers?["Content-Length"],
      length = Int(_lengthString) else{
        return 0
    }
    return length
  }
  var body:NSData?{
    return CFHTTPMessageCopyBody(message)?.takeRetainedValue() as NSData?
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
    message = CFHTTPMessageCreateEmpty(nil, yes).takeRetainedValue()
  }
  
  
  init(response: Response){
    message = CFHTTPMessageCreateResponse(nil, response.status, nil, kCFHTTPVersion1_1).takeRetainedValue()
    for (key, value) in response.headers {
      CFHTTPMessageSetHeaderFieldValue(message, key as CFString, value as CFString)
    }
    if let data = response.data {
      CFHTTPMessageSetBody(message, data as CFData)
    }
  }
  
  
  func append(data:NSData){
    CFHTTPMessageAppendBytes(message, unsafeBitCast(data.bytes, UnsafePointer<UInt8>.self), data.length)
  }
}