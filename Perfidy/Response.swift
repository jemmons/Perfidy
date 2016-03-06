import Foundation

/// A simple subclass of `NSHTTPURLResponse` that encapsulates response body as well as header.
///
/// It adds a `data` property, related constructors, and automagically inserts `Content-Length` into headers if not already present.
public class Response : NSHTTPURLResponse{
  public static var contentLengthHeaderName:String{
    return "Content-Length"
  }
  public private(set) var data: NSData?

  //The URL of the response should refect the URL of the request. But we don't know the request until after initialization. Thus we need to make internal, mutable, URL storage for us to set later, and point the inherited «URL» property at it.
  internal var internalURL: NSURL?
  
  override public var URL: NSURL? {
    return internalURL
  }

  public override var allHeaderFields:[NSObject:AnyObject]{
    var headers = super.allHeaderFields
    if let someData = data where headers[Response.contentLengthHeaderName] == nil {
      headers[Response.contentLengthHeaderName] = String(someData.length)
    }
    return headers
  }
  
  var message: HTTPMessage{
    return HTTPMessage(response: self)
  }
  
  
  public init?(status: Int = 200, headers: [String:String] = [String:String](), data: NSData? = nil) {
    self.data = data
    super.init(URL: NSURL(), statusCode: status, HTTPVersion: kCFHTTPVersion1_1 as String, headerFields: headers)
    
  }
  
  
  public convenience init?(status:Int=200, headers:[String:String]=[String:String](), body:String){
    self.init(status: status, headers: headers, data: body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true))
  }

  
  public convenience init?(status: Int = 200, var headers: [String:String] = [String:String](), json: [NSObject:AnyObject]){
    headers["Content-Type"] = "application/json"
    guard let data = try? NSJSONSerialization.dataWithJSONObject(json, options: []) else {
      return nil
    }
    self.init(status: status, headers: headers, data: data)
  }

  
  public convenience init?(status:Int=200, var headers:[String:String]=[String:String](), rawJSON:String){
    headers["Content-Type"] = "application/json"
    self.init(status: status, headers: headers, data: rawJSON.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true))
  }
  
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}


