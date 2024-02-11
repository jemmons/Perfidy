import Foundation
import XCTest
import Perfidy



class RequestTrackingTests: XCTestCase {
  func testRequestWasSent() throws {
    let responseReceived = expectation(description: "Waiting for response")
    let route: Route = "PUT /hello"
    
    let server = try FakeServer()
    defer { server.stop() }
    server.add(route)

    XCTAssertFalse(server.didRequest(route: route))
      
    session.resumeRequest("PUT", "/hello") { _, _, _ in
      XCTAssert(server.didRequest(route: route))
      responseReceived.fulfill()
    }
    wait(for: [responseReceived], timeout: 1)
  }
  
  
  func testRequestWasSentTwice() throws {
    let responseReceived = expectation(description: "Waiting for responses")
    responseReceived.expectedFulfillmentCount = 2
    
    let route: Route = "POST /content/111"
    
    let server = try FakeServer()
    defer { server.stop() }
    server.add(route)

    XCTAssertEqual(server.numberOfRequests(for: route), 0)
      
    session.resumeRequest("POST", "/content/111") { _, _, _ in
      responseReceived.fulfill()
    }
      
    session.resumeRequest("POST", "/content/111") { _, _, _ in
      responseReceived.fulfill()
    }
      
    waitForExpectations(timeout: 1) { _ in
      XCTAssertEqual(server.numberOfRequests(for: route), 2)
    }
  }
}
