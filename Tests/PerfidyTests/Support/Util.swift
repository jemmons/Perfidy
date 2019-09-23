import Foundation


/// Normally we’d use the bundle of the test harness, but SwiftPM doesn’t yet allow us to inlcude resources (or test assets) in our packages. This is a wonky work-around until that’s sorted.
/// - SeeAlso: https://bugs.swift.org/browse/SR-2866, https://bugs.swift.org/browse/SR-4725
func fetchFakeBundle() -> Bundle {
  let path = URL(fileURLWithPath: #file)
    .deletingLastPathComponent()
    .appendingPathComponent("FakeBundle.bundle")
  return Bundle(url: path)!
}



let session = URLSession(configuration: URLSessionConfiguration.default)



extension URLSession {
  func resumeRequest(_ method: String, _ path: String, headers: [String: String] = [:], body: Data? = nil, ƒ: @escaping (_ data: Data?, _ res: HTTPURLResponse?, _ error: Error?) -> Void) {
    dataTask(with: Helper.makeReq(method: method, path: path, headers: headers, body: body)) { data, res, error in
      ƒ(data, res as? HTTPURLResponse, error)
    }.resume()
  }
}



private enum Helper {
  private static func makeURL(path: String) -> URL {
    return URL(string: "http://localhost:10175\(path)")!
  }



  static func makeReq(method: String, path: String, headers: [String: String], body: Data?) -> URLRequest {
    var req = URLRequest(url: makeURL(path: path))
    req.httpMethod = method
    req.allHTTPHeaderFields = headers
    req.httpBody = body
    return req
  }
}
