import Foundation
import Rebar

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
    let (method, path) = Helper.methodAndPath(from: value)
    self.init(method: method, path: path)
  }
  
  
  public init(unicodeScalarLiteral value: String){
    let (method, path) = Helper.methodAndPath(from: value)
    self.init(method: method, path: path)
  }
  
  
  public init(extendedGraphemeClusterLiteral value: String){
    let (method, path) = Helper.methodAndPath(from: value)
    self.init(method: method, path: path)
  }
}



fileprivate enum Helper {
  static func methodAndPath(from string: String) -> (Verb?, String?) {
    let comp = string.components(separatedBy: " ")

    guard let verb = Verb(rawValue: comp.first!.uppercased()) else {
      return (nil, formatPath(string))
    }
    
    let rest = comp.dropFirst().joined(separator: " ").trimmingWhitespace
    return (verb, formatPath(rest))
  }

  
  static func formatPath(_ string:String?) -> String? {
    guard let path = string?.maybeBlank?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)?.replacingOccurrences(of: "%20", with: "+") else {
      return nil
    }
    return path.hasPrefix("/") ? path : "/" + path
  }
}



public func ==(lhs: Endpoint, rhs: Endpoint) -> Bool {
  return lhs.method == rhs.method && lhs.path == rhs.path
}
