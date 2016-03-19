import Foundation
import XCTest
import Perfidy

class TestTests: XCTestCase {
  let server = FakeServer()
  
  override func setUp() {
  }
  
  func xtestFillForm() {
    let subject = MockForm()
    subject.fetch()
  }
  
  
  func testSaveForm() {
    let expectSave = expectationWithDescription("Saved")
    server.add(nil, endpoint: Endpoint(method: .POST, path: "/form")) { req in
      let jsonData = try! NSJSONSerialization.dataWithJSONObject(["first_name": "first","last_name": "last","age": "55",], options: [])
      XCTAssertEqual(req.HTTPBody, jsonData)
      expectSave.fulfill()
    }
    try! server.start()
    let subject = MockForm()
    subject.save()
    waitForExpectationsWithTimeout(200, handler: nil)
  }
}
