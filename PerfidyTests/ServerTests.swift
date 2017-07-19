import UIKit
import XCTest
import Perfidy
import Medea

class ServerTests: XCTestCase {
  func testTimeout() {
    let shouldTimeOut = expectation(description: "times out")
    FakeServer.runWith { server in
      server.add("/", response: 666)
      let req = URLRequest(url: URL(string: "http://localhost:10175")!)
      let config = URLSessionConfiguration.default
      config.timeoutIntervalForRequest = 0.1
      let session = URLSession(configuration: config)
      
      session.dataTask(with: req) { _, _, error in
        if
          let _error = error,
          (_error as NSError).domain == NSURLErrorDomain,
          (_error as NSError).code == -1001 {
          shouldTimeOut.fulfill()
        }
      }.resume()
      waitForExpectations(timeout: 0.5, handler: nil)
    }
  }
  

  func testShouldConnectWithoutError(){
    let expectResponse = expectation(description: "Response received.")
    FakeServer.runWith { _ in
      sendRequest { _, _, error in
        XCTAssertNil(error)
        expectResponse.fulfill()
      }
      waitForExpectations(timeout: 2.0, handler: nil)
    }
  }
  
  
  func testShouldErrorOnDuplicateConnections(){
    let shouldThrow = expectation(description: "Should throw")
    FakeServer.runWith { server in
      do {
        try server.start()
      } catch {
        XCTAssert((error as NSError).localizedDescription.contains("accept while connected"))
        shouldThrow.fulfill()
      }
      waitForExpectations(timeout: 2.0, handler: nil)
    }
  }

  
  func testStatusCodes(){
    let expect201 = expectation(description: "201 status code")
    let expect300 = expectation(description: "300 status code")
    let expect400 = expectation(description: "400 status code")
    let expect800 = expectation(description: "Nonexistant status code")
    
    FakeServer.runWith { server in
      server.add("/201", response: 201)
      server.add("/300", response: 300)
      server.add("/400", response: 400)
      server.add("/800", response: 800)
    
      sendRequest("/201"){ res, _, _ in
        if res?.statusCode == 201 { expect201.fulfill() }
      }
      
      sendRequest("/300"){ res, _, _ in
        if res?.statusCode == 300 { expect300.fulfill() }
      }
      
      sendRequest("/400"){ res, _, _ in
        if res?.statusCode == 400 { expect400.fulfill() }
      }
      
      sendRequest("/800"){ res, _, _ in
        if res?.statusCode == 800 { expect800.fulfill() }
      }
      
      waitForExpectations(timeout: 1.0, handler: nil)
    }
  }
  
  
  func testDefaultStatusCode() {
    let should404 = expectation(description: "respond with a 404")
    FakeServer.runWith { _ in
      sendRequest("/foo/bar/baz") { res, _, _ in
        if res?.statusCode == 404 { should404.fulfill() }
      }
      waitForExpectations(timeout: 1.0, handler: nil)
    }
  }

  
  func testSetDefaultStatusCode(){
    let should500 = expectation(description: "should implicitly return 500 without specifying a response")

    FakeServer.runWith(defaultStatusCode: 500) { server in
      sendRequest("/foo/bar/baz"){ res, _, _ in
        if res?.statusCode == 500{ should500.fulfill() }
      }
      waitForExpectations(timeout: 3.0, handler: nil)
    }
  }
  

  func testDefaultStatusCodeOfAddedRoute() {
    let should200 = expectation(description: "respond with a 200")
    FakeServer.runWith { server in
      server.add("/foo/bar/baz")
      sendRequest("/foo/bar/baz"){ res, _, _ in
        if res?.statusCode == 200 { should200.fulfill() }
      }
      waitForExpectations(timeout: 1.0, handler: nil)
    }
  }
  
  
  func testHeaders() {
    let shouldReceive = expectation(description: "receive request with header")
    let shouldRespond = expectation(description: "respond")

    FakeServer.runWith { server in
      server.add("/", response: 200) { req in
        XCTAssertEqual(req.value(forHTTPHeaderField: "foo"), "bar")
        shouldReceive.fulfill()
      }
    
      var headerRequest = request("/")
      headerRequest.addValue("bar", forHTTPHeaderField: "foo")
      URLSession.shared.dataTask(with: headerRequest) { _, _, _ in
        shouldRespond.fulfill()
        }.resume()
      waitForExpectations(timeout: 1.0, handler: nil)
    }
  }
  
