import Foundation

public struct Endpoint{
  let method: Verb
  var path: String

  public init(method: Verb? = nil, path: String? = nil) {
    self.method = method ?? .GET
    self.path = path ?? "/"
  }
  
  
  public init(method: String?, path: String?) {
    self.init(method: Verb(rawValue: method ?? ""), path: path)
  }
}



extension Endpoint: Hashable{
  public var hashValue:Int{
    return path.hashValue ^ method.hashValue
  }
}



extension Endpoint: CustomStringConvertible {
  public var description: String {
    return "\(method.rawValue) \(path)"
  }
}



extension Endpoint: StringLiteralConvertible {
  private static func pathFromString(string:String) -> String {
    let path = string.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet())?.stringByReplacingOccurrencesOfString("%20", withString: "+") ?? "/"
    guard path.hasPrefix("/") else {
      return "/\(path)"
    }
    return path
  }

  
  public init(stringLiteral value: String) {
    self.init(path: Endpoint.pathFromString(value))
  }
  
  
  public init(unicodeScalarLiteral value: String){
    self.init(path: Endpoint.pathFromString(value))
  }
  
  
  public init(extendedGraphemeClusterLiteral value: String){
    self.init(path: Endpoint.pathFromString(value))
  }
}


public func ==(lhs: Endpoint, rhs: Endpoint) -> Bool {
  return lhs.method == rhs.method && lhs.path == rhs.path
}
