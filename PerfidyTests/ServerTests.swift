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
    let expectation = expectationWithDescription("Thing should stuff")

    self.server.start()
    let url = NSURL(string: "localhost:10175/foo")!
    let req = NSMutableURLRequest(URL: url)
    req.HTTPBody = "Foo".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
    var res:AutoreleasingUnsafeMutablePointer<NSURLResponse?>=nil
    var error:NSErrorPointer = nil
    NSURLConnection.sendAsynchronousRequest(req, queue:nil){ res, data, error in
      expectation.fulfill()
    }
    waitForExpectationsWithTimeout(100.0){ error in
    }
  }
}
