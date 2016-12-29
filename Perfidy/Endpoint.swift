import Foundation

public struct Endpoint{
  fileprivate let method: Verb
  fileprivate var path: String

  public init(method: Verb? = nil, path: String? = nil) {
    self.method = method ?? .get
    self.path = path ?? "/"
  }
  
  
  public init(method: String?, path: String?) {
    self.init(method: Verb(rawValue: method ?? "🚫"), path: path)
  }
  
  init(request: URLRequest) {
    self.init(method: request.httpMethod, path: request.url?.path)
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



extension Endpoint: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(path: Helper.pathFromString(value))
  }
  
  
  public init(unicodeScalarLiteral value: String){
    self.init(path: Helper.pathFromString(value))
  }
  
  
  public init(extendedGraphemeClusterLiteral value: String){
    self.init(path: Helper.pathFromString(value))
  }
}



fileprivate enum Helper {
  fileprivate static func pathFromString(_ string:String) -> String {
    let path = string.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)?.replacingOccurrences(of: "%20", with: "+") ?? "/"
    return path.hasPrefix("/") ? path : "/" + path
  }
}



public func ==(lhs: Endpoint, rhs: Endpoint) -> Bool {
  return lhs.method == rhs.method && lhs.path == rhs.path
}
