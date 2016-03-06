import Foundation

public enum Verb:String{
  case GET="GET", HEAD="HEAD", POST="POST", PUT="PUT", PATCH="PATCH", DELETE="DELETE"
  
  public init(string:String){
    self = Verb(rawValue: string.uppercaseString) ?? Verb.GET
  }
}



extension Verb: CustomStringConvertible {
  public var description: String {
    return self.rawValue
  }
}
