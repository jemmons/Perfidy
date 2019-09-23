import Foundation



public enum Verb: String, Equatable {
  case get="GET", head="HEAD", post="POST", put="PUT", patch="PATCH", delete="DELETE"
  
  
  public init?(string: String) {
    guard let someVerb = Verb(rawValue: string.uppercased()) else {
      return nil
    }
    self = someVerb
  }
}



extension Verb: CustomStringConvertible {
  public var description: String {
    return self.rawValue
  }
}
