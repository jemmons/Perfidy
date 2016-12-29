import Foundation
import Medea
import Rebar


private enum Const {
  static let contentLengthKey = "Content-Length"
  static let contentTypeKey = "Content-Type"
  static let jsonContentType = "application/json"
  static let textContentType = "text/html"
}



/// A simple struct that encapsulates the ideas of a status code, body, and HTTP headers.
///
/// As part of its «body» management, it automagically inserts the proper `Content-Length` into headers if not already present.
/// 
/// Using the json, and text convenience initializers also sets the `Content-Type` if not already present.
public struct Response {
  public let status: Int
  public let body: Data?
  public let headers: [String:String]
  
  
  public init(status: Int = 200, headers: [String:String] = [String:String](), data: Data?) {
    self.status = status
    self.body = data
    let contentLengthHeader = data == nil ? [:] : [Const.contentLengthKey:String(data!.count)]
    self.headers = contentLengthHeader + headers
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [String:String](), text: String) {
    let mergedHeaders = [Const.contentTypeKey: Const.textContentType] + headers
    let data = text.data(using: .utf8, allowLossyConversion: true)!
    self.init(status: status, headers: mergedHeaders, data: data)
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [String:String](), json: JSONObject) throws {
    let data = try JSONHelper.data(from: json)
    let mergedHeaders = [Const.contentTypeKey: Const.jsonContentType] + headers
    self.init(status: status, headers: mergedHeaders, data: data)
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [String:String](), rawJSON: String) throws {
    let mergedHeaders = [Const.contentTypeKey: Const.jsonContentType] + headers

    //We're making this round-trip just to validate the JSON
    let data = try JSONHelper.data(from: JSONHelper.json(from: rawJSON))
    self.init(status: status, headers: mergedHeaders, data: data)
  }
}



//NOTE: There's probably a case to be made for strings translating into «rawJSON» instead of text/html. But text seems the more expected outcome to me. To do JSON, use «DictionaryLiteralConvertible».
extension Response: ExpressibleByStringLiteral {
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


extension Response: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (AnyHashable, Any)...) {
    let json = Dictionary(pairs: elements as [(key: AnyHashable, value: Any)])
    //NOTE: Becuase of the way «DictionaryLiteralConvertible» is defined, this initializer is the one that gets called when there are no arguments (as in: «Response()»).
    guard json.isNotEmpty else {
      self.init(data: nil)
      return
    }
    try! self.init(json: json)
  }
}



extension Response: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.init(status: value, data: nil)
  }
}
