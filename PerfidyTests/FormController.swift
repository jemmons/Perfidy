import UIKit

class MockForm {
  var firstName: String?
  var lastName: String?
  var age: Int?
  
  func fetch(){
    NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://localhost:10175/form")!) { data, response, error in
      guard error == nil else {
        self.fillWithJSON([:])
        return
      }
      let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [NSObject:AnyObject]
      self.fillWithJSON(json)
    }.resume()
  }
  
  
  func save(){
    var json = [NSObject:AnyObject]()
    json["first_name"] = "first"//firstName
    json["last_name"] = "last"//lastName
    json["age"] = "55"//age
    let data = try! NSJSONSerialization.dataWithJSONObject(json, options: [])
    let req = NSMutableURLRequest(URL: NSURL(string: "http://localhost:10175/form")!)
    req.HTTPMethod = "POST"
    NSURLSession.sharedSession().uploadTaskWithRequest(req, fromData: data).resume()
  }
}


private extension MockForm {
  func fillWithJSON(json: [NSObject:AnyObject]) {
    firstName = castJSON(json, forKey: "first_name")
    lastName = castJSON(json, forKey: "last_name")
    age = castJSON(json, forKey: "age")
  }
  
  
  func castJSON<T>(json: [NSObject:AnyObject], forKey key: String) -> T? {
    return json[key] as? T
  }
}