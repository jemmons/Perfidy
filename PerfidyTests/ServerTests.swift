import UIKit
import XCTest
import Perfidy
import Medea

class ServerTests: XCTestCase {
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
    let expect404 = expectation(description: "Default status code")
    let expect201 = expectation(description: "201 status code")
    let expect300 = expectation(description: "300 status code")
    let expect400 = expectation(description: "400 status code")
    let expect800 = expectation(description: "Nonexistant status code")
    
    FakeServer.runWith { server in
      server.add("/201", response: 201)
      server.add("/300", response: 300)
      server.add("/400", response: 400)
      server.add("/800", response: 800)
    
      sendRequest("/foo/bar"){ res, _, _ in
        if res?.statusCode == 404 { expect404.fulfill() }
      }
      
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
      
      waitForExpectations(timeout: 3.0, handler: nil)
    }
  }

  
  func testDefaultStatusCodes(){
    let should500 = self.expectation(description: "should implicitly return 500 without specifying a response")

    FakeServer.runWith(defaultStatusCode: 500) { server in
      sendRequest(){ res, _, _ in
        if res?.statusCode == 500{
          should500.fulfill()
        }
      }
      waitForExpectations(timeout: 3.0, handler: nil)
    }
  }
  
  
  func testRawJSONResponse(){
    let expectResponse = expectation(description: "Should get response")

    FakeServer.runWith { server in
      let res = try! Response(status: 201, rawJSON:"{\"thing\":42}")
      server.add("/foo", response: res)

      sendRequest("/foo"){ res, data, error in
        let json = try! JSONHelper.json(from: data!)
        XCTAssertEqual(json["thing"] as! NSNumber, 42)
        XCTAssertNil(error)
        XCTAssertEqual(res?.statusCode, 201)
        expectResponse.fulfill()
      }
      
      waitForExpectations(timeout: 2.0, handler: nil)
    }
  }

  
  func testJSONResponse(){
    let expectResponse = expectation(description: "Should get response")
    
    FakeServer.runWith { server in
      let res = try! Response(status: 202, json:["fred":"barney"])
      server.add("/foo/bar/baz", response: res)

      sendRequest("/foo/bar/baz"){ res, data, error in
        let json = try! JSONHelper.json(from: data!)
        XCTAssertEqual(json["fred"] as! String, "barney")
        XCTAssertNil(error)
        XCTAssertEqual(res?.statusCode, 202)
        expectResponse.fulfill()
      }

      waitForExpectations(timeout: 2.0, handler: nil)
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

      waitForExpectations(timeout: 2.0, handler: nil)
    }
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
