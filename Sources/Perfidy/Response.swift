import Foundation



private enum Const {
  static let contentLengthKey = "Content-Length"
  static let contentTypeKey = "Content-Type"
  static let jsonContentType = "application/json"
  static let textContentType = "text/html"
}



/**
 A simple struct that encapsulates the ideas of a status code, body, and HTTP headers.

 As part of its «body» management, it automagically inserts the proper `Content-Length` into headers if not already present.
 
 Using the json, and text convenience initializers also sets the `Content-Type` if not already present.
 */
public struct Response {
  public enum Error: LocalizedError {
    case unableToSerializeJSON
    
    public var errorDescription: String? {
      switch self {
      case .unableToSerializeJSON:
        return "Unable to convert given JSON to data."
      }
    }
      
    public var failureReason: String? {
      switch self {
      case .unableToSerializeJSON:
        return "JSON Serialization Error"
      }
    }
  }
  
  
  public let status: Int
  public let body: Data?
  public let headers: [String:String]
  
  
  public init(status: Int? = nil, headers: [String:String] = [:], data: Data?) {
    self.status = status ?? 200
    self.body = data
    let contentLengthHeader = data == nil ? [:] : [Const.contentLengthKey:String(data!.count)]
    self.headers = headers.merging(onto: contentLengthHeader)
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [:], text: String) {
    let mergedHeaders = headers.merging(onto: [Const.contentTypeKey: Const.textContentType])
    let data = text.data(using: .utf8, allowLossyConversion: true)!
    self.init(status: status, headers: mergedHeaders, data: data)
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [:], jsonObject: JSONObject) throws {
    guard JSONSerialization.isValidJSONObject(jsonObject) else {
      throw Error.unableToSerializeJSON
    }
    let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
    let mergedHeaders = headers.merging(onto: [Const.contentTypeKey: Const.jsonContentType])
    self.init(status: status, headers: mergedHeaders, data: data)
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [:], jsonArray: JSONArray) throws {
    guard JSONSerialization.isValidJSONObject(jsonArray) else {
      throw Error.unableToSerializeJSON
    }
    let data = try JSONSerialization.data(withJSONObject: jsonArray, options: [])
    let mergedHeaders = headers.merging(onto: [Const.contentTypeKey: Const.jsonContentType])
    self.init(status: status, headers: mergedHeaders, data: data)
  }
  
  
  public init(status: Int = 200, headers: [String:String] = [:], rawJSON: String) throws {
    let mergedHeaders = headers.merging(onto: [Const.contentTypeKey: Const.jsonContentType])
    let jsonData = Data(rawJSON.utf8)
    _ = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
    self.init(status: status, headers: mergedHeaders, data: jsonData)
  }
}



//NOTE: There's probably a case to be made for strings translating into «rawJSON» instead of text/html. But text seems the more expected outcome to me. To do JSON, use «DictionaryLiteralConvertible».
extension Response: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(text: value)
  }
}


extension Response: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (AnyHashable, Any)...) {
    var json = JSONObject()
    elements.forEach{ key, value in
      guard let string = key as? String else {
        return
      }
      json[string] = value
    }

    //NOTE: Becuase of the way «DictionaryLiteralConvertible» is defined, this initializer is the one that gets called when there are no arguments (as in: «Response()»).
    guard !json.isEmpty else {
      self.init(data: nil)
      return
    }
    try! self.init(jsonObject: json)
  }
}



// We'd implement array literal for JSON also, but JSON arrays are rare and the empty `Response()` becomes ambiguous if we have it.



extension Response: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.init(status: value, data: nil)
  }
}



private extension Dictionary {
  func merging(onto right: Dictionary<Key, Value>) -> [Key: Value] {
    return merging(right) { left, right in left }
  }
}