  func testRawJSONResponse(){
    let expectResponse = expectation(description: "Should get response")

    FakeServer.runWith { server in
      let res = try! Response(status: 201, rawJSON:"{\"thing\":42}")
      server.add("/foo", response: res)

      sendRequest("/foo"){ res, data, error in
        let json = try! JSONHelper.jsonObject(from: data!)
        XCTAssertEqual(json["thing"] as! NSNumber, 42)
        XCTAssertNil(error)
        XCTAssertEqual(res?.statusCode, 201)
        expectResponse.fulfill()
      }
      
      waitForExpectations(timeout: 2.0, handler: nil)
    }
  }

  
  func testJSONObjectResponse(){
    let expectResponse = expectation(description: "Should get response")
    
    FakeServer.runWith { server in
      let res = try! Response(status: 202, jsonObject:["fred":"barney"])
      server.add("/foo/bar/baz", response: res)

      sendRequest("/foo/bar/baz"){ res, data, error in
        let json = try! JSONHelper.jsonObject(from: data!)
        XCTAssertEqual(json["fred"] as! String, "barney")
        XCTAssertNil(error)
        XCTAssertEqual(res?.statusCode, 202)
        expectResponse.fulfill()
      }

      waitForExpectations(timeout: 1.0, handler: nil)
    }
  }

  
  func testJSONArrayResponse(){
    let expectResponse = expectation(description: "Should get response")
    
    FakeServer.runWith { server in
      let res = try! Response(status: 202, jsonArray:["fred","barney"])
      server.add("/foo/bar/baz", response: res)
      
      sendRequest("/foo/bar/baz"){ res, data, error in
        let json = try! JSONHelper.jsonArray(from: data!)
        XCTAssertEqual(json as! [String], ["fred","barney"])
        XCTAssertNil(error)
        XCTAssertEqual(res?.statusCode, 202)
        expectResponse.fulfill()
      }
      
      waitForExpectations(timeout: 1.0, handler: nil)
    }
  }

  
  func testPostingData() {
    let expectSent = expectation(description: "Sent data")
    let expectReceived = expectation(description: "Received data")

    FakeServer.runWith { server in
      server.add("POST /") { req in
        let body = String(data: req.httpBody!, encoding: .utf8)
        XCTAssertEqual(body, "foo")
        expectReceived.fulfill()
      }
      let data = "foo".data(using: String.Encoding.utf8)!
      var req = URLRequest(url: URL(string: "http://localhost:10175/")!)
      req.httpMethod = "POST"
      URLSession.shared.uploadTask(with: req, from: data){ _, _, _ in
        expectSent.fulfill()
        }.resume()

      waitForExpectations(timeout: 1.0, handler: nil)
    }
  }
  
  
  func testDefaultURL() {
    XCTAssertEqual(FakeServer.defaultURL.absoluteString, "http://localhost:10175")
  }
  
  
  func testFakeServerURL() {
    let expectedURL = expectation(description: "Waiting for expected URL")
    FakeServer.runWith(port: 11111) { server in
      XCTAssertEqual(server.url.absoluteString, "http://localhost:11111")
      expectedURL.fulfill()
    }
    wait(for: [expectedURL], timeout: 1)
  }
}


private extension ServerTests{
  func request(_ path:String="/")->URLRequest{
    return URLRequest(url:URL(string:"http://localhost:10175\(path)")!)
  }
  
  
  func sendRequest(_ path:String="/", handler:@escaping (HTTPURLResponse?, Data?, NSError?)->Void){
    URLSession.shared.dataTask(with: request(path)) { data, res, error in
      handler((res as? HTTPURLResponse), data, error as NSError!)
    }.resume()
  }
}
