import Foundation



public struct Route: Hashable {
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
    
    let rest = comp.dropFirst().joined(separator: " ")
    let trimmed = rest.trimmingCharacters(in: .whitespacesAndNewlines)
    return (verb, formatPath(trimmed))
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



public func ==(lhs: Route, rhs: Route) -> Bool {
  return lhs.method == rhs.method && lhs.path == rhs.path
}
