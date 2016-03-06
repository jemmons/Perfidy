import Foundation
import Rebar

/// A simple struct that encapsulates the ideas of a status code, body, and HTTP headers.
///
/// As part of its «body» management, it automagically inserts the proper `Content-Length` into headers if not already present.
/// 
/// Using the json, and text convenience initializers also sets the `Content-Type` if not already present.
public struct Response {
  public enum Error: ErrorType {
    case invalidJSONObject
  }
  private struct K {
    static let contentLengthKey = "Content-Length"
    static let contentTypeKey = "Content-Type"
    static let jsonContentType = "application/json"
    static let textContentType = "text/html"
  }
  public let status: Int
  public let body: NSData?
  public let headers: [String:String]
  
  
  public init(status: Int = 200, headers: [String:String] = [String:String](), data: NSData?) {
    self.status = status
    self.body = data
    let contentLengthHeader = data == nil ? [:] : [K.contentLengthKey:String(data!.length)]
    self.headers = contentLengthHeader + headers
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [String:String](), text: String) {
    let mergedHeaders = [K.contentTypeKey:K.textContentType] + headers
    let data = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: yes)!
    self.init(status: status, headers: mergedHeaders, data: data)
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [String:String](), json: [NSObject:AnyObject]) throws {
    guard NSJSONSerialization.isValidJSONObject(json) else {
      throw Error.invalidJSONObject
    }
    let data = try NSJSONSerialization.dataWithJSONObject(json, options: [])
    let mergedHeaders = [K.contentTypeKey:K.jsonContentType] + headers
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



//NOTE: There's probably a case to be made for strings translating into «rawJSON» instead of text/html. But text seems the more naturally expected outcome to me. To do JSON, use «DictionaryLiteralConvertible».
extension Response: StringLiteralConvertible {
  public init(stringLiteral value: String) {
    self.init(text: value)
  }
  
  
  public init(unicodeScalarLiteral value: String){
    self.init(text: value)
  }
  
  
  public init(extendedGraphemeClusterLiteral value: String){
    self.init(text: value)
  }
}


extension Response: DictionaryLiteralConvertible {
  public init(dictionaryLiteral elements: (NSObject, AnyObject)...) {
    let json = Dictionary(pairs: elements)
    //NOTE: Becuase of the way «DictionaryLiteralConvertible» is defined, this initializer is the one that gets called when there are no arguments (as in: «Response()»).
    guard json.isNotEmpty else {
      self.init(data: nil)
      return
    }
    try! self.init(json: json)
  }
}



extension Response: IntegerLiteralConvertible {
  public init(integerLiteral value: Int) {
    self.init(status: value, data: nil)
  }
}
