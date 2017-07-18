import Foundation



struct HTTPMessage{
  private let message:CFHTTPMessage

  
  var needsMoreHeader:Bool{
    let headerComplete = CFHTTPMessageIsHeaderComplete(message)
    return !headerComplete
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
    return CFHTTPMessageCopyRequestMethod(message)?.takeRetainedValue() as String?
  }
  
  
  var url:URL?{
    return CFHTTPMessageCopyRequestURL(message)?.takeRetainedValue() as URL?
  }
  
  
  var headers:[String:String]?{
    guard let
      cfdict = CFHTTPMessageCopyAllHeaderFields(message)?.takeRetainedValue() else {
        return nil
    }
    return cfdict as? [String: String]
  }
  
  
  var data:Data?{
    return CFHTTPMessageCopySerializedMessage(message)?.takeRetainedValue() as Data?
  }
  
  
  var contentLength:Int{
    guard let
      _lengthString = headers?["Content-Length"],
      let length = Int(_lengthString) else{
        return 0
    }
    return length
  }
  
  
  var body:Data?{
    return CFHTTPMessageCopyBody(message)?.takeRetainedValue() as Data?
  }
  
  
  var bodyString:String?{
    switch body{
    case .some(let data):
      return String(data:data, encoding:.utf8)
    case .none:
      return nil
    }
  }
  
  
  var request: URLRequest{
    //The new URLRequest struct oddly requires we initialize it with a URL.
    var req = URLRequest(url: URL(string: "example.com")!)
    req.url = CFHTTPMessageCopyRequestURL(message)?.takeRetainedValue() as URL?

    if
      let _unretainedHeaders = CFHTTPMessageCopyAllHeaderFields(message),
      let headers = _unretainedHeaders.takeRetainedValue() as? [String: String] {
      req.allHTTPHeaderFields = headers
    }
    
    if let body = CFHTTPMessageCopyBody(message) {
      req.httpBody = body.takeRetainedValue() as Data
    }
    if let method = CFHTTPMessageCopyRequestMethod(message) {
      req.httpMethod = method.takeRetainedValue() as String
    }
    return req
  }
  
  
  init(){
    message = CFHTTPMessageCreateEmpty(nil, true).takeRetainedValue()
  }
  
  
  init(response: Response){
    message = CFHTTPMessageCreateResponse(nil, response.status, nil, kCFHTTPVersion1_1).takeRetainedValue()
    for (key, value) in response.headers {
      CFHTTPMessageSetHeaderFieldValue(message, key as CFString, value as CFString)
    }
    if let body = response.body {
      CFHTTPMessageSetBody(message, body as CFData)
    }
  }
  
  
  func append(_ data:Data){
    data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
      CFHTTPMessageAppendBytes(message, bytes, data.count)
    }
  }
}
