import Foundation
import NIOHTTP1



public struct Route: Hashable, Equatable {
  private let method: Verb
  private var path: String


  public init(method: Verb? = nil, path: String? = nil) {
    self.method = method ?? .get
    self.path = path ?? "/"
  }
  
  
  public init(method: String?, path: String?) {
    let maybeMethod = method.flatMap(Verb.init(string:))
    self.init(method: maybeMethod, path: path)
  }
  
  
  init(request: URLRequest) {
    self.init(method: request.httpMethod, path: request.url?.path)
  }
  
  
  init(requestHead: HTTPRequestHead) {
    let maybeURL = URL(string: requestHead.uri)
    self.init(method: requestHead.method.rawValue, path: maybeURL?.path)
  }
}



extension Route: CustomStringConvertible {
  public var description: String {
    return "\(method.rawValue) \(path)"
  }
}



extension Route: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    let (method, path) = Helper.methodAndPath(from: value)
    self.init(method: method, path: path)
  }
}



fileprivate enum Helper {
  static func methodAndPath(from string: String) -> (Verb?, String?) {
    let comp = string.components(separatedBy: " ")

    guard let verb = comp.first.flatMap(Verb.init(string:)) else {
      return (nil, formatPath(string))
    }
    
    let rest = comp
      .dropFirst()
      .joined(separator: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return (verb, formatPath(rest))
  }

  
  static func formatPath(_ string:String?) -> String? {
    guard
      let _string = string,
      _string.trimmingCharacters(in: .whitespacesAndNewlines) != "",
      let path = _string.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)?.replacingOccurrences(of: "%20", with: "+") else {
        return nil
    }
    
    return path.hasPrefix("/") ? path : "/" + path
  }
}
