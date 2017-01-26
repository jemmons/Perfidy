import Foundation
import Medea



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
    self.headers = Helper.merging(headers, on: contentLengthHeader)
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [String:String](), text: String) {
    let mergedHeaders = Helper.merging(headers, on: [Const.contentTypeKey: Const.textContentType])
    let data = text.data(using: .utf8, allowLossyConversion: true)!
    self.init(status: status, headers: mergedHeaders, data: data)
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [String:String](), jsonObject: JSONObject) throws {
    let data = try JSONHelper.data(from: jsonObject)
    let mergedHeaders = Helper.merging(headers, on: [Const.contentTypeKey: Const.jsonContentType])
    self.init(status: status, headers: mergedHeaders, data: data)
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [String:String](), jsonArray: JSONArray) throws {
    let data = try JSONHelper.data(from: jsonArray)
    let mergedHeaders = Helper.merging(headers, on: [Const.contentTypeKey: Const.jsonContentType])
    self.init(status: status, headers: mergedHeaders, data: data)
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [String:String](), rawJSON: String) throws {
    let mergedHeaders = Helper.merging(headers, on: [Const.contentTypeKey: Const.jsonContentType])
    try JSONHelper.validate(rawJSON)
    self.init(status: status, headers: mergedHeaders, data: rawJSON.data(using: .utf8)!)
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
    var json = [AnyHashable: Any]()
    elements.forEach{ key, value in
      json[key] = value
    }

    //NOTE: Becuase of the way «DictionaryLiteralConvertible» is defined, this initializer is the one that gets called when there are no arguments (as in: «Response()»).
    guard !json.isEmpty else {
      self.init(data: nil)
      return
    }
    try! self.init(jsonObject: json)
  }
}



//We'd implement array literal for JSON also, but JSON arrays are rare and the empty `Response()` becomes ambiguous if we have it.



extension Response: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.init(status: value, data: nil)
  }
}



private enum Helper {
  static func merging<K: Hashable, V>(_ source: [K: V], on target: [K: V]) -> [K: V] {
    return source.reduce(target){ (last, next) in
      var mutatingCopy = last
      let (key, value) = next
      mutatingCopy.updateValue(value, forKey:key)
      return mutatingCopy
    }
  }
}
