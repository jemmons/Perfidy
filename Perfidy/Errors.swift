import Foundation



public enum FileError: LocalizedError {
  case malformed(String)
  
  
  public var localizedDescription: String {
    switch self {
    case .malformed(let name):
      return "Perfidy couldn't parse the file of endpoints named \(name)."
    }
  }
}
