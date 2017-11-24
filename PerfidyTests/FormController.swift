import UIKit

class MockForm {
  var firstName: String?
  var lastName: String?
  var age: Int?
  
  func fetch(){
    URLSession.shared.dataTask(with: URL(string: "http://localhost:10175/form")!, completionHandler: { data, response, error in
      guard error == nil else {
        self.fillWithJSON([:])
        return
      }
      let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [AnyHashable: Any]
      self.fillWithJSON(json)
    }) .resume()
  }
  
  
  func save(){
    var json = [AnyHashable: Any]()
    json["first_name"] = "first"
    json["last_name"] = "last"
    json["age"] = "55"
    let data = try! JSONSerialization.data(withJSONObject: json, options: [])
    var req = URLRequest(url: URL(string: "http://localhost:10175/form")!)
    req.httpMethod = "POST"
    URLSession.shared.uploadTask(with: req, from: data).resume()
  }
}


private extension MockForm {
  func fillWithJSON(_ json: [AnyHashable: Any]) {
    firstName = castJSON(json, forKey: "first_name")
    lastName = castJSON(json, forKey: "last_name")
    age = castJSON(json, forKey: "age")
  }
  
  
  func castJSON<T>(_ json: [AnyHashable: Any], forKey key: String) -> T? {
    return json[key] as? T
  }
}
