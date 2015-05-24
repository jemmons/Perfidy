import UIKit
import XCTest
import Perfidy
import GroundFloor

class ServerTests: XCTestCase {
  var server = FakeServer()
  
  override func tearDown() {
    server.stop()
  }
  
  
  func testShouldConnectWithoutError(){
    server.start()
    let url = NSURL(string: "localhost:10175/foo")!
    let req = NSURLRequest(URL: url)
    var error:NSErrorPointer = nil
    NSURLConnection.sendSynchronousRequest(req, returningResponse:nil, error:error)
    XCTAssert(error == nil)
  }
  
  
  func testShouldErrorOnDuplicateConnections(){
    server.start()
    let error = server.errorFromStart()
    XCTAssert(error != nil, "Should die...")
    XCTAssert(error!.localizedDescription.contains("accept while connected"), "...becasue socket is already connected.")
  }
  
  
  func testStatusCodes(){
    let a200Expectation = expectationWithDescription("Default status code")
    let a201Expectation = expectationWithDescription("201 status code")
    let a300Expectation = expectationWithDescription("300 status code")
    let a400Expectation = expectationWithDescription("400 status code")
    let a800Expectation = expectationWithDescription("Nonexistant status code")
    
    server.addResponse(BodyResponse(statusCode:201)!, forEndpoint:Endpoint(path:"/201"))
    server.addResponse(BodyResponse(statusCode:300)!, forEndpoint:Endpoint(path:"/300"))
    server.addResponse(BodyResponse(statusCode:400)!, forEndpoint:Endpoint(path:"/400"))
    server.addResponse(BodyResponse(statusCode:800)!, forEndpoint:Endpoint(path:"/800"))
    server.start()
    
    sendRequestWithPath("/foo/bar"){ res, data, error in
      if res.statusCode == 200 { a200Expectation.fulfill() }
    }

    
    sendRequestWithPath("/201"){ res, data, error in
      if res.statusCode == 201 { a201Expectation.fulfill() }
    }
      
    sendRequestWithPath("/300"){ res, data, error in
      if res.statusCode == 300 { a300Expectation.fulfill() }
    }
    
    sendRequestWithPath("/400"){ res, data, error in
      if res.statusCode == 400 { a400Expectation.fulfill() }
    }

    sendRequestWithPath("/800"){ res, data, error in
      if res.statusCode == 800 { a800Expectation.fulfill() }
    }
    
    waitForExpectationsWithTimeout(3.0){ error in }
  }
  
  
  func testDefaultStatusCodes(){
    let expectation = expectationWithDescription("should explicitly return 400 without specifying a response")

    server = FakeServer(statusCode: 400)
    server.start()
    sendRequestWithPath(){ res, data, error in
      if res.statusCode == 400{ expectation.fulfill() }
    }

    waitForExpectationsWithTimeout(3.0){ error in }
  }
  
  
  func testShouldRespondWithData(){
    let expectation = expectationWithDescription("Should get response")

    let res = BodyResponse(statusCode: 201, rawJSON:"{\"thing\":42}")!
    server.addResponse(res, forEndpoint:Endpoint(path:"/foo"))
    server.start()

    sendRequestWithPath("/foo"){ res, data, error in
      if error == nil && res.statusCode == 201{
        expectation.fulfill()
      }
    }

    waitForExpectationsWithTimeout(3.0){ error in }
  }
}


private extension ServerTests{
  func request(_ path:String="/")->NSURLRequest{
    return NSURLRequest(URL:NSURL(string:"http://localhost:10175\(path)")!)
  }
  
  
  func sendRequestWithPath(_ path:String="/", handler:(NSHTTPURLResponse!, NSData!, NSError!)->Void){
    NSURLConnection.sendAsynchronousRequest(request(path), queue:NSOperationQueue.mainQueue()){ res, data, error in
      handler((res as? NSHTTPURLResponse), data, error)
    }
  }
}
