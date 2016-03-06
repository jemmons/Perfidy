import Foundation
import Rebar

/// A simple struct that encapsulates the ideas of a status code, body, and HTTP headers.
///
/// As part of its «body» management, it automagically inserts the proper `Content-Length` into headers if not already present.
/// 
/// Using the json, and text convenience initializers also sets the `Content-Type` if not already present.
public struct Response {
  private struct K {
    static let contentLengthKey = "Content-Length"
    static let contentTypeKey = "Content-Type"
    static let jsonContentType = "application/json"
    static let textContentType = "text/html"
  }
  public let status: Int
  public let data: NSData?
  public let headers: [String:String]
  
  
  
  public init(status: Int = 200, headers: [String:String] = [String:String](), data: NSData? = nil) {
    self.status = status
    self.data = data
    let contentLengthHeader = data == nil ? [:] : [K.contentLengthKey:String(data!.length)]
    self.headers = contentLengthHeader + headers
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [String:String](), text: String) {
    let mergedHeaders = [K.contentTypeKey:K.textContentType] + headers
    let data = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: yes)!
    self.init(status: status, headers: mergedHeaders, data: data)
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [String:String](), json: [NSObject:AnyObject]) throws {
    let mergedHeaders = [K.contentTypeKey:K.jsonContentType] + headers
    let data = try NSJSONSerialization.dataWithJSONObject(json, options: [])
    self.init(status: status, headers: mergedHeaders, data: data)
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [String:String](), rawJSON: String) throws {
    let mergedHeaders = [K.contentTypeKey:K.jsonContentType] + headers

    //We're making this round-trip just to validate the JSON
    let stringData = rawJSON.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: yes)!
    let json = try NSJSONSerialization.JSONObjectWithData(stringData, options: [])
    let data = try NSJSONSerialization.dataWithJSONObject(json, options: [])
    
    self.init(status: status, headers: mergedHeaders, data: data)
  }
}