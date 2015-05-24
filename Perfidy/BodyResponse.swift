import Foundation

/// A simple subclass of `NSHTTPURLResponse` that encapsulates response body as well as header.
///
/// It adds a `data` property, related constructors, and automagically inserts `Content-Length` into headers if not already present.
public class BodyResponse : NSHTTPURLResponse{
  public static var contentLengthHeaderName:String{
    return "Content-Length"
  }
  public var data:NSData?
  
  public override var allHeaderFields:[NSObject:AnyObject]{
    var headers = super.allHeaderFields
    if let someData = data where headers[BodyResponse.contentLengthHeaderName] == nil {
      headers[BodyResponse.contentLengthHeaderName] = String(someData.length)
    }
    return headers
  }
  
  var message:HTTPMessage{
    return HTTPMessage(response:self)
  }
  
  
  public init?(url:NSURL=NSURL(string:"/")!, statusCode:Int=200, headerFields:[String:String]=[String:String](), data:NSData?=nil){
    self.data = data
    super.init(URL: url, statusCode: statusCode, HTTPVersion: kCFHTTPVersion1_1 as String, headerFields: headerFields)
  }
  
  
  public convenience init?(url:NSURL=NSURL(string:"/")!, statusCode:Int=200, headerFields:[String:String]=[String:String](), body:String){
    self.init(url:url, statusCode:statusCode, headerFields:headerFields, data:body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true))
  }

  
  public convenience init?(url:NSURL=NSURL(string:"/")!, statusCode:Int=200, var headerFields:[String:String]=[String:String](), rawJSON:String){
    headerFields["Content-Type"] = "application/json"
    self.init(url:url, statusCode:statusCode, headerFields:headerFields, data:rawJSON.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true))
  }

  
  public required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}


