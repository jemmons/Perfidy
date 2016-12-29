import Foundation
import XCTest
import Perfidy
import Medea

class TestTests: XCTestCase {
  let server = FakeServer()
  
  override func setUp() {
  }
  
  func xtestFillForm() {
    let subject = MockForm()
    subject.fetch()
  }
  
  
  func testSaveForm() {
    let expectSave = expectation(description: "Saved")
    server.add(nil, endpoint: Endpoint(method: .post, path: "/form")) { req in
      let jsonData = try! JSONHelper.data(from: ["first_name": "first","last_name": "last","age": "55"])
      XCTAssertEqual(req.httpBody, jsonData)
      expectSave.fulfill()
    }
    try! server.start()
    let subject = MockForm()
    subject.save()
    waitForExpectations(timeout: 2.0, handler: nil)
  }
}
