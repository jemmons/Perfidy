import UIKit
import XCTest
import Perfidy

class ServerTests: XCTestCase {
  var server = FakeServer()
  
  
  override func tearDown() {
    server.stop()
  }
  
  
  func testShouldConnectWithoutError(){
    let expectResponse = expectationWithDescription("Response received.")
    do{
      try server.start()
      sendRequest { _, _, error in
        XCTAssertNil(error)
        expectResponse.fulfill()
      }
    } catch {
      XCTFail()
    }
    
    waitForExpectationsWithTimeout(2.0, handler: nil)
  }
  
  
  func testShouldErrorOnDuplicateConnections(){
    try! server.start()
    do {
      try server.start()
    } catch {
      XCTAssert((error as NSError).localizedDescription.containsString("accept while connected"))
    }
  }
  
  
  func testStatusCodes(){
    let expect200 = expectationWithDescription("Default status code")
    let expect201 = expectationWithDescription("201 status code")
    let expect300 = expectationWithDescription("300 status code")
    let expect400 = expectationWithDescription("400 status code")
    let expect800 = expectationWithDescription("Nonexistant status code")
    
//    let responses =
    server.add(Response(status: 201), endpoint: Endpoint(path: "/201"))
    server.add(Response(status: 300), endpoint: Endpoint(path: "/300"))
    server.add(Response(status: 400), endpoint: Endpoint(path: "/400"))
    server.add(Response(status: 800), endpoint: Endpoint(path: "/800"))
    try! server.start()
    
    sendRequest("/foo/bar"){ res, data, error in
      if res.statusCode == 200 { expect200.fulfill() }
    }
    
    sendRequest("/201"){ res, data, error in
      if res.statusCode == 201 { expect201.fulfill() }
    }
      
    sendRequest("/300"){ res, data, error in
      if res.statusCode == 300 { expect300.fulfill() }
    }
    
    sendRequest("/400"){ res, data, error in
      if res.statusCode == 400 { expect400.fulfill() }
    }

    sendRequest("/800"){ res, data, error in
      if res.statusCode == 800 { expect800.fulfill() }
    }
    
    waitForExpectationsWithTimeout(3.0, handler: nil)
  }
  
  
  func testDefaultStatusCodes(){
    let expectation = expectationWithDescription("should explicitly return 400 without specifying a response")

    server = FakeServer(statusCode: 400)
    try! server.start()
    sendRequest(){ res, data, error in
      if res.statusCode == 400{ expectation.fulfill() }
    }

    waitForExpectationsWithTimeout(3.0, handler: nil)
  }
  
  
  func testRawJSONResponse(){
    let expectResponse = expectationWithDescription("Should get response")

    let res = try! Response(status: 201, rawJSON:"{\"thing\":42}")
    server.add(res, endpoint:"/foo")
    try! server.start()

    sendRequest("/foo"){ res, data, error in
      let json = try! NSJSONSerialization.JSONObjectWithData(data, options: [])
      XCTAssertEqual(json["thing"], 42)
      XCTAssertNil(error)
      XCTAssertEqual(res.statusCode, 201)
      expectResponse.fulfill()
    }

    waitForExpectationsWithTimeout(2.0, handler: nil)
  }
  
  
  func testJSONResponse(){
    let expectResponse = expectationWithDescription("Should get response")
    
    let res = try! Response(status: 202, json:["fred":"barney"])
    server.add(res, endpoint:"/foo/bar/baz")
    try! server.start()
    
    sendRequest("/foo/bar/baz"){ res, data, error in
      let json = try! NSJSONSerialization.JSONObjectWithData(data, options: [])
      XCTAssertEqual(json["fred"], "barney")
      XCTAssertNil(error)
      XCTAssertEqual(res.statusCode, 202)
      expectResponse.fulfill()
    }
    
    waitForExpectationsWithTimeout(2.0, handler: nil)
  }
}


private extension ServerTests{
  func request(path:String="/")->NSURLRequest{
    return NSURLRequest(URL:NSURL(string:"http://localhost:10175\(path)")!)
  }
  
  
  func sendRequest(path:String="/", handler:(NSHTTPURLResponse!, NSData!, NSError!)->Void){
    NSURLConnection.sendAsynchronousRequest(request(path), queue:NSOperationQueue.mainQueue()){ res, data, error in
      handler((res as? NSHTTPURLResponse), data, error)
    }
  }
}
