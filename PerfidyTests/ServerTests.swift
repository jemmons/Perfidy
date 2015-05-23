import UIKit
import XCTest
import Perfidy
import GroundFloor

class ServerTests: XCTestCase {
  var server = HTTPServer()
  
  override func tearDown() {
    server.stop()
  }
  
  func testShouldErrorOnDuplicateConnections(){
    server.start()
    let error = server.errorFromStart()
    XCTAssert(error != nil, "Should die...")
    XCTAssert(error!.localizedDescription.contains("accept while connected"), "...becasue socket is already connected.")
  }
  
  func testShouldConnectWithoutError(){
    server.start()
    let url = NSURL(string: "localhost:10175/foo")!
    let req = NSURLRequest(URL: url)
    var error:NSErrorPointer = nil
    NSURLConnection.sendSynchronousRequest(req, returningResponse:nil, error:error)
    XCTAssert(error == nil)
  }
  
  
  func testShouldRespondWithData(){
    let expectation = expectationWithDescription("Should get response")

    let res = DataHTTPURLResponse(statusCode: 201, rawJSON:"{\"thing\":42}")!
    server.addResponse(res, forEndpoint:Endpoint(path:"/foo"))
    server.start()
    
    let req = NSURLRequest(URL:NSURL(string: "http://localhost:10175/foo")!)
    NSURLConnection.sendAsynchronousRequest(req, queue: NSOperationQueue.mainQueue()){ res, data, error in
      if error == nil && (res as! NSHTTPURLResponse).statusCode == 201{
        expectation.fulfill()
      }
    }
    
    waitForExpectationsWithTimeout(3.0){ error in }
  }
}
