import Foundation

public class DataHTTPURLResponse : NSHTTPURLResponse{
  var data:NSData?

  
  var allHeadersFields:NSDictionary{
    var headers = super.allHeaderFields
    if headers["Content-Length"] == nil{
      let length = data?.length ?? 0
      headers["Content-Length"] = String(length)
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


