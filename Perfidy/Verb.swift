import Foundation

public enum Verb:String{
  case get="GET", head="HEAD", post="POST", put="PUT", patch="PATCH", delete="DELETE"
  
  public init(string:String){
    self = Verb(rawValue: string.uppercased()) ?? .get
  }
}



extension Verb: CustomStringConvertible {
  public var description: String {
    return self.rawValue
  }
}
