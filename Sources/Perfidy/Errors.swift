import Foundation
import NIO



public enum FileError: LocalizedError {
  case malformed(String)
  
  
  public var errorDescription: String {
    switch self {
    case .malformed(let name):
      return "Perfidy couldn't parse the file of endpoints named \(name)."
    }
  }
}



public struct UnknownNetworkError: LocalizedError {
  private let reason: String
  
  
  internal init(ioError: IOError) {
    self.init(reason: ioError.description)
  }
  
  
  public init(reason: String) {
    self.reason = reason
  }
  
  
  public var errorDescription: String? {
    return reason
  }
}



public enum NetworkError: LocalizedError {
  case portAlreadyInUse(port: Int)
  
  
  public var errorDescription: String? {
    switch self {
    case .portAlreadyInUse(let port):
      return "The port \(port) is already in use."
    }
  }
}
